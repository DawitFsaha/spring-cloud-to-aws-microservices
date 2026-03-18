package com.lab6.stockservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/stock")
public class StockController {

    private final StockRepository stockRepository;
    private final StockService stockService;

    /** If set (>= 0), this fixed value is returned for every product instead of querying the DB.
     *  Injected via the STOCK_FIXED_VALUE environment variable. */
    @Value("${stock.fixed-value:-1}")
    private int fixedStockValue;

    public StockController(StockRepository stockRepository, StockService stockService) {
        this.stockRepository = stockRepository;
        this.stockService = stockService;
    }

    @GetMapping("/{productNumber}")
    public ResponseEntity<Integer> getStock(@PathVariable int productNumber) {
        if (fixedStockValue >= 0) {
            return ResponseEntity.ok(fixedStockValue);
        }
        Integer available = stockService.getAvailableStock(productNumber);
        if (available == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(available);
    }

    @PostMapping
    public ResponseEntity<Stock> createStock(@RequestBody Stock stock) {
        Stock saved = stockRepository.save(stock);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{productNumber}")
    public ResponseEntity<Stock> updateStock(@PathVariable int productNumber,
                                             @RequestParam int quantity) {
        return stockRepository.findFirstByProductNumberOrderByIdDesc(productNumber)
                .map(stock -> {
                    stock.setQuantity(quantity);
                    return ResponseEntity.ok(stockRepository.save(stock));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/{productNumber}/reserve")
    public ResponseEntity<Stock> reserveStock(@PathVariable int productNumber,
                                              @RequestParam String orderId,
                                              @RequestParam int quantity) {
        if (quantity <= 0) {
            return ResponseEntity.badRequest().build();
        }

        try {
            Stock updated = stockService.reserve(productNumber, orderId, quantity);
            if (updated == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(updated);
        } catch (IllegalStateException ex) {
            if ("INSUFFICIENT_STOCK".equals(ex.getMessage())) {
                return ResponseEntity.status(409).build();
            }
            throw ex;
        }
    }

    @PostMapping("/{productNumber}/release-reservation")
    public ResponseEntity<Stock> releaseReservation(@PathVariable int productNumber,
                                                    @RequestParam String orderId) {
        Stock updated = stockService.releaseReservation(productNumber, orderId);
        if (updated == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(updated);
    }

    @PostMapping("/{productNumber}/restock")
    public ResponseEntity<Stock> restock(@PathVariable int productNumber,
                                         @RequestParam int quantity) {
        if (quantity <= 0) {
            return ResponseEntity.badRequest().build();
        }
        Stock updated = stockService.restock(productNumber, quantity);
        if (updated == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{productNumber}")
    public ResponseEntity<Void> deleteStock(@PathVariable int productNumber) {
        return stockRepository.findFirstByProductNumberOrderByIdDesc(productNumber)
                .map(stock -> {
                    stockRepository.delete(stock);
                    return ResponseEntity.noContent().<Void>build();
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
