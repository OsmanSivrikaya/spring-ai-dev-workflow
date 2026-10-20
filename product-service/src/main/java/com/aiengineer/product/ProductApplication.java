package com.aiengineer.product;

import com.aiengineer.product.domain.Product;
import com.aiengineer.product.repository.ProductRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import java.math.BigDecimal;
import java.util.List;

/**
 * MİKROSERVİS 2: Product Service (Port: 8082)
 */
@SpringBootApplication
public class ProductApplication {

    public static void main(String[] args) {
        SpringApplication.run(ProductApplication.class, args);
    }

    @Bean
    CommandLineRunner seedProducts(ProductRepository productRepository) {
        return args -> {
            if (productRepository.count() == 0) {
                productRepository.saveAll(List.of(
                        new Product("MacBook Pro M3", "Bilgisayar", new BigDecimal("74999.00"), 8),
                        new Product("Sony WH-1000XM5 Kulaklık", "Ses & Müzik", new BigDecimal("14500.00"), 15),
                        new Product("Logitech MX Master 3S Mouse", "Aksesuar", new BigDecimal("4200.00"), 25)
                ));
            }
        };
    }
}
