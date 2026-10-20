# 🤝 Servisler Arası Kontrat (`CONTRACTS.md`)

`auth-service` (8081) ile `product-service` (8082) arasındaki HTTP kontratlarının **tek doğru kaynağı**. Kod ile bu dosya ayrışırsa bu bir hatadır; kontratı değiştiren her değişiklik bu dosyayı da aynı anda günceller. (İleride bu dosyanın yerini springdoc ile üretilen OpenAPI şeması alacak.)

---

## 📡 1. Aktif Endpoint'ler (`auth-service`)

### 1.1 `GET /api/auth/check-permission` — product-service bunu kullanır
* Çağıran: `product-service` → `client/AuthClient.hasPermission(token, permission)`
* Query: `token` (string), `permission` (string)
* Response `200`:
  ```json
  { "allowed": true, "permission": "PRODUCT_WRITE" }
  ```
* Geçersiz token veya izin yoksa yine `200` ve `"allowed": false` döner.

### 1.2 `GET /api/auth/validate` — frontend / ileride kullanım için
* Query: `token`
* Response `200` (`TokenValidationResponse`):
  ```json
  { "valid": true, "username": "osman-admin", "role": "ADMIN", "permissions": ["PRODUCT_READ", "PRODUCT_WRITE"] }
  ```
* Geçersiz token: `{ "valid": false, "username": "anonymous", "role": "NONE", "permissions": [] }`

> ⚠️ Bilinen kısıt: token query string'de taşınıyor (loglara düşer) ve token'lar `AuthService` içinde sabit kodlu. Gerçek kimlik doğrulamaya (login + JWT) geçildiğinde bu bölüm yeniden yazılacak.

---

## 🔑 2. Roller ve İzinler

| Token (test) | Kullanıcı | Rol | İzinler |
| :--- | :--- | :--- | :--- |
| `admin-token` | `osman-admin` | `ADMIN` | `PRODUCT_READ`, `PRODUCT_WRITE` |
| `seller-token` | `ali-seller` | `SELLER` | `PRODUCT_READ` |

Kullanım yerleri: `PRODUCT_WRITE` → `POST /api/products`. `PRODUCT_READ` tanımlı ama henüz hiçbir endpoint'te kontrol edilmiyor (`GET /api/products` herkese açık).

---

## 📜 3. Değişiklik Geçmişi

Kontratı değiştiren her değişiklik buraya bir satır ekler. Sadece ekleme yapan değişiklikler geriye uyumludur; alan/endpoint kaldırma "kırıcı" olarak işaretlenir ve önce yazılımcıyla konuşulur.

| Versiyon | Değişiklik | Tür |
| :--- | :--- | :--- |
| `v1` | İlk kurulum: test token'ları, `PRODUCT_READ` / `PRODUCT_WRITE`, `check-permission` ve `validate` endpoint'leri. | ekleme |
