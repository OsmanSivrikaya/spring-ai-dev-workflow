#!/bin/bash
# Ortak yardımcı: durum klasörü ve dosya kümelerinin parmak izi (hash). Diğer hook'lar source eder.
# Parmak izi karşılaştırması, değişiklik hangi araçla yapılırsa yapılsın (Edit, Bash, script) yakalar.
#
# Durum dosyaları (referans hash'ler, işaretler, log) bilinçli olarak proje DIŞINDA tutulur;
# böylece ajanın proje içinde çalışırken bunları ezmesi zorlaşır.

project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
guard_root="${XDG_CACHE_HOME:-$HOME/.cache}/claude-guard"
state="$guard_root/${project//\//_}"
modules=(auth-service product-service)
mkdir -p "$state"

# Hash aracı: sha256sum (Linux) ya da shasum (macOS). Hiçbiri yoksa sessizce "değişiklik yok"
# demek yerine hash_ok false döner; çağıran hook'lar bunu açıkça hata olarak ele alır.
if command -v sha256sum >/dev/null 2>&1; then
  HASH=(sha256sum)
elif command -v shasum >/dev/null 2>&1; then
  HASH=(shasum -a 256)
else
  HASH=()
fi
hash_ok() { (( ${#HASH[@]} > 0 )); }

# find argümanlarıyla seçilen dosyaların tek bir parmak izi. target/ hariç.
fp_find() {
  hash_ok || return 1
  (cd "$project" && find "$@" -type f -not -path '*/target/*' -print0 2>/dev/null \
    | sort -z | xargs -0 "${HASH[@]}" | "${HASH[@]}" | cut -d' ' -f1)
}

fp_module() { fp_find "$1/src" "$1/pom.xml" pom.xml; }      # modülün build'ini etkileyen her şey
fp_tests()  { fp_find . -path '*/src/test/*'; }               # tüm test dosyaları
fp_guard()  { fp_find .claude -not -name settings.local.json; } # bekçinin kendi dosyaları
