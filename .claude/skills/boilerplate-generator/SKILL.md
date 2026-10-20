---
name: boilerplate-generator
description: >-
  Generates Spring Boot boilerplate ("amelasyon") for auth-service or product-service: Java record DTOs
  with Jakarta Validation, entity-to-DTO mappers, REST controller endpoints and @RestControllerAdvice
  error handling. Use when a new field, entity or service method needs to be exposed over HTTP.
---

# 🛠️ Boilerplate (Amelasyon) Üretimi

Önce hangi servisin içinde çalıştığını belirle ve sadece o servisin dizinine yaz (kök `AGENTS.md` §2).

| Servis | DTO paketi |
| :--- | :--- |
| auth-service | `auth-service/src/main/java/com/aiengineer/auth/dto/` |
| product-service | `product-service/src/main/java/com/aiengineer/product/dto/` |

## 1. DTO (`record`)
* **Request DTO:** alanlarda `jakarta.validation.constraints.*` (`@NotBlank`, `@NotNull`, `@Positive`, `@PositiveOrZero`).
* **Response DTO:** `static XxxResponse from(Entity e)` mapper metodu.

```java
package com.aiengineer.product.dto;

public record CreateProductRequest(
        @NotBlank(message = "Ürün adı boş olamaz") String name,
        @NotBlank(message = "Kategori boş olamaz") String category,
        @NotNull @Positive(message = "Fiyat 0'dan büyük olmalıdır") BigDecimal price,
        @PositiveOrZero(message = "Stok negatif olamaz") int stockQuantity
) {}

public record ProductResponse(Long id, String name, String category, BigDecimal price, int stockQuantity) {
    public static ProductResponse from(Product p) {
        return new ProductResponse(p.getId(), p.getName(), p.getCategory(), p.getPrice(), p.getStockQuantity());
    }
}
```

## 2. Controller
* `@PostMapping` / `@PutMapping` → `@Valid @RequestBody XxxRequest`.
* Dönüş `ResponseEntity<XxxResponse>`; controller'da iş kuralı yok, sadece service çağrısı.

## 3. Hata yönetimi (`@RestControllerAdvice`, servis başına bir tane: `<paket>/exception/GlobalExceptionHandler.java`)
* `MethodArgumentNotValidException` → 400
* Yetkisiz işlem için özel exception (ör. `ForbiddenException`) → 403
* Bulunamadı (ör. `NotFoundException`) → 404
* Gövde: `timestamp`, `status`, `error`, `message`. Spring'in `ProblemDetail`'i de kabul.

## Bitirmeden önce
`mvn -q -pl <servis> test` çalıştır.
