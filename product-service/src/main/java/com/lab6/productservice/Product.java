package com.lab6.productservice;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "products", uniqueConstraints = @UniqueConstraint(columnNames = "productNumber"))
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private int productNumber;
    private String name;

    @Transient
    private int numberOnStock;

    public Product() {}

    public Product(int productNumber, String name) {
        this.productNumber = productNumber;
        this.name = name;
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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getNumberOnStock() {
        return numberOnStock;
    }

    public void setNumberOnStock(int numberOnStock) {
        this.numberOnStock = numberOnStock;
    }
}
