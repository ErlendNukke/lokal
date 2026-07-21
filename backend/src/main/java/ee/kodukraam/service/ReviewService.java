package ee.kodukraam.service;

import ee.kodukraam.domain.*;
import ee.kodukraam.repository.OrderRepository;
import ee.kodukraam.repository.ProducerProfileRepository;
import ee.kodukraam.repository.ReviewRepository;
import ee.kodukraam.web.dto.ApiDtos.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.UUID;

@Service
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final OrderRepository orderRepository;
    private final ProducerProfileRepository producerProfileRepository;

    public ReviewService(
            ReviewRepository reviewRepository,
            OrderRepository orderRepository,
            ProducerProfileRepository producerProfileRepository
    ) {
        this.reviewRepository = reviewRepository;
        this.orderRepository = orderRepository;
        this.producerProfileRepository = producerProfileRepository;
    }

    @Transactional
    public ReviewDto create(User reviewer, CreateReviewRequest request) {
        Order order = orderRepository.findById(request.orderId())
                .orElseThrow(() -> new IllegalArgumentException("Order not found"));
        if (!order.getBuyer().getId().equals(reviewer.getId())) {
            throw new IllegalArgumentException("Only the buyer can review this order");
        }
        if (order.getStatus() != OrderStatus.COMPLETED) {
            throw new IllegalArgumentException("Order must be completed before reviewing");
        }
        if (reviewRepository.existsByOrderId(order.getId())) {
            throw new IllegalArgumentException("Order already reviewed");
        }

        Review review = Review.builder()
                .order(order)
                .reviewer(reviewer)
                .producer(order.getProducer())
                .rating(request.rating())
                .comment(request.comment())
                .build();
        reviewRepository.save(review);
        recalculateProducerRating(order.getProducer().getId());
        return toDto(review);
    }

    @Transactional(readOnly = true)
    public List<ReviewDto> forProducer(UUID producerId) {
        return reviewRepository.findByProducerIdOrderByCreatedAtDesc(producerId).stream()
                .map(this::toDto)
                .toList();
    }

    private void recalculateProducerRating(UUID producerId) {
        List<Review> reviews = reviewRepository.findByProducerIdOrderByCreatedAtDesc(producerId);
        ProducerProfile producer = producerProfileRepository.findById(producerId).orElseThrow();
        if (reviews.isEmpty()) {
            producer.setRatingAvg(BigDecimal.ZERO);
            producer.setRatingCount(0);
        } else {
            double avg = reviews.stream().mapToInt(Review::getRating).average().orElse(0);
            producer.setRatingAvg(BigDecimal.valueOf(avg).setScale(2, RoundingMode.HALF_UP));
            producer.setRatingCount(reviews.size());
        }
        producerProfileRepository.save(producer);
    }

    private ReviewDto toDto(Review review) {
        return new ReviewDto(
                review.getId(),
                review.getOrder().getId(),
                review.getProducer().getId(),
                review.getReviewer().getName(),
                review.getRating(),
                review.getComment(),
                review.getCreatedAt()
        );
    }
}
