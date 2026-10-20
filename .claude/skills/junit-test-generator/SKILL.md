---
name: junit-test-generator
description: >-
  Writes JUnit 5 + Mockito unit tests for services in auth-service (AuthService) or product-service
  (ProductService). Use when asked to generate tests or after adding/modifying a service method.
---

# 🧪 JUnit 5 + Mockito Test Üretimi

| Servis | Test dizini |
| :--- | :--- |
| auth-service | `auth-service/src/test/java/com/aiengineer/auth/service/` |
| product-service | `product-service/src/test/java/com/aiengineer/product/service/` |

## 1. İskelet (.NET xUnit + Moq karşılığı)
* `@SpringBootTest` değil, `@ExtendWith(MockitoExtension.class)`.
* Bağımlılıklar `@Mock` (ör. `ProductRepository`, `AuthClient`), test edilen sınıf `@InjectMocks`.
* `AuthService` bağımlılıksız; doğrudan `new AuthService()` ile test et.

## 2. İsimlendirme ve yapı
`metot_Durum_Beklenen` + Given / When / Then. Her iş kuralı için en az bir başarılı ve bir red testi.

```java
@ExtendWith(MockitoExtension.class)
class ProductServiceTest {

    @Mock ProductRepository productRepository;
    @Mock AuthClient authClient;
    @InjectMocks ProductService productService;

    @Test
    void createProduct_WhenUserHasWritePermission_ShouldSave() {
        // Given
        Product p = new Product("Klavye", "Aksesuar", new BigDecimal("1500.00"), 10);
        when(authClient.hasPermission("admin-token", "PRODUCT_WRITE")).thenReturn(true);
        when(productRepository.save(p)).thenReturn(p);

        // When
        Product saved = productService.createProduct("admin-token", p);

        // Then
        assertSame(p, saved);
        verify(productRepository).save(p);
    }

    @Test
    void createProduct_WhenUserLacksWritePermission_ShouldRejectAndNotSave() {
        Product p = new Product("Klavye", "Aksesuar", new BigDecimal("1500.00"), 10);
        when(authClient.hasPermission("seller-token", "PRODUCT_WRITE")).thenReturn(false);

        assertThrows(IllegalStateException.class, () -> productService.createProduct("seller-token", p));
        verify(productRepository, never()).save(any());
    }
}
```

Exception tipi koddakiyle aynı olmalı; servis özel bir exception'a geçtiyse testi ona göre yaz.

## Bitirmeden önce
`mvn -q -pl <servis> test` çalıştır ve sonucu raporla.
