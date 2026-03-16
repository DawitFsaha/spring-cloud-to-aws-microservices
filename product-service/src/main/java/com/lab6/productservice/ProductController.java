package com.lab6.productservice;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/product")
public class ProductController {

    private final ProductRepository productRepository;
    private final StockClient stockClient;

    public ProductController(ProductRepository productRepository, StockClient stockClient) {
        this.productRepository = productRepository;
        this.stockClient = stockClient;
    }

    @GetMapping("/{productNumber}")
    public ResponseEntity<Product> getProduct(@PathVariable int productNumber) {
        return productRepository.findByProductNumber(productNumber)
                .map(product -> {
                    int stock = stockClient.getStock(productNumber);
                    product.setNumberOnStock(stock);
                    return ResponseEntity.ok(product);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping
    public List<Product> getAllProducts() {
        List<Product> products = productRepository.findAll();
        products.forEach(p -> p.setNumberOnStock(stockClient.getStock(p.getProductNumber())));
        return products;
    }

    @PostMapping
    public ResponseEntity<Product> createProduct(@RequestBody Product product) {
        Product saved = productRepository.save(product);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{productNumber}")
    public ResponseEntity<Product> updateProduct(@PathVariable int productNumber,
                                                 @RequestBody Product updated) {
        return productRepository.findByProductNumber(productNumber)
                .map(product -> {
                    product.setName(updated.getName());
                    return ResponseEntity.ok(productRepository.save(product));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{productNumber}")
    public ResponseEntity<Void> deleteProduct(@PathVariable int productNumber) {
        return productRepository.findByProductNumber(productNumber)
                .map(product -> {
                    productRepository.delete(product);
                    return ResponseEntity.noContent().<Void>build();
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
