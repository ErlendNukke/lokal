package ee.kodukraam.web.dto;

import ee.kodukraam.domain.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class ApiDtos {

    private ApiDtos() {}

    public record RegisterRequest(
            @NotBlank @Size(max = 120) String name,
            @NotBlank @Email String email,
            @NotBlank @Size(min = 6, max = 100) String password,
            @NotNull UserRole role,
            Double latitude,
            Double longitude,
            String city
    ) {}

    public record LoginRequest(
            @NotBlank @Email String email,
            @NotBlank String password
    ) {}

    public record GoogleLoginRequest(
            @NotBlank String idToken,
            @NotBlank String email,
            @NotBlank String name,
            UserRole role
    ) {}

    public record AuthResponse(
            String token,
            UserDto user
    ) {}

    public record UserDto(
            UUID id,
            String name,
            String email,
            UserRole role,
            Double latitude,
            Double longitude,
            String city,
            String avatarUrl,
            UUID producerProfileId,
            String farmName
    ) {}

    public record UpdateProfileRequest(
            @NotBlank String name,
            UserRole role,
            Double latitude,
            Double longitude,
            String city,
            String farmName,
            String farmDescription,
            Boolean pickupAvailable,
            Boolean deliveryAvailable,
            Integer deliveryRadiusKm
    ) {}

    public record ProducerDto(
            UUID id,
            UUID userId,
            String farmName,
            String description,
            String ownerName,
            BigDecimal ratingAvg,
            Integer ratingCount,
            Boolean pickupAvailable,
            Boolean deliveryAvailable,
            Integer deliveryRadiusKm,
            Double latitude,
            Double longitude,
            String city
    ) {}

    public record ProductRequest(
            @NotBlank @Size(max = 160) String name,
            @Size(max = 2000) String description,
            @NotNull ProductCategory category,
            @NotNull @DecimalMin("0.01") BigDecimal price,
            @NotNull ProductUnit unit,
            @NotNull @DecimalMin("0.01") BigDecimal quantity,
            @NotNull Double latitude,
            @NotNull Double longitude,
            String locationLabel,
            Boolean pickupAvailable,
            Boolean deliveryAvailable,
            List<String> photoUrls
    ) {}

    public record ProductDto(
            UUID id,
            String name,
            String description,
            ProductCategory category,
            BigDecimal price,
            ProductUnit unit,
            BigDecimal quantity,
            Double latitude,
            Double longitude,
            String locationLabel,
            Boolean pickupAvailable,
            Boolean deliveryAvailable,
            List<String> photos,
            Double distanceKm,
            ProducerSummaryDto producer,
            Instant createdAt
    ) {}

    public record ProducerSummaryDto(
            UUID id,
            String farmName,
            String ownerName,
            BigDecimal ratingAvg,
            Integer ratingCount
    ) {}

    public record CreateOrderRequest(
            @NotNull UUID productId,
            @NotNull @DecimalMin("0.01") BigDecimal quantity,
            @NotNull FulfillmentType fulfillment,
            @Size(max = 1000) String message
    ) {}

    public record OrderDto(
            UUID id,
            UUID productId,
            String productName,
            String productPhoto,
            UUID buyerId,
            String buyerName,
            UUID producerId,
            String farmName,
            BigDecimal quantity,
            ProductUnit unit,
            BigDecimal unitPrice,
            BigDecimal totalPrice,
            FulfillmentType fulfillment,
            String message,
            OrderStatus status,
            Instant createdAt,
            boolean canReview
    ) {}

    public record UpdateOrderStatusRequest(
            @NotNull OrderStatus status
    ) {}

    public record CreateReviewRequest(
            @NotNull UUID orderId,
            @NotNull @Min(1) @Max(5) Integer rating,
            @Size(max = 1000) String comment
    ) {}

    public record ReviewDto(
            UUID id,
            UUID orderId,
            UUID producerId,
            String reviewerName,
            Integer rating,
            String comment,
            Instant createdAt
    ) {}

    public record MessageResponse(String message) {}
}
