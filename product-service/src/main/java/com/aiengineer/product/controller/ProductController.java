package com.aiengineer.product.controller;

import com.aiengineer.product.domain.Product;
import com.aiengineer.product.service.ProductService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Product-Service REST API (Port: 8082).
 */
@RestController
@RequestMapping("/api/products")
@CrossOrigin(origins = "*")
public class ProductController {

    private final ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping
    public ResponseEntity<List<Product>> getAllProducts() {
        return ResponseEntity.ok(productService.getAllProducts());
    }

    @PostMapping
    public ResponseEntity<Product> createProduct(
            @RequestHeader("X-Auth-Token") String token,
            @RequestBody Product product) {
        Product saved = productService.createProduct(token, product);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }
}
