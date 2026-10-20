#!/bin/bash
# SessionStart hook: oturum başında modüllerin ve testlerin parmak izini alır.
# mark-changed.sh ve test-guard.sh bu referansla karşılaştırma yapar.
# Yazılımcının oturumlar arasında elle yaptığı değişiklikler böylece "ajan değiştirdi" sayılmaz.

source "$(dirname "$0")/fingerprint.sh"
cat >/dev/null
snapshot_all
rm -f "$state/test-tamper"
exit 0
