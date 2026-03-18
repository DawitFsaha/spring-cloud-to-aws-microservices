package com.lab6.stockservice;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapKeyColumn;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.util.HashMap;
import java.util.Map;

@Entity
@Table(name = "stocks", uniqueConstraints = @UniqueConstraint(columnNames = "productNumber"))
public class Stock {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private int productNumber;
    private int quantity;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "stock_reservations", joinColumns = @JoinColumn(name = "stock_id"))
    @MapKeyColumn(name = "order_id")
    @Column(name = "reserved_quantity")
    private Map<String, Integer> reservations = new HashMap<>();

    public Stock() {}

    public Stock(int productNumber, int quantity) {
        this.productNumber = productNumber;
        this.quantity = quantity;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
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
