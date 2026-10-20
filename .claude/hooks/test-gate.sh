#!/bin/bash
# Stop hook: ajan "bitti" demeden önce değişen modüllerin testlerini kendisi çalıştırır.
# Testler kırmızıysa ajanın durmasına izin vermez ve hatayı ona geri verir.
# Sonsuz döngüye karşı: art arda 3 engellemeden sonra durmaya izin verir ama kullanıcıyı uyarır.

input=$(cat)
project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
state="$project/.claude/state"
changed="$state/changed-modules"
attempts="$state/test-gate-attempts"

[[ -s "$changed" ]] || exit 0   # kod değişmediyse kapı yok

modules=$(sort -u "$changed" | paste -sd, -)

if ! command -v mvn >/dev/null 2>&1 || ! java -version >/dev/null 2>&1; then
  jq -n --arg m "$modules" '{systemMessage: ("Test kapısı: \($m) değişti ama JDK/Maven bulunamadığı için testler ÇALIŞTIRILAMADI. Değişiklik doğrulanmadı.")}'
  exit 0
fi

cd "$project" || exit 0
if output=$(mvn -q -B -pl "$modules" test 2>&1); then
  rm -f "$changed" "$attempts"
  jq -n --arg m "$modules" '{systemMessage: ("Test kapısı: \($m) testleri geçti.")}'
  exit 0
fi

n=$(( $(cat "$attempts" 2>/dev/null || echo 0) + 1 ))
echo "$n" > "$attempts"
summary=$(grep -E 'Tests run:|FAIL|ERROR|expected|but was' <<<"$output" | head -40)

if (( n > 3 )); then
  rm -f "$attempts"
  jq -n --arg m "$modules" '{systemMessage: ("Test kapısı: \($m) testleri 3 denemeden sonra hâlâ KIRMIZI. Ajan durdu ama iş bitmiş sayılmaz.")}'
  exit 0
fi

jq -n --arg m "$modules" --arg s "$summary" '{
  decision: "block",
  reason: ("Test kapısı: \($m) testleri kırmızı, iş bitmiş sayılamaz. Production koddaki hatayı düzelt; test yanlışsa test-engineer ajanına gönder (testi kendin değiştiremezsin).\n\n\($s)")
}'
exit 0
