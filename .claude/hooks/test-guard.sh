#!/bin/bash
# PostToolUse hook: test dosyalarının test-engineer dışında değişip değişmediğini tespit eder.
# agent-scope.sh Bash komutlarını metin olarak inceler ve her yolu kapatamaz (ör. bir script üzerinden yazmak).
# Bu hook ise yöntemden bağımsızdır: her araç çağrısından sonra testlerin parmak izini referansla karşılaştırır.
#   test-engineer değiştirdiyse → yeni referans olur.
#   başkası değiştirdiyse      → ajana bildirilir, test-tamper işaretlenir; test-gate.sh bu işaret
#                                kalkana kadar işin bitmesine izin vermez.
# Testler referans hâline geri döndürülürse işaret kendiliğinden kalkar.

source "$(dirname "$0")/fingerprint.sh"
input=$(cat)
agent=$(jq -r '.agent_type // empty' <<<"$input")
tool=$(jq -r '.tool_name' <<<"$input")
base="$state/test-baseline"
cur=$(fp_tests)

if [[ "$agent" == "test-engineer" || ! -f "$base" ]]; then
  echo "$cur" > "$base"
  rm -f "$state/test-tamper"
  exit 0
fi

if [[ "$cur" == "$(cat "$base")" ]]; then
  rm -f "$state/test-tamper"
  exit 0
fi

echo "agent=${agent:-main} tool=$tool" > "$state/test-tamper"
echo "$(date '+%F %T') TAMPER agent=${agent:-main} tool=$tool test dosyaları test-engineer dışında değişti" >> "$state/hook.log"
jq -n '{
  decision: "block",
  reason: "Test dosyaları test-engineer dışında değişti. Testleri sadece test-engineer değiştirebilir: yaptığın test değişikliğini geri al ya da gerekli değişikliği test-engineer ajanına yaptır. Bu düzelmeden test kapısı işi bitirmene izin vermez."
}'
exit 0
