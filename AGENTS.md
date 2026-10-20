# AGENTS.md — SmartCommerce

Java 21 + Spring Boot 3 ile yazılmış iki bağımsız mikroservis. Çalışma zamanında (runtime) AI yoktur; bu dosya geliştirme sırasında kod yazan AI ajanı için kuralları tanımlar.

| Servis | Port | Ne yapar | Ayrıntılı kurallar |
| :--- | :--- | :--- | :--- |
| `auth-service/` | 8081 | Token doğrulama, rol → izin haritası | `auth-service/AGENTS.md` |
| `product-service/` | 8082 | Ürün kataloğu, stok; yazma işlemlerinde auth-service'e yetki sorar | `product-service/AGENTS.md` |

* Servisler arası HTTP kontratı: `CONTRACTS.md` (tek doğru kaynak)
* Katman kuralları: `ARCHITECTURE.md`
* `README.md`: projenin tanıtımı ve yazılımcının kişisel öğrenme notları (kural kaynağı değildir; kurallar bu dosyada)

---

## 1. Komutlar

```bash
mvn -q -pl auth-service test              # sadece auth-service testleri
mvn -q -pl product-service test           # sadece product-service testleri
mvn -q test                               # hepsi
mvn -pl auth-service spring-boot:run      # 8081
mvn -pl product-service spring-boot:run   # 8082 (auth-service de ayakta olmalı)
```

Testler geçmeden "tamamlandı" deme. Komut çalıştırılamadıysa (JDK/Maven yok vb.) bunu açıkça söyle.

## 2. Servis sınırları

* İki servis birbirinin kodunu import etmez, ortak modül yoktur; sadece HTTP ile konuşurlar.
* Bir görev tek servise aitse sadece o servisin dizinini değiştir.
* İki servisi birden etkileyen değişikliklerde (yeni permission, endpoint, response alanı) `add-permission` skill'indeki sırayı izle:
  **önce sağlayıcı (auth-service) → `CONTRACTS.md` → sonra tüketici (product-service)**.
* auth-service'teki mevcut endpoint path'lerini ve response alanlarını kaldırma/yeniden adlandırma; sadece ekle (geriye uyumluluk). Kırıcı değişiklik gerekiyorsa önce yazılımcıya sor.

## 3. Kod kuralları

* Paket kökleri: `com.aiengineer.auth`, `com.aiengineer.product`. Katmanlar: `controller/`, `service/`, `repository/`, `domain/`, `dto/`, `client/`.
* Constructor injection; `@Autowired` alan enjeksiyonu yok.
* API'de `@Entity` alınmaz/dönülmez; `dto/` altında Java `record`. Request DTO'larında Jakarta Validation, controller'da `@Valid @RequestBody`.
* Para alanları `BigDecimal`.
* `@Transactional` sadece service katmanında; başka servise HTTP çağrısı transaction içinde yapılmaz.
* HTTP kodları: validasyon → 400, token yok/geçersiz → 401, yetki yok → 403, bulunamadı → 404. Ham `IllegalStateException` ile 500 dönme.
* Her yeni iş kuralı için JUnit 5 + Mockito testi (başarılı + red senaryosu).

## 4. Ajanlar, otomatik kontroller ve iş akışı

Kodu yazan ajan kendi işini onaylayamaz.

| Kim | Görev | Yazabildiği yer |
| :--- | :--- | :--- |
| ana oturum | Planlar, kodu yazar (service, controller, DTO, client, entity), diğerlerini çağırır | her yer, **`src/test/**` hariç** |
| `test-engineer` (`.claude/agents/`) | Gereksinimden test yazar ve çalıştırır | `*/src/test/**` |
| `code-reviewer` (`.claude/agents/`) | Bağımsız inceleme, `ONAY` / `RED` | hiçbir yer (salt okunur) |

Otomatik kontroller (ajanın beyanına bağlı değil, `.claude/settings.json`):
* **`agent-scope.sh`** (PreToolUse): yukarıdaki yazma sınırlarını uygular; Write/Edit'i ve Bash'teki yaygın yazma kalıplarını (test dosyalarına `sed -i`, `>`, `tee`…) engeller. Herkes için: `.claude/**` (hook, ajan, ayar) ve durum klasörü yazılamaz; `rm -rf` / `git push` / `git reset --hard` / `.env` varyasyonları engellenir.
* **`test-guard.sh`** (PostToolUse): test dosyalarının parmak izini izler; `test-engineer` dışında herhangi bir yolla değişirse bildirir ve test kapısını kilitler. Test değişikliğini geri al ya da `test-engineer`'a yaptır.
* **`mark-changed.sh`** (PostToolUse) + **`snapshot.sh`** (SessionStart, sadece yeni oturum): modüllerin parmak iziyle hangi modülün değiştiğini bulur (Bash ile yapılan değişiklikler dahil). Compact/resume referansı sıfırlamaz.
* **`test-gate.sh`** (Stop): hash aracı yoksa, `.claude/` oturum içinde değiştiyse, testler izinsiz değiştiyse veya değişen modülün testleri kırmızıysa ajanın bitirmesini engeller. En fazla 3 kez art arda engeller, sonra "iş bitmiş sayılmaz" uyarısıyla bırakır; JDK/Maven yoksa "doğrulanmadı" der. Bu uyarıları yazılımcıya aynen raporla.
* Durum dosyaları (referans hash'ler, işaretler, `hook.log`) proje dışında: `~/.cache/claude-guard/`. Hook'ların kendisi `.claude/hooks/tests/hooktest.py` ile test edilir (CI'da da çalışır).
* Hook veya ayar değişikliği gerekiyorsa yapma; yazılımcıya öner. `.claude/` dosyalarını yazılımcı elle değiştirir.
* **`contract-reminder.sh`** (PostToolUse): kontratı etkileyen dosyada `CONTRACTS.md`'yi hatırlatır.
* **CI** (`.github/workflows/ci.yml`) her branch'teki her push'ta ve her PR'da `mvn -B verify`; **`claude-review.yml`** her PR'da `code-reviewer` kurallarıyla inceleme yapar.

### Akış değişikliğin riskine göre seçilir

**Küçük değişiklik:** yazım/isim düzeltme, log mesajı, yorum, doküman, davranışı değiştirmeyen refactor.
1. Değişikliği yap.
2. Testleri test kapısı çalıştırır; ayrıca ajan çağırma.

**Normal değişiklik:** yeni endpoint, yeni/değişen iş kuralı, bug fix.
1. Kodu yaz (DB etkisi varsa `db-changes` skill'i).
2. `test-engineer` → testler. Kırmızı test production hatası gösteriyorsa kodu düzelt, **testi değil**; test yanlışsa `test-engineer`'a geri gönder.
3. `code-reviewer` → `RED` ise düzelt, 2–3'ü tekrarla.

**Riskli değişiklik:** yetki/rol/token, servisler arası kontrat, entity/şema, güvenlik ayarları.
1. Normal akış + gerekiyorsa `add-permission` sırası (auth → `CONTRACTS.md` → product).
2. Ek olarak `/security-review` (Claude Code'un yerleşik güvenlik incelemesi).
3. `ci-build` skill'i ile `mvn -B verify`.

Hangi kategoride olduğundan emin değilsen bir üst kategoriyi seç.

## 5. Skill'ler (`.claude/skills/`)

| Skill | Ne zaman |
| :--- | :--- |
| `add-permission` | Yeni permission/rol/auth endpoint'i gerektiren özellik |
| `boilerplate-generator` | DTO, controller endpoint, exception handler |
| `db-changes` | Entity, repository, DB ayarı, migration |
| `ci-build` | CI ile aynı build, pipeline/pom değişikliği |
| `junit-test-generator` | Test standardı (`test-engineer` kullanır) |
| `architecture-guard` | İnceleme kontrol listesi (`code-reviewer` kullanır) |

## 6. Tamamlanma tanımı

- [ ] Test kapısı geçti (Stop hook; JDK/Maven yoksa "doğrulanmadı" olarak raporla)
- [ ] Normal/riskli değişiklikte `code-reviewer` kararı `ONAY`
- [ ] Riskli değişiklikte `/security-review` ve `mvn -B verify` temiz
- [ ] Kontrat değiştiyse `CONTRACTS.md` kodla birebir aynı
- [ ] Yazılımcıya kısa özet: kategori, ne değişti, testler, inceleme sonucu, bilinen eksik
