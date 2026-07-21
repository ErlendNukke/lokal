package ee.kodukraam.domain;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "producer_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProducerProfile {

    @Id
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "farm_name", nullable = false, length = 160)
    private String farmName;

    @Column(length = 2000)
    private String description;

    @Column(name = "rating_avg", precision = 3, scale = 2)
    private BigDecimal ratingAvg;

    @Column(name = "rating_count")
    private Integer ratingCount;

    @Column(name = "pickup_available")
    private Boolean pickupAvailable;

    @Column(name = "delivery_available")
    private Boolean deliveryAvailable;

    @Column(name = "delivery_radius_km")
    private Integer deliveryRadiusKm;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        createdAt = Instant.now();
        if (ratingAvg == null) {
            ratingAvg = BigDecimal.ZERO;
        }
        if (ratingCount == null) {
            ratingCount = 0;
        }
        if (pickupAvailable == null) {
            pickupAvailable = true;
        }
        if (deliveryAvailable == null) {
            deliveryAvailable = false;
        }
        if (deliveryRadiusKm == null) {
            deliveryRadiusKm = 10;
        }
    }
}
