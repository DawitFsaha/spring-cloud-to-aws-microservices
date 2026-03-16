package com.lab6.stockservice;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.HashMap;
import java.util.Map;

@Document(collection = "stocks")
public class Stock {

    @Id
    private String id;
    private int productNumber;
    private int quantity;
    private Map<String, Integer> reservations = new HashMap<>();

    public Stock() {}

    public Stock(int productNumber, int quantity) {
        this.productNumber = productNumber;
        this.quantity = quantity;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
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

    public Map<String, Integer> getReservations() {
        return reservations;
    }

    public void setReservations(Map<String, Integer> reservations) {
        this.reservations = reservations;
    }
}
