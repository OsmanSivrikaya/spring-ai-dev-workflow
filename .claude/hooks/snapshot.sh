#!/bin/bash
# SessionStart hook (sadece "startup"): yeni oturumun başında referans parmak izlerini alır.
#   * Modüller ve bekçi dosyaları (.claude/) her yeni oturumda yeniden referans olur; yazılımcının
#     oturumlar arasında elle yaptığı değişiklikler böylece "ajan değiştirdi" sayılmaz.
#   * Test referansı, açık bir test-tamper işareti varsa YENİLENMEZ ve işaret silinmez:
#     izinsiz test değişikliği oturum değişince "aklanmaz".
# resume, /clear ve compact sonrasında çalışmaz (settings.json'da matcher: "startup").

source "$(dirname "$0")/fingerprint.sh"
cat >/dev/null
hash_ok || exit 0   # test-gate.sh bu durumu ayrıca bildirir

for m in "${modules[@]}"; do fp_module "$m" > "$state/fp-$m"; done
fp_guard > "$state/guard-baseline"
[[ -f "$state/test-tamper" ]] || fp_tests > "$state/test-baseline"
exit 0
