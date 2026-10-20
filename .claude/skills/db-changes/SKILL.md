---
name: db-changes
description: >-
  Rules for persistence changes: JPA entities, repositories, datasource settings and migrations.
  Use when adding or changing an entity, column, relation, repository query or database configuration,
  or when reviewing persistence code for N+1 queries, missing indexes or wrong mappings.
---

# Veritabanı / kalıcılık değişiklikleri

## Mevcut durum
* Sadece `product-service` DB kullanıyor: H2 in-memory, `ddl-auto: update`, tablo `products`.
* `auth-service`'te DB yok.

## Kurallar
* Para `BigDecimal` + `@Column(precision = 19, scale = 2)`.
* Zorunlu alanlar `nullable = false`; arama/filtre yapılan kolonlar için index düşün.
* İlişkilerde `FetchType.LAZY`; koleksiyon dönen sorgularda N+1 riskini kontrol et (`@EntityGraph` / `join fetch`).
* Türetilmiş metot isimleri (`findByCategoryIgnoreCase`) yeterliyse `@Query` yazma.
* Kalıcı bir veritabanına (PostgreSQL) geçildiğinde `ddl-auto: update` yerine Flyway migration'ı (`src/main/resources/db/migration/V<n>__aciklama.sql`). Bu geçişi yazılımcı onaylamadan yapma.

## Değişiklikten sonra
* Etkilenen service/DTO/test'leri listele ve güncelle.
* Şema etkisini özetle: yeni kolon/tablo/index, geriye uyumlu mu, mevcut veri etkilenir mi?
* Bu değişiklik "tam akış" gerektirir (kök `AGENTS.md` §4).
