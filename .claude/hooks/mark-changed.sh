#!/bin/bash
# PostToolUse hook: her araç çağrısından sonra (Edit, Write, Bash...) modüllerin parmak izine bakar;
# değişen modülü changed-modules dosyasına yazar. test-gate.sh (Stop hook) bunu okur.
# Değişiklik Bash ile yapılmış olsa da yakalanır. Sadece doküman değiştiyse hiçbir modül işaretlenmez.
# Hash aracı yoksa tedbiren tüm modüller işaretlenir (testler her seferinde çalışır).

source "$(dirname "$0")/fingerprint.sh"
cat >/dev/null

if ! hash_ok; then
  printf '%s\n' "${modules[@]}" >> "$state/changed-modules"
  exit 0
fi

for m in "${modules[@]}"; do
  cur=$(fp_module "$m")
  ref="$state/fp-$m"
  if [[ -f "$ref" && "$(cat "$ref")" != "$cur" ]]; then
    echo "$m" >> "$state/changed-modules"
  fi
  echo "$cur" > "$ref"
done
exit 0
