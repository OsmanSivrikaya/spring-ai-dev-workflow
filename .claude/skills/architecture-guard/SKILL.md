---
name: architecture-guard
description: >-
  Reviews auth-service and product-service code against ARCHITECTURE.md, AGENTS.md rules and CONTRACTS.md.
  Use when the developer asks for a code review or architecture check, or before finishing a feature.
---

# 🛡️ Mimari Denetim

Kodu değiştirme; bulguları `dosya:satır` + neden + önerilen düzeltme şeklinde raporla.

## Kontrol listesi
1. **Katman:** Controller doğrudan Repository çağırıyor mu? Controller'da iş kuralı var mı?
2. **API sınırı:** Controller `@Entity` alıyor/dönüyor mu? (DTO `record` olmalı.) POST/PUT'ta `@Valid` eksik mi?
3. **Transaction:** Durum değiştiren service metodunda `@Transactional` eksik mi? Transaction içinde başka servise HTTP çağrısı var mı?
4. **Veri tipi:** Para alanında `double`/`float` var mı? (`BigDecimal` olmalı.)
5. **Hata kodları:** Yetkisiz/bulunamadı durumları 500 olarak mı dönüyor?
6. **Servis sınırı:** Bir servis diğerinin paketini import ediyor mu? İki servisi etkileyen değişiklik `add-permission` sırasına (auth → CONTRACTS.md → product) uyuyor mu?
7. **Kontrat uyumu:** `AuthClient`'ın çağırdığı path/parametre/alanlar ve `AuthController` ile `CONTRACTS.md` birebir aynı mı? Kodda kullanılan her permission `CONTRACTS.md` §2'de var mı?
8. **Test:** Yeni/değişen her service metodunun `src/test/...` altında başarılı + red testi var mı? `mvn -q test` geçiyor mu?
