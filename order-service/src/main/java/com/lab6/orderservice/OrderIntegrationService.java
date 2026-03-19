package com.lab6.orderservice;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class OrderIntegrationService {

    private static final Logger logger = LoggerFactory.getLogger(OrderIntegrationService.class);

    private final ProductClient productClient;
    private final StockClient stockClient;

    public OrderIntegrationService(ProductClient productClient, StockClient stockClient) {
        this.productClient = productClient;
        this.stockClient = stockClient;
    }

    @Retry(name = "productService")
    @CircuitBreaker(name = "productService", fallbackMethod = "productFallback")
    public ProductResponse getProduct(int productNumber) {
        return productClient.getProduct(productNumber);
    }

    @Retry(name = "stockService")
    @CircuitBreaker(name = "stockService", fallbackMethod = "reserveFallback")
    public StockResponse reserveStock(int productNumber, String orderId, int quantity) {
        return stockClient.reserveStock(productNumber, orderId, quantity);
    }

    @Retry(name = "stockService")
    @CircuitBreaker(name = "stockService", fallbackMethod = "releaseReservationFallback")
    public StockResponse releaseReservation(int productNumber, String orderId) {
        return stockClient.releaseReservation(productNumber, orderId);
    }

    @Retry(name = "stockService")
    @CircuitBreaker(name = "stockService", fallbackMethod = "restockFallback")
    public StockResponse restock(int productNumber, int quantity) {
        return stockClient.restock(productNumber, quantity);
    }

    private ProductResponse productFallback(int productNumber, Throwable throwable) {
        logger.warn("Circuit breaker fallback triggered for product-service. productNumber={}, errorType={}, errorMessage={}",
                productNumber,
                throwable.getClass().getSimpleName(),
                throwable.getMessage());
        throw new IllegalStateException("Product service unavailable", throwable);
    }

    private StockResponse reserveFallback(int productNumber, String orderId, int quantity, Throwable throwable) {
        logger.warn("Circuit breaker fallback triggered for stock-service reserve. productNumber={}, orderId={}, quantity={}, errorType={}, errorMessage={}",
                productNumber,
                orderId,
                quantity,
                throwable.getClass().getSimpleName(),
                throwable.getMessage());
        throw new IllegalStateException("Stock service unavailable for reservation", throwable);
    }

    private StockResponse releaseReservationFallback(int productNumber, String orderId, Throwable throwable) {
        logger.warn("Circuit breaker fallback triggered for stock-service release reservation. productNumber={}, orderId={}, errorType={}, errorMessage={}",
                productNumber,
                orderId,
                throwable.getClass().getSimpleName(),
                throwable.getMessage());
        throw new IllegalStateException("Stock service unavailable for reservation release", throwable);
    }

    private StockResponse restockFallback(int productNumber, int quantity, Throwable throwable) {
        logger.warn("Circuit breaker fallback triggered for stock-service restock. productNumber={}, quantity={}, errorType={}, errorMessage={}",
                productNumber,
                quantity,
                throwable.getClass().getSimpleName(),
                throwable.getMessage());
        throw new IllegalStateException("Stock service unavailable for restock", throwable);
    }
}
