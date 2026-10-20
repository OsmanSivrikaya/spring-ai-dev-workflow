#!/bin/bash
# Ortak yardımcı: dosya kümelerinin parmak izini (hash) üretir. Diğer hook'lar source eder.
# Parmak izi karşılaştırması, değişiklik hangi araçla yapılırsa yapılsın (Edit, Bash, script) yakalar.

project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
state="$project/.claude/state"
modules=(auth-service product-service)
mkdir -p "$state"

# Bir modülün build'i etkileyen her şeyi (src + pom'lar) kapsar; target/ hariç.
fp_module() {
  (cd "$project" && find "$1/src" "$1/pom.xml" pom.xml -type f -not -path '*/target/*' -print0 2>/dev/null \
    | sort -z | xargs -0 shasum 2>/dev/null | shasum | cut -d' ' -f1)
}

# Tüm test dosyaları.
fp_tests() {
  (cd "$project" && find . -path '*/src/test/*' -type f -not -path '*/target/*' -print0 2>/dev/null \
    | sort -z | xargs -0 shasum 2>/dev/null | shasum | cut -d' ' -f1)
}

snapshot_all() {
  for m in "${modules[@]}"; do fp_module "$m" > "$state/fp-$m"; done
  fp_tests > "$state/test-baseline"
}
