package com.aiengineer.auth.controller;

import com.aiengineer.auth.dto.TokenValidationResponse;
import com.aiengineer.auth.service.AuthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Auth-Service REST API (Port: 8081).
 * Hem Frontend login/doğrulama için hem de product-service'in yetki kontrolü için kullanılır.
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    // GET http://localhost:8081/api/auth/validate?token=admin-token
    @GetMapping("/validate")
    public ResponseEntity<TokenValidationResponse> validateToken(@RequestParam String token) {
        return ResponseEntity.ok(authService.validateToken(token));
    }

    // GET http://localhost:8081/api/auth/check-permission?token=admin-token&permission=PRODUCT_WRITE
    @GetMapping("/check-permission")
    public ResponseEntity<Map<String, Object>> checkPermission(
            @RequestParam String token,
            @RequestParam String permission) {
        boolean allowed = authService.hasPermission(token, permission);
        return ResponseEntity.ok(Map.of(
                "allowed", allowed,
                "permission", permission
        ));
    }
}
