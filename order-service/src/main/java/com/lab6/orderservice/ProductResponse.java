package com.lab6.orderservice;

public class ProductResponse {
    private String id;
    private int productNumber;
    private String name;
    private int numberOnStock;

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
