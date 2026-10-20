---
name: ci-build
description: >-
  Run the same build CI runs, diagnose build/CI failures, or change the pipeline (.github/workflows)
  and Maven build configuration (pom.xml files).
---

# Build ve CI

## CI'ın yaptığını yerelde çalıştır
```bash
mvn -B verify
```
`.github/workflows/ci.yml` ile aynı komut. Başarısızsa: hangi modül, hangi test, ilk anlamlı hata satırı. Uzun log yapıştırma, özetle.

## Pipeline'lar
* `.github/workflows/ci.yml` — her push/PR'da `mvn -B verify`
* `.github/workflows/claude-review.yml` — her PR'da `code-reviewer` kurallarıyla AI incelemesi

## Kurallar
* Bağımlılık versiyonları kök `pom.xml`'deki Spring Boot parent'tan gelir; alt modüllerde versiyon yazma.
* CI ile yerel build aynı komutu çalıştırmalı; workflow'u değiştirirsen bu dosyayı da güncelle.
* Secret/token'ı asla workflow dosyasına yazma; `${{ secrets.X }}` kullan.
