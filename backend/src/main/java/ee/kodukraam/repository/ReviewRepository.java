package ee.kodukraam.repository;

import ee.kodukraam.domain.Review;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ReviewRepository extends JpaRepository<Review, UUID> {
    List<Review> findByProducerIdOrderByCreatedAtDesc(UUID producerId);
    Optional<Review> findByOrderId(UUID orderId);
    boolean existsByOrderId(UUID orderId);
}
