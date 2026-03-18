package com.lab6.stockservice;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {

    private final StockRepository stockRepository;

    public DataInitializer(StockRepository stockRepository) {
        this.stockRepository = stockRepository;
    }

    @Override
    public void run(String... args) {
        if (stockRepository.count() == 0) {
            stockRepository.saveAll(List.of(
                    new Stock(1, 50),
                    new Stock(2, 120),
                    new Stock(3, 0),
                    new Stock(4, 35),
                    new Stock(5, 200)
            ));
            System.out.println("Stock data seeded into PostgreSQL (app_db).");
        }
    }
}
