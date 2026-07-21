package com.lokal.service;

import com.lokal.domain.*;
import com.lokal.repository.OrderRepository;
import com.lokal.repository.ProductRepository;
import com.lokal.repository.ProducerProfileRepository;
import com.lokal.repository.ReviewRepository;
import com.lokal.web.dto.ApiDtos.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.EnumSet;
import java.util.List;
import java.util.UUID;

@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final ProducerProfileRepository producerProfileRepository;
    private final ReviewRepository reviewRepository;

    public OrderService(
            OrderRepository orderRepository,
            ProductRepository productRepository,
            ProducerProfileRepository producerProfileRepository,
            ReviewRepository reviewRepository
    ) {
        this.orderRepository = orderRepository;
        this.productRepository = productRepository;
        this.producerProfileRepository = producerProfileRepository;
        this.reviewRepository = reviewRepository;
    }

    @Transactional
    public OrderDto create(User buyer, CreateOrderRequest request) {
        if (buyer.getRole() == UserRole.PRODUCER) {
            throw new IllegalArgumentException("Switch to buyer role to place orders");
        }
        Product product = productRepository.findById(request.productId())
                .orElseThrow(() -> new IllegalArgumentException("Product not found"));
        if (!Boolean.TRUE.equals(product.getActive())) {
            throw new IllegalArgumentException("Product is not available");
        }
        if (product.getQuantity().compareTo(request.quantity()) < 0) {
            throw new IllegalArgumentException("Not enough quantity available");
        }
        if (request.fulfillment() == FulfillmentType.PICKUP && !Boolean.TRUE.equals(product.getPickupAvailable())) {
            throw new IllegalArgumentException("Pickup not available for this product");
        }
        if (request.fulfillment() == FulfillmentType.DELIVERY && !Boolean.TRUE.equals(product.getDeliveryAvailable())) {
            throw new IllegalArgumentException("Delivery not available for this product");
        }

        Order order = Order.builder()
                .buyer(buyer)
                .product(product)
                .producer(product.getProducer())
                .quantity(request.quantity())
                .unitPrice(product.getPrice())
                .fulfillment(request.fulfillment())
                .message(request.message())
                .status(OrderStatus.PENDING)
                .build();

        return toDto(orderRepository.save(order), buyer);
    }

    @Transactional(readOnly = true)
    public List<OrderDto> myOrders(User user) {
        return orderRepository.findByBuyerId(user.getId()).stream()
                .map(o -> toDto(o, user))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<OrderDto> producerOrders(User user) {
        ProducerProfile producer = producerProfileRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Producer profile required"));
        return orderRepository.findByProducerId(producer.getId()).stream()
                .map(o -> toDto(o, user))
                .toList();
    }

    @Transactional
    public OrderDto updateStatus(User user, UUID orderId, UpdateOrderStatusRequest request) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found"));

        OrderStatus next = request.status();
        boolean isProducer = producerProfileRepository.findByUserId(user.getId())
                .map(p -> p.getId().equals(order.getProducer().getId()))
                .orElse(false);
        boolean isBuyer = order.getBuyer().getId().equals(user.getId());

        if (isProducer) {
            if (!EnumSet.of(OrderStatus.ACCEPTED, OrderStatus.REJECTED, OrderStatus.COMPLETED).contains(next)) {
                throw new IllegalArgumentException("Producer can accept, reject, or complete orders");
            }
            if (order.getStatus() == OrderStatus.PENDING && (next == OrderStatus.ACCEPTED || next == OrderStatus.REJECTED)) {
                if (next == OrderStatus.ACCEPTED) {
                    Product product = order.getProduct();
                    if (product.getQuantity().compareTo(order.getQuantity()) < 0) {
                        throw new IllegalArgumentException("Not enough stock to accept");
                    }
                    product.setQuantity(product.getQuantity().subtract(order.getQuantity()));
                }
                order.setStatus(next);
            } else if (order.getStatus() == OrderStatus.ACCEPTED && next == OrderStatus.COMPLETED) {
                order.setStatus(OrderStatus.COMPLETED);
            } else {
                throw new IllegalArgumentException("Invalid status transition");
            }
        } else if (isBuyer) {
            if (next != OrderStatus.CANCELLED || order.getStatus() != OrderStatus.PENDING) {
                throw new IllegalArgumentException("Buyer can only cancel pending orders");
            }
            order.setStatus(OrderStatus.CANCELLED);
        } else {
            throw new IllegalArgumentException("Not allowed to update this order");
        }

        return toDto(orderRepository.save(order), user);
    }

    private OrderDto toDto(Order order, User viewer) {
        Product product = order.getProduct();
        String photo = product.getPhotos().isEmpty() ? null : product.getPhotos().getFirst().getUrl();
        boolean canReview = order.getStatus() == OrderStatus.COMPLETED
                && order.getBuyer().getId().equals(viewer.getId())
                && !reviewRepository.existsByOrderId(order.getId());
        BigDecimal total = order.getUnitPrice().multiply(order.getQuantity());
        return new OrderDto(
                order.getId(),
                product.getId(),
                product.getName(),
                photo,
                order.getBuyer().getId(),
                order.getBuyer().getName(),
                order.getProducer().getId(),
                order.getProducer().getFarmName(),
                order.getQuantity(),
                product.getUnit(),
                order.getUnitPrice(),
                total,
                order.getFulfillment(),
                order.getMessage(),
                order.getStatus(),
                order.getCreatedAt(),
                canReview
        );
    }
}
