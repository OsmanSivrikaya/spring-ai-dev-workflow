package com.aiengineer.auth.service;

import com.aiengineer.auth.dto.TokenValidationResponse;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Set;

/**
 * Auth-Service İş Mantığı Katmanı.
 *
 * Örnek Token'lar:
 * - "admin-token"  -> ADMIN rolü (PRODUCT_READ, PRODUCT_WRITE)
 * - "seller-token" -> SELLER rolü (PRODUCT_READ)
 */
@Service
public class AuthService {

    private final Map<String, TokenValidationResponse> tokenStore = Map.of(
            "admin-token", new TokenValidationResponse(
                    true, "osman-admin", "ADMIN", Set.of("PRODUCT_READ", "PRODUCT_WRITE")
            ),
            "seller-token", new TokenValidationResponse(
                    true, "ali-seller", "SELLER", Set.of("PRODUCT_READ")
            )
    );

    public TokenValidationResponse validateToken(String token) {
        if (token == null || !tokenStore.containsKey(token)) {
            return new TokenValidationResponse(false, "anonymous", "NONE", Set.of());
        }
        return tokenStore.get(token);
    }

    public boolean hasPermission(String token, String requiredPermission) {
        TokenValidationResponse validation = validateToken(token);
        return validation.valid() && validation.permissions().contains(requiredPermission);
    }
}
