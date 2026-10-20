#!/bin/bash
# Stop hook: ajan "bitti" demeden önce şunları kontrol eder:
#   1. Hash aracı var mı? Yoksa test koruması çalışmıyor demektir.
#   2. Bekçinin kendi dosyaları (.claude/) oturum içinde değişti mi?
#   3. Test dosyaları test-engineer dışında değiştirilmiş mi? (test-guard.sh işareti)
#   4. Kod değiştiyse, değişen modüllerin testleri geçiyor mu?
# Sorun varsa ajanın durmasına izin vermez ve sebebi ona geri verir.
#
# Bilinçli sınırlar (sonsuz döngüye ve kilitlenmeye karşı):
#   * En fazla 3 kez art arda engeller; sonra durmaya izin verir ama kullanıcıya
#     "iş bitmiş sayılmaz" uyarısı gösterir.
#   * JDK/Maven bulunamazsa testleri çalıştıramaz; engellemez, "doğrulanmadı" uyarısı gösterir.

source "$(dirname "$0")/fingerprint.sh"
cat >/dev/null
changed="$state/changed-modules"
tamper="$state/test-tamper"
attempts="$state/test-gate-attempts"

block_or_give_up() {  # $1 = engelleme sebebi, $2 = vazgeçince gösterilecek uyarı
  local n=$(( $(cat "$attempts" 2>/dev/null || echo 0) + 1 ))
  echo "$n" > "$attempts"
  if (( n > 3 )); then
    rm -f "$attempts"
    jq -n --arg w "$2" '{systemMessage: ("Test kapısı: 3 engellemeden sonra durmaya izin verildi. \($w) İş bitmiş sayılmaz.")}'
  else
    jq -n --arg r "$1" '{decision: "block", reason: $r}'
  fi
  exit 0
}

if ! hash_ok; then
  block_or_give_up \
    "Test kapısı: hash aracı (sha256sum/shasum) bulunamadı; test koruması ve değişiklik takibi çalışmıyor. Yazılımcıya bildir." \
    "Hash aracı bulunamadığı için test koruması ÇALIŞMADI."
fi

if [[ -f "$state/guard-baseline" && "$(fp_guard)" != "$(cat "$state/guard-baseline")" ]]; then
  block_or_give_up \
    "Test kapısı: bekçi dosyaları (.claude/ altındaki hook, ajan veya ayar dosyaları) bu oturumda değişti. Ajanlar bu dosyaları değiştiremez; değişikliği geri al ve yazılımcıya bildir. Değişikliği yazılımcı yaptıysa yeni bir oturum başlatması yeterli." \
    "Bekçi dosyaları (.claude/) oturum içinde değişti."
fi

if [[ -f "$tamper" ]]; then
  block_or_give_up \
    "Test kapısı: test dosyaları test-engineer dışında değiştirildi ($(cat "$tamper")). Değişikliği geri al ya da test-engineer'a yaptır." \
    "Test dosyaları test-engineer dışında değiştirildi ve geri alınmadı."
fi

[[ -s "$changed" ]] || { rm -f "$attempts"; exit 0; }   # kod değişmediyse test gerekmez

modules_csv=$(sort -u "$changed" | paste -sd, -)

if ! command -v mvn >/dev/null 2>&1 || ! java -version >/dev/null 2>&1; then
  jq -n --arg m "$modules_csv" '{systemMessage: ("Test kapısı: \($m) değişti ama JDK/Maven bulunamadığı için testler ÇALIŞTIRILAMADI. Değişiklik doğrulanmadı.")}'
  exit 0
fi

cd "$project" || exit 0
if output=$(mvn -q -B -pl "$modules_csv" test 2>&1); then
  rm -f "$changed" "$attempts"
  jq -n --arg m "$modules_csv" '{systemMessage: ("Test kapısı: \($m) testleri geçti.")}'
  exit 0
fi

summary=$(grep -E 'Tests run:|FAIL|ERROR|expected|but was' <<<"$output" | head -40)
block_or_give_up \
  "Test kapısı: $modules_csv testleri kırmızı, iş bitmiş sayılamaz. Production koddaki hatayı düzelt; test yanlışsa test-engineer ajanına gönder (testi kendin değiştiremezsin).

$summary" \
  "$modules_csv testleri hâlâ KIRMIZI."
