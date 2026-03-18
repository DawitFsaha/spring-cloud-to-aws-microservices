package com.lab6.orderservice;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@FeignClient(name = "stock-service", url = "${STOCK_SERVICE_BASE_URL:http://stock-service.demo.local:8900}")
public interface StockClient {

    @PostMapping("/stock/{productNumber}/reserve")
    StockResponse reserveStock(@PathVariable("productNumber") int productNumber,
                               @RequestParam("orderId") String orderId,
                               @RequestParam("quantity") int quantity);

    @PostMapping("/stock/{productNumber}/release-reservation")
    StockResponse releaseReservation(@PathVariable("productNumber") int productNumber,
                                     @RequestParam("orderId") String orderId);

    @PostMapping("/stock/{productNumber}/restock")
    StockResponse restock(@PathVariable("productNumber") int productNumber,
                          @RequestParam("quantity") int quantity);
}
