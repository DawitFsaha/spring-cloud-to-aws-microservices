package com.lab6.productservice;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {

    private final ProductRepository productRepository;

    public DataInitializer(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    @Override
    public void run(String... args) {
        if (productRepository.count() == 0) {
            productRepository.saveAll(List.of(
                    new Product(1, "Laptop"),
                    new Product(2, "Smartphone"),
                    new Product(3, "Tablet"),
                    new Product(4, "Monitor"),
                    new Product(5, "Keyboard")
            ));
            System.out.println("Product data seeded into PostgreSQL (app_db).");
        }
    }
}
