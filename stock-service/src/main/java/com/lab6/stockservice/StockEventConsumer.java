package com.lab6.stockservice;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class StockEventConsumer {

    private final StockService stockService;

    public StockEventConsumer(StockService stockService) {
        this.stockService = stockService;
    }

    @KafkaListener(topics = "${ORDER_CREATED_TOPIC:order-created}", groupId = "${STOCK_CONSUMER_GROUP_ID:stock-service-group}")
    public void onOrderCreated(OrderEvent event) {
        if (event != null) {
            stockService.confirmReservation(event.getProductNumber(), event.getOrderId());
            System.out.println("Confirmed stock reservation for orderId=" + event.getOrderId());
        }
    }

    @KafkaListener(topics = "${ORDER_CANCELLED_TOPIC:order-cancelled}", groupId = "${STOCK_CONSUMER_GROUP_ID:stock-service-group}")
    public void onOrderCancelled(OrderEvent event) {
        if (event != null) {
            System.out.println("Received order-cancelled event for orderId=" + event.getOrderId());
        }
    }
}
