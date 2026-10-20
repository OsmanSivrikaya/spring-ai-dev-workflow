#!/bin/bash
# PreToolUse hook: ajanların yazabileceği yeri ve tehlikeli komutları sınırlar.
#   ana oturum ve diğer ajanlar → her yer, src/test/** ve bekçi dosyaları hariç
#   test-engineer  → */src/test/**
#   code-reviewer  → hiçbir yer (salt okunur)
#   herkes         → .claude/** (hook, ajan, ayar) ve proje dışındaki durum klasörü yazılamaz;
#                    bunları yazılımcı elle değiştirir.
# Bash komutları metin olarak incelenir. Bu sezgisel bir kontroldür ve her yolu kapatamaz
# (ör. bir script dosyası üzerinden yazmak); kaçan test değişikliklerini test-guard.sh,
# bekçi dosyası değişikliklerini test-gate.sh sonradan yakalar.
# exit 2 = engelle, stderr ajana gider. Engellenen her girişim durum klasöründeki hook.log'a yazılır.

source "$(dirname "$0")/fingerprint.sh"
input=$(cat)
agent=$(jq -r '.agent_type // empty' <<<"$input")
tool=$(jq -r '.tool_name' <<<"$input")

deny() {
  echo "$(date '+%F %T') DENY agent=${agent:-main} tool=$tool $1" >> "$state/hook.log"
  echo "[${agent:-ana-oturum}] $2" >&2
  exit 2
}

# git alt komutunu seçeneklerden (-C yol, -c k=v, --git-dir=...) ayırarak bulur.
# "git log --grep push" gibi zararsız komutları yakalamamak için düz metin araması yapılmaz.
git_violation() {
  local s="$1" seg t sub i j
  s="${s//&&/$'\n'}"; s="${s//||/$'\n'}"; s="${s//;/$'\n'}"; s="${s//|/$'\n'}"
  while IFS= read -r seg; do
    read -ra t <<<"$seg"
    for ((i = 0; i < ${#t[@]}; i++)); do
      [[ "${t[i]##*/}" == git ]] || continue
      sub="" j=$((i + 1))
      while (( j < ${#t[@]} )); do
        case "${t[j]}" in
          -C|-c|--git-dir|--work-tree|--namespace|--exec-path) j=$((j + 2)) ;;
          -*) j=$((j + 1)) ;;
          *) sub="${t[j]}"; break ;;
        esac
      done
      [[ "$sub" == push ]] && return 0
      [[ "$sub" == reset && " ${t[*]:j} " == *" --hard "* ]] && return 0
    done
  done <<<"$s"
  return 1
}

# .env ve .env.local gibi gizli dosyalar; .env.example/.sample/.template/.dist şablonlarına izin verilir.
env_violation() {
  local tok suf
  while IFS= read -r tok; do
    [[ -z "$tok" ]] && continue
    suf="${tok#*.env}"
    case "$suf" in
      .example|.sample|.template|.dist) ;;
      *) return 0 ;;
    esac
  done < <(grep -oE '(^|[^[:alnum:]_])\.env(\.[[:alnum:]_-]+)?' <<<"$1")
  return 1
}

if [[ "$tool" == "Bash" ]]; then
  cmd=$(jq -r '.tool_input.command' <<<"$input")

  # 1) Herkes için (ana oturum dahil): yıkıcı komutlar ve gizli bilgi.
  #    settings.json'daki deny kuralları ön ek eşleştirir; varyasyonları burada yakalarız.
  if grep -qE '\brm\b' <<<"$cmd" \
     && grep -qE '(^|[[:space:]])(-[[:alpha:]]*[rR][[:alpha:]]*|--recursive)([[:space:]]|$)' <<<"$cmd" \
     && grep -qE '(^|[[:space:]])(-[[:alpha:]]*f[[:alpha:]]*|--force)([[:space:]]|$)' <<<"$cmd"; then
    deny "cmd=$cmd" "Özyinelemeli zorla silme (rm -rf ve varyasyonları) yasak: $cmd"
  fi
  git_violation "$cmd" && deny "cmd=$cmd" "git push ve git reset --hard yasak; bunları yazılımcı yapar: $cmd"
  env_violation "$cmd" && deny "cmd=$cmd" ".env dosyaları gizli bilgi içerir; okunamaz/değiştirilemez: $cmd"

  writes='(^|[^0-9&])>|\btee\b|\brm\b|\bmv\b|\bcp\b|\bln\b|\bchmod\b|\btouch\b|\bsed[[:space:]]+(-[[:alpha:]]*[[:space:]]+)*-[[:alpha:]]*i|\bperl\b.*[[:space:]]-[[:alpha:]]*i|\btruncate\b|\bdd\b|\bgit[[:space:]]+(add|commit|checkout|reset|restore|stash|merge|rebase|apply)'

  # 2) Herkes için: bekçinin kendi dosyaları ve durum klasörü.
  if grep -qE '\.claude([/[:space:]]|$)|claude-guard|\.cache' <<<"$cmd" && grep -qE "$writes" <<<"$cmd"; then
    deny "cmd=$cmd" "Bekçi dosyaları (.claude/) ve durum klasörü Bash ile değiştirilemez; bunları yazılımcı elle değiştirir: $cmd"
  fi

  # 3) Alt ajanlar Bash ile dosya/git durumu değiştiremez.
  if [[ -n "$agent" ]] && grep -qE "$writes" <<<"$cmd"; then
    deny "cmd=$cmd" "Bu Bash komutu engellendi (dosya veya git durumunu değiştirebilir): $cmd. Dosyaları Edit/Write ile değiştir; değişiklikleri raporla."
  fi

  # 4) test-engineer dışındaki herkes testlere Bash ile de yazamaz.
  if [[ "$agent" != "test-engineer" ]] && grep -qE 'src/test|Tests?\.java' <<<"$cmd" && grep -qE "$writes" <<<"$cmd"; then
    deny "cmd=$cmd" "Test dosyalarını Bash ile değiştirmek yasak; testleri sadece test-engineer yazar/değiştirir: $cmd"
  fi
  exit 0
fi

path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
[[ -z "$path" ]] && exit 0
[[ "$path" != /* ]] && path="$project/$path"
rel="${path#"$project"/}"

# Herkes için: bekçi dosyaları ve durum klasörü.
if [[ "$rel" == .claude/* || "$path" == "$guard_root"/* ]]; then
  deny "path=$rel" "'$rel' bekçi dosyası; ajanlar hook, ajan tanımı, ayar ve durum dosyalarını değiştiremez. Gerekiyorsa yazılımcıya öner."
fi

case "$agent" in
  test-engineer)
    [[ "$rel" == */src/test/* ]] || deny "path=$rel" "'$rel' yazılamaz: test-engineer sadece */src/test/** altına yazar. Production kodda hata varsa raporla."
    ;;
  code-reviewer)
    deny "path=$rel" "code-reviewer salt okunurdur; bulguyu raporla."
    ;;
  *)
    # Ana oturum ve diğer tüm ajanlar (general-purpose vb.): testlere dokunamaz.
    [[ "$rel" == */src/test/* ]] && deny "path=$rel" "'$rel' bir test dosyası. Testleri sadece test-engineer yazar/değiştirir; testi geçirmek için testi değiştirme, test-engineer'a gönder."
    ;;
esac
exit 0
