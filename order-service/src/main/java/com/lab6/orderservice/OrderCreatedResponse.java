package com.lab6.orderservice;

public class OrderCreatedResponse {
    private String orderId;
    private int productNumber;
    private String productName;
    private int numberOnStock;
    private int numberOrdered;
    private String status;

    public OrderCreatedResponse() {
    }

    public OrderCreatedResponse(String orderId, int productNumber, String productName,
                                int numberOnStock, int numberOrdered, String status) {
        this.orderId = orderId;
        this.productNumber = productNumber;
        this.productName = productName;
        this.numberOnStock = numberOnStock;
        this.numberOrdered = numberOrdered;
        this.status = status;
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

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public int getNumberOnStock() {
        return numberOnStock;
    }

    public void setNumberOnStock(int numberOnStock) {
        this.numberOnStock = numberOnStock;
    }

    public int getNumberOrdered() {
        return numberOrdered;
    }

    public void setNumberOrdered(int numberOrdered) {
        this.numberOrdered = numberOrdered;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
