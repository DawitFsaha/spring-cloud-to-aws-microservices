package com.lab6.orderservice;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "product-service", url = "${PRODUCT_SERVICE_BASE_URL:http://product-service.demo.local:8901}")
public interface ProductClient {

    @GetMapping("/product/{productNumber}")
    ProductResponse getProduct(@PathVariable("productNumber") int productNumber);
}
