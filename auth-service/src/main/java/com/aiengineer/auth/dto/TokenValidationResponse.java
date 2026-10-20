package com.aiengineer.auth.dto;

import java.util.Set;

/**
 * .NET Karşılığı: public record TokenValidationResponse(...)
 * product-service, token doğrulamak için auth-service'i çağırdığında dönen kontrat DTO'su.
 */
public record TokenValidationResponse(
        boolean valid,
        String username,
        String role,
        Set<String> permissions
) {}
