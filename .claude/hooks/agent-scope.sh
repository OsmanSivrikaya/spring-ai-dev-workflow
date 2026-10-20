#!/bin/bash
# PreToolUse hook: ajanların yazabileceği yeri ve tehlikeli komutları sınırlar.
#   ana oturum ve diğer ajanlar → her yer, src/test/** hariç (testler test-engineer'ın)
#   test-engineer  → */src/test/**
#   code-reviewer  → hiçbir yer (salt okunur)
# Bash komutları metin olarak incelenir. Bu sezgisel bir kontroldür ve her yolu kapatamaz
# (ör. bir script dosyası üzerinden yazmak); kaçan değişiklikleri test-guard.sh sonradan yakalar.
# exit 2 = engelle, stderr ajana gider. Engellenen her girişim .claude/state/hook.log'a yazılır.

input=$(cat)
agent=$(jq -r '.agent_type // empty' <<<"$input")
tool=$(jq -r '.tool_name' <<<"$input")
project="${CLAUDE_PROJECT_DIR:-$(pwd)}"

deny() {
  mkdir -p "$project/.claude/state"
  echo "$(date '+%F %T') DENY agent=${agent:-main} tool=$tool $1" >> "$project/.claude/state/hook.log"
  echo "[${agent:-ana-oturum}] $2" >&2
  exit 2
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
  if grep -qE '\bgit\b.*\bpush\b|\bgit\b.*\breset\b.*--hard' <<<"$cmd"; then
    deny "cmd=$cmd" "git push ve git reset --hard yasak; bunları yazılımcı yapar: $cmd"
  fi
  if grep -qE '(^|[^[:alnum:]_])\.env([^[:alnum:]_]|$)' <<<"$cmd"; then
    deny "cmd=$cmd" ".env dosyaları gizli bilgi içerir; okunamaz/değiştirilemez: $cmd"
  fi

  writes='(^|[^0-9&])>|\btee\b|\brm\b|\bmv\b|\bcp\b|\bsed[[:space:]]+(-[[:alpha:]]*[[:space:]]+)*-[[:alpha:]]*i|\bperl\b.*[[:space:]]-[[:alpha:]]*i|\btruncate\b|\bdd\b|\bgit[[:space:]]+(add|commit|checkout|reset|restore|stash|merge|rebase|apply)'

  # 2) Alt ajanlar Bash ile dosya/git durumu değiştiremez.
  if [[ -n "$agent" ]] && grep -qE "$writes" <<<"$cmd"; then
    deny "cmd=$cmd" "Bu Bash komutu engellendi (dosya veya git durumunu değiştirebilir): $cmd. Dosyaları Edit/Write ile değiştir; değişiklikleri raporla."
  fi

  # 3) Ana oturum (ve test-engineer dışındaki herkes) testlere Bash ile de yazamaz.
  if [[ "$agent" != "test-engineer" ]] && grep -qE 'src/test|Tests?\.java' <<<"$cmd" && grep -qE "$writes" <<<"$cmd"; then
    deny "cmd=$cmd" "Test dosyalarını Bash ile değiştirmek yasak; testleri sadece test-engineer yazar/değiştirir: $cmd"
  fi
  exit 0
fi

path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
[[ -z "$path" ]] && exit 0
[[ "$path" != /* ]] && path="$project/$path"
rel="${path#"$project"/}"

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
