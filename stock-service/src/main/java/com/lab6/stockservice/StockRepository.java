package com.lab6.stockservice;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StockRepository extends JpaRepository<Stock, Long> {
    Optional<Stock> findFirstByProductNumberOrderByIdDesc(int productNumber);
}
