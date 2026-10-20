#!/bin/bash
# PostToolUse hook: servisler arası kontratı etkileyen bir dosya değiştiğinde
# ajana CONTRACTS.md'yi güncellemesini hatırlatır (kontrat kayması / contract drift'i önler).

input=$(cat)
path=$(jq -r '.tool_input.file_path // empty' <<<"$input")

case "$path" in
  */auth-service/src/main/java/*/controller/*|*/auth-service/src/main/java/*/dto/*|*/auth-service/src/main/java/*/service/AuthService.java|*/product-service/src/main/java/*/client/*)
    jq -n --arg f "${path##*/}" '{
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: ("\($f) servisler arası kontratı etkileyebilir. Endpoint, response alanı, rol veya permission değiştiyse CONTRACTS.md dosyasını aynı değişiklikte güncelle.")
      }
    }'
    ;;
esac
exit 0
