#!/bin/bash
# PreToolUse hook: her ajanın sadece kendi alanına yazmasını zorunlu kılar.
#   ana oturum ve diğer ajanlar → her yer, src/test/** hariç (testler test-engineer'ın)
#   test-engineer  → */src/test/**
#   code-reviewer  → hiçbir yer (salt okunur)
# Alt ajanlar Bash ile dosya değiştiremez. exit 2 = engelle, stderr ajana gider.
# Engellenen her girişim .claude/state/hook.log dosyasına yazılır.

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
  [[ -z "$agent" ]] && exit 0
  cmd=$(jq -r '.tool_input.command' <<<"$input")
  if grep -qE '(^|[^0-9&])>|\btee\b|\brm\b|\bmv\b|\bcp\b|sed[[:space:]]+-i|\bgit[[:space:]]+(add|commit|checkout|reset|push|restore|stash|merge|rebase)' <<<"$cmd"; then
    deny "cmd=$cmd" "Bu Bash komutu engellendi (dosya veya git durumunu değiştirebilir): $cmd. Bulguyu raporla; değişiklikleri ana oturum yapar."
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
