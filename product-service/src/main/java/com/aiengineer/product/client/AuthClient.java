package com.aiengineer.product.client;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.Map;

/**
 * .NET Karşılığı: Typed HttpClient (IHttpClientFactory).
 * product-service'in auth-service (Port 8081) ile konuştuğu HTTP istemcisi.
 */
@Component
public class AuthClient {

    private final RestClient restClient;

    public AuthClient(@Value("${services.auth.base-url:http://localhost:8081}") String authBaseUrl) {
        this.restClient = RestClient.builder()
                .baseUrl(authBaseUrl)
                .build();
    }

    public boolean hasPermission(String token, String permission) {
        Map<?, ?> response = restClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/api/auth/check-permission")
                        .queryParam("token", token)
                        .queryParam("permission", permission)
                        .build())
                .retrieve()
                .body(Map.class);

        return response != null && Boolean.TRUE.equals(response.get("allowed"));
    }
}
