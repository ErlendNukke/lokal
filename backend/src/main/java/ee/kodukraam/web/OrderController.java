package ee.kodukraam.web;

import ee.kodukraam.security.SecurityUtils;
import ee.kodukraam.service.OrderService;
import ee.kodukraam.service.ReviewService;
import ee.kodukraam.web.dto.ApiDtos.*;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api")
public class OrderController {

    private final OrderService orderService;
    private final ReviewService reviewService;

    public OrderController(OrderService orderService, ReviewService reviewService) {
        this.orderService = orderService;
        this.reviewService = reviewService;
    }

    @PostMapping("/orders")
    public OrderDto create(@Valid @RequestBody CreateOrderRequest request) {
        return orderService.create(SecurityUtils.currentUser(), request);
    }

    @GetMapping("/orders/mine")
    public List<OrderDto> myOrders() {
        return orderService.myOrders(SecurityUtils.currentUser());
    }

    @GetMapping("/producer/orders")
    public List<OrderDto> producerOrders() {
        return orderService.producerOrders(SecurityUtils.currentUser());
    }

    @PatchMapping("/orders/{id}/status")
    public OrderDto updateStatus(@PathVariable UUID id, @Valid @RequestBody UpdateOrderStatusRequest request) {
        return orderService.updateStatus(SecurityUtils.currentUser(), id, request);
    }

    @PostMapping("/reviews")
    public ReviewDto createReview(@Valid @RequestBody CreateReviewRequest request) {
        return reviewService.create(SecurityUtils.currentUser(), request);
    }

    @GetMapping("/producers/{id}/reviews")
    public List<ReviewDto> producerReviews(@PathVariable UUID id) {
        return reviewService.forProducer(id);
    }
}
