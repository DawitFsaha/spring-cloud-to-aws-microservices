package com.lab6.stockservice;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class StockEventConsumer {

    private final StockService stockService;

    public StockEventConsumer(StockService stockService) {
        this.stockService = stockService;
    }

    @KafkaListener(topics = "order-created", groupId = "stock-service-group")
    public void onOrderCreated(OrderEvent event) {
        if (event != null) {
            stockService.confirmReservation(event.getProductNumber(), event.getOrderId());
            System.out.println("Confirmed stock reservation for orderId=" + event.getOrderId());
        }
    }

    @KafkaListener(topics = "order-cancelled", groupId = "stock-service-group")
    public void onOrderCancelled(OrderEvent event) {
        if (event != null) {
            System.out.println("Received order-cancelled event for orderId=" + event.getOrderId());
        }
    }
}
