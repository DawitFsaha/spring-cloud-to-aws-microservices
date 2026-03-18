package com.lab6.orderservice;

import feign.FeignException;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/order")
public class OrderController {

    @Value("${ORDER_CREATED_TOPIC:order-created}")
    private String orderCreatedTopic;

    @Value("${ORDER_CANCELLED_TOPIC:order-cancelled}")
    private String orderCancelledTopic;

    private final OrderRepository orderRepository;
    private final KafkaTemplate<String, OrderEvent> kafkaTemplate;
    private final OrderIntegrationService integrationService;

    public OrderController(OrderRepository orderRepository,
                           KafkaTemplate<String, OrderEvent> kafkaTemplate,
                           OrderIntegrationService integrationService) {
        this.orderRepository = orderRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.integrationService = integrationService;
    }

    @GetMapping
    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Order> getOrder(@PathVariable String id) {
        return orderRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<OrderCreatedResponse> createOrder(@RequestBody CreateOrderRequest request) {
        if (request.getQuantity() <= 0) {
            return ResponseEntity.badRequest().build();
        }

        String orderId = UUID.randomUUID().toString();

        try {
            integrationService.reserveStock(request.getProductNumber(), orderId, request.getQuantity());
        } catch (FeignException.NotFound ex) {
            return ResponseEntity.notFound().build();
        } catch (FeignException.Conflict ex) {
            return ResponseEntity.status(409).build();
        } catch (IllegalStateException ex) {
            return ResponseEntity.status(503).build();
        }

        ProductResponse product;
        try {
            product = integrationService.getProduct(request.getProductNumber());
        } catch (FeignException.NotFound ex) {
            integrationService.releaseReservation(request.getProductNumber(), orderId);
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException ex) {
            integrationService.releaseReservation(request.getProductNumber(), orderId);
            return ResponseEntity.status(503).build();
        }

        Order saved;
        try {
            Order order = new Order(request.getProductNumber(), request.getQuantity(), "CREATED");
            order.setId(orderId);
            saved = orderRepository.save(order);
        } catch (RuntimeException ex) {
            integrationService.releaseReservation(request.getProductNumber(), orderId);
            throw ex;
        }

        OrderEvent event = new OrderEvent(
                "ORDER_CREATED",
                saved.getId(),
                saved.getProductNumber(),
                saved.getQuantity(),
                Instant.now()
        );
        kafkaTemplate.send(orderCreatedTopic, saved.getId(), event);

        OrderCreatedResponse response = new OrderCreatedResponse(
            saved.getId(),
            product.getProductNumber(),
            product.getName(),
            product.getNumberOnStock(),
            saved.getQuantity(),
            saved.getStatus()
        );

        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}/cancel")
    public ResponseEntity<OrderCreatedResponse> cancelOrder(@PathVariable String id) {
        var existingOptional = orderRepository.findById(id);
        if (existingOptional.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Order existing = existingOptional.get();

        if (!"CANCELLED".equals(existing.getStatus())) {
            try {
                integrationService.restock(existing.getProductNumber(), existing.getQuantity());
            } catch (FeignException.NotFound ex) {
                return ResponseEntity.notFound().build();
            } catch (IllegalStateException ex) {
                return ResponseEntity.status(503).build();
            }

            existing.setStatus("CANCELLED");
            existing = orderRepository.save(existing);

            OrderEvent event = new OrderEvent(
                    "ORDER_CANCELLED",
                    existing.getId(),
                    existing.getProductNumber(),
                    existing.getQuantity(),
                    Instant.now()
            );
            kafkaTemplate.send(orderCancelledTopic, existing.getId(), event);
        }

        ProductResponse product;
        try {
            product = integrationService.getProduct(existing.getProductNumber());
        } catch (FeignException.NotFound ex) {
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException ex) {
            return ResponseEntity.status(503).build();
        }

        OrderCreatedResponse response = new OrderCreatedResponse(
                existing.getId(),
                product.getProductNumber(),
                product.getName(),
                product.getNumberOnStock(),
                existing.getQuantity(),
                existing.getStatus()
        );

        return ResponseEntity.ok(response);
    }
}
