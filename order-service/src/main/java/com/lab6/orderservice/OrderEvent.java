package com.lab6.orderservice;

import java.time.Instant;

public class OrderEvent {
    private String eventType;
    private String orderId;
    private int productNumber;
    private int quantity;
    private Instant occurredAt;

    public OrderEvent() {
    }

    public OrderEvent(String eventType, String orderId, int productNumber, int quantity, Instant occurredAt) {
        this.eventType = eventType;
        this.orderId = orderId;
        this.productNumber = productNumber;
        this.quantity = quantity;
        this.occurredAt = occurredAt;
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public String getOrderId() {
        return orderId;
    }

    public void setOrderId(String orderId) {
        this.orderId = orderId;
    }

    public int getProductNumber() {
        return productNumber;
    }

    public void setProductNumber(int productNumber) {
        this.productNumber = productNumber;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public Instant getOccurredAt() {
        return occurredAt;
    }

    public void setOccurredAt(Instant occurredAt) {
        this.occurredAt = occurredAt;
    }
}
