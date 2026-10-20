---
name: add-permission
description: >-
  Cross-service workflow for features that need a new permission, role or auth endpoint
  (e.g. "ürün silme ekle, PRODUCT_DELETE yetkisi gereksin"). Changes auth-service first, updates
  CONTRACTS.md, then implements the product-service side, with tests on both sides.
---

# Yeni yetki gerektiren özellik

Sıra önemlidir: **sağlayıcı → kontrat → tüketici.** Böylece product-service hiçbir zaman var olmayan bir permission'a bağlı kalmaz.

## 0. Netleştir
* Permission adı (`PRODUCT_DELETE` gibi, `KAYNAK_EYLEM` formatında)
* Hangi rollere verilecek? (ADMIN, SELLER …) Belirtilmemişse yazılımcıya sor, tahmin etme.
* Mevcut permission yetiyor mu? (`CONTRACTS.md` §2) Yetiyorsa 1–2. adımları atla.

## 1. auth-service
1. `AuthService` içindeki rol → izin haritasına permission'ı ekle.
2. `AuthServiceTest`: yetkili rol için `hasPermission == true`, yetkisiz rol için `false`.
3. `mvn -q -pl auth-service test`

## 2. CONTRACTS.md
* §2 rol/izin tablosunu güncelle.
* §3 değişiklik geçmişine satır ekle.

## 3. product-service
1. `dto/` altında request/response `record`'ları (`boilerplate-generator` kuralları).
2. `ProductService`: `authClient.hasPermission(token, "<PERMISSION>")` kontrolü, sonra iş kuralı. HTTP çağrısı transaction dışında.
3. `ProductController`: endpoint, `@Valid`.
4. `ProductServiceTest`: izinli + izinsiz senaryo (`junit-test-generator` kuralları).
5. `mvn -q -pl product-service test`

## 4. Kapanış
`architecture-guard` kontrol listesini uygula, `mvn -q test` çalıştır, özet ver.
