#!/bin/bash
# PostToolUse hook: kod/build dosyası değiştiğinde hangi Maven modülünün test edilmesi gerektiğini
# .claude/state/changed-modules dosyasına yazar. test-gate.sh (Stop hook) bunu okur.
# Sadece doküman değiştiyse hiçbir şey yazılmaz → test kapısı devreye girmez.

input=$(cat)
project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
path=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[[ -z "$path" ]] && exit 0
[[ "$path" != /* ]] && path="$project/$path"
rel="${path#"$project"/}"

state="$project/.claude/state"
mkdir -p "$state"

case "$rel" in
  pom.xml)
    printf 'auth-service\nproduct-service\n' >> "$state/changed-modules" ;;
  auth-service/*.java|auth-service/*.yml|auth-service/*.xml|auth-service/*.sql)
    echo auth-service >> "$state/changed-modules" ;;
  product-service/*.java|product-service/*.yml|product-service/*.xml|product-service/*.sql)
    echo product-service >> "$state/changed-modules" ;;
esac
exit 0
