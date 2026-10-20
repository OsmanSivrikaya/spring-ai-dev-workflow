package com.aiengineer.product.service;

import com.aiengineer.product.client.AuthClient;
import com.aiengineer.product.domain.Product;
import com.aiengineer.product.repository.ProductRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Product-Service İş Mantığı Katmanı.
 */
@Service
public class ProductService {

    private final ProductRepository productRepository;
    private final AuthClient authClient;

    public ProductService(ProductRepository productRepository, AuthClient authClient) {
        this.productRepository = productRepository;
        this.authClient = authClient;
    }

    @Transactional(readOnly = true)
    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    @Transactional
    public Product createProduct(String token, Product product) {
        // İşlemi yapmadan önce auth-service'e soruyoruz: Bu kullanıcının PRODUCT_WRITE izni var mı?
        if (!authClient.hasPermission(token, "PRODUCT_WRITE")) {
            throw new IllegalStateException("YETKİSİZ İŞLEM: Ürün eklemek için 'PRODUCT_WRITE' yetkisi gereklidir!");
        }
        return productRepository.save(product);
    }
}
