package com.lab6.stockservice;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

@Service
public class StockService {

    private final StockRepository stockRepository;

    public StockService(StockRepository stockRepository) {
        this.stockRepository = stockRepository;
    }

    @Transactional(readOnly = true)
    public Integer getAvailableStock(int productNumber) {
        return stockRepository.findFirstByProductNumberOrderByIdDesc(productNumber)
                .map(stock -> stock.getQuantity() - totalReserved(stock))
                .orElse(null);
    }

    @Transactional
    public Stock reserve(int productNumber, String orderId, int quantity) {
        Stock stock = stockRepository.findFirstByProductNumberOrderByIdDesc(productNumber).orElse(null);
        if (stock == null) {
            return null;
        }

        Map<String, Integer> reservations = stock.getReservations();
        if (reservations == null) {
            reservations = new HashMap<>();
            stock.setReservations(reservations);
        }

        Integer existing = reservations.get(orderId);
        if (existing != null) {
            if (existing == quantity) {
                return stock;
            }
            return null;
        }

        int available = stock.getQuantity() - totalReserved(stock);
        if (available < quantity) {
            throw new IllegalStateException("INSUFFICIENT_STOCK");
        }

        reservations.put(orderId, quantity);
        return stockRepository.save(stock);
    }

    @Transactional
    public Stock releaseReservation(int productNumber, String orderId) {
        Stock stock = stockRepository.findFirstByProductNumberOrderByIdDesc(productNumber).orElse(null);
        if (stock == null) {
            return null;
        }

        Map<String, Integer> reservations = stock.getReservations();
        if (reservations != null) {
            reservations.remove(orderId);
        }
        return stockRepository.save(stock);
    }

    @Transactional
    public Stock confirmReservation(int productNumber, String orderId) {
        Stock stock = stockRepository.findFirstByProductNumberOrderByIdDesc(productNumber).orElse(null);
        if (stock == null) {
            return null;
        }

        Map<String, Integer> reservations = stock.getReservations();
        if (reservations == null) {
            return stock;
        }

        Integer reservedQty = reservations.remove(orderId);
        if (reservedQty == null) {
            return stock;
        }

        stock.setQuantity(stock.getQuantity() - reservedQty);
        return stockRepository.save(stock);
    }

    @Transactional
    public Stock restock(int productNumber, int quantity) {
        Stock stock = stockRepository.findFirstByProductNumberOrderByIdDesc(productNumber).orElse(null);
        if (stock == null) {
            return null;
        }
        stock.setQuantity(stock.getQuantity() + quantity);
        return stockRepository.save(stock);
    }

    private int totalReserved(Stock stock) {
        Map<String, Integer> reservations = stock.getReservations();
        if (reservations == null || reservations.isEmpty()) {
            return 0;
        }
        return reservations.values().stream().mapToInt(Integer::intValue).sum();
    }
}