# auth-service (8081)

Genel kurallar için kök `AGENTS.md`. Bu dosya sadece auth-service'e özgü bağlamı içerir.

## Ne var
* `service/AuthService.java` — test token'ları ve rol → izin haritası (sabit kodlu, DB yok)
* `controller/AuthController.java` — `GET /api/auth/validate`, `GET /api/auth/check-permission`
* `dto/TokenValidationResponse.java`
* Test: `src/test/java/com/aiengineer/auth/` (henüz yok; ilk değişiklikte `service/AuthServiceTest.java` oluştur)

## Komutlar
```bash
mvn -q -pl auth-service test
mvn -pl auth-service spring-boot:run
```

## Dikkat
* Bu servis bir **sağlayıcıdır**: `product-service/client/AuthClient.java` buradaki endpoint'leri çağırır. Controller veya DTO değiştirdiğinde `CONTRACTS.md`'yi aynı değişiklikte güncelle.
* `AuthService` bağımlılıksızdır; testlerde `new AuthService()` yeterli, Spring context gerekmez.

## Bilinen teknik borç
* Token query string'de taşınıyor; `Authorization: Bearer` header'ına taşınmalı.
* Token'lar sabit kodlu; ileride login + JWT.
