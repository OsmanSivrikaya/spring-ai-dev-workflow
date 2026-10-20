# product-service (8082)

Genel kurallar için kök `AGENTS.md`. Bu dosya sadece product-service'e özgü bağlamı içerir.

## Ne var
* `domain/Product.java` (JPA entity), `repository/ProductRepository.java`
* `service/ProductService.java` — listeleme, ekleme (ekleme öncesi `PRODUCT_WRITE` kontrolü)
* `controller/ProductController.java` — `GET/POST /api/products`, token `X-Auth-Token` header'ında
* `client/AuthClient.java` — auth-service'e `RestClient` ile gider (`services.auth.base-url`)
* DB: H2 in-memory; açılışta 3 örnek ürün yüklenir (`ProductApplication.seedProducts`)
* Test: `src/test/java/com/aiengineer/product/` (henüz yok; ilk değişiklikte `service/ProductServiceTest.java` oluştur)

## Komutlar
```bash
mvn -q -pl product-service test
mvn -pl product-service spring-boot:run   # auth-service (8081) de ayakta olmalı
```

## Dikkat
* Bu servis auth-service'in **tüketicisidir**. Token, rol veya izin burada uydurulmaz/sabit kodlanmaz; yetki her zaman `AuthClient` ile sorulur.
* Kullanılan permission `CONTRACTS.md` §2'de yoksa önce auth tarafı yapılır (`add-permission` skill'i).
* Testlerde `AuthClient` ve `ProductRepository` `@Mock`; gerçek HTTP çağrısı yapılmaz.

## Bilinen teknik borç
* Controller `@Entity` (`Product`) alıp dönüyor → DTO'ya geçilmeli.
* Yetkisiz istekte `IllegalStateException` → 500 dönüyor; 403 olmalı (`@RestControllerAdvice`).
* `AuthClient` çağrısı `@Transactional` metodun içinde ve timeout'u yok.
