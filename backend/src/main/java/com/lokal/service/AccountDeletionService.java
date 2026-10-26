package com.lokal.service;

import com.lokal.domain.Order;
import com.lokal.domain.OrderStatus;
import com.lokal.domain.ProducerProfile;
import com.lokal.domain.Product;
import com.lokal.domain.User;
import com.lokal.repository.OrderRepository;
import com.lokal.repository.ProducerProfileRepository;
import com.lokal.repository.ProductRepository;
import com.lokal.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * Deletes or anonymizes a user account and related personal data.
 * <p>
 * Policy: block deletion while the user has open orders (pending or accepted, as buyer or producer)
 * and for the shared demo accounts. Reviews they wrote are removed and producer ratings recalculated.
 * Order messages from the user as buyer are cleared. Producer listings are deleted when no order
 * references them; otherwise they are deactivated and stripped of description, location and photos.
 * When order history would break foreign keys, the user and producer profile rows are anonymized
 * (scrubbed PII, login disabled, {@code deleted_at} set so old JWTs are rejected) instead of
 * hard-deleted; other parties still see a generic "Kustutatud konto" / farm label on past orders.
 * <p>
 * Uploaded photo files in object storage (R2) are not removed: {@link StorageService} has no delete
 * operation yet. Only the database references are dropped.
 */
@Service
public class AccountDeletionService {

    static final String DELETED_DISPLAY_NAME = "Kustutatud konto";
    static final String DELETED_FARM_NAME = "Kustutatud tootja";
    static final String DELETED_EMAIL_DOMAIN = "@deleted.lokal";

    /** Seeded demo accounts shared by all visitors (see 002-sample-data.yaml). */
    static final Set<String> DEMO_EMAILS = Set.of(
            "anna@lokal.app", "mari@lokal.app", "juri@lokal.app", "liisa@lokal.app");

    private static final List<OrderStatus> OPEN_STATUSES = List.of(OrderStatus.PENDING, OrderStatus.ACCEPTED);

    private final UserRepository userRepository;
    private final ProducerProfileRepository producerProfileRepository;
    private final ProductRepository productRepository;
    private final OrderRepository orderRepository;
    private final ReviewService reviewService;

    public AccountDeletionService(
            UserRepository userRepository,
            ProducerProfileRepository producerProfileRepository,
            ProductRepository productRepository,
            OrderRepository orderRepository,
            ReviewService reviewService
    ) {
        this.userRepository = userRepository;
        this.producerProfileRepository = producerProfileRepository;
        this.productRepository = productRepository;
        this.orderRepository = orderRepository;
        this.reviewService = reviewService;
    }

    @Transactional
    public void deleteAccount(User current) {
        User user = userRepository.findById(current.getId()).orElseThrow();

        if (isDemoAccount(user)) {
            throw new AccountDeletionBlockedException(HttpStatus.FORBIDDEN,
                    AccountDeletionBlockedException.DEMO_ACCOUNT, "Demo accounts cannot be deleted");
        }

        if (orderRepository.countByBuyerIdAndStatusIn(user.getId(), OPEN_STATUSES) > 0) {
            throw new AccountDeletionBlockedException(HttpStatus.CONFLICT,
                    AccountDeletionBlockedException.PENDING_ORDERS,
                    "Complete or cancel your open orders before deleting your account");
        }

        var producerProfile = producerProfileRepository.findByUserId(user.getId());
        if (producerProfile.isPresent()) {
            UUID producerId = producerProfile.get().getId();
            if (orderRepository.countByProducerIdAndStatusIn(producerId, OPEN_STATUSES) > 0) {
                throw new AccountDeletionBlockedException(HttpStatus.CONFLICT,
                        AccountDeletionBlockedException.PENDING_SELLER_ORDERS,
                        "Accept, decline, or complete open seller orders before deleting your account");
            }
        }

        reviewService.deleteReviewsByReviewer(user.getId());

        for (Order order : orderRepository.findByBuyerId(user.getId())) {
            order.setMessage(null);
        }

        if (producerProfile.isPresent()) {
            ProducerProfile profile = producerProfile.get();
            removeOrScrubProducts(profile.getId());
            if (orderRepository.existsByProducerId(profile.getId())) {
                anonymizeProducerProfile(profile);
            } else {
                producerProfileRepository.delete(profile);
            }
        }

        boolean keepUserRow = orderRepository.existsByBuyerId(user.getId())
                || producerProfileRepository.findByUserId(user.getId()).isPresent();
        if (keepUserRow) {
            anonymizeUser(user);
        } else {
            userRepository.delete(user);
        }
    }

    static boolean isDemoAccount(User user) {
        return user.getEmail() != null && DEMO_EMAILS.contains(user.getEmail().toLowerCase(Locale.ROOT));
    }

    /** Products without orders are deleted; ones referenced by past orders keep only name/unit/price. */
    private void removeOrScrubProducts(UUID producerId) {
        for (Product product : productRepository.findByProducerId(producerId)) {
            if (orderRepository.existsByProductId(product.getId())) {
                product.setActive(false);
                product.setDescription(null);
                product.setLocationLabel(null);
                product.setLatitude(0.0);
                product.setLongitude(0.0);
                product.getPhotos().clear();
                productRepository.save(product);
            } else {
                productRepository.delete(product);
            }
        }
    }

    private void anonymizeProducerProfile(ProducerProfile profile) {
        profile.setFarmName(DELETED_FARM_NAME);
        profile.setDescription(null);
        producerProfileRepository.save(profile);
    }

    private void anonymizeUser(User user) {
        user.setName(DELETED_DISPLAY_NAME);
        user.setEmail(deletedEmail(user.getId()));
        user.setPasswordHash(null);
        user.setLatitude(null);
        user.setLongitude(null);
        user.setCity(null);
        user.setAvatarUrl(null);
        user.setDeletedAt(Instant.now());
        userRepository.save(user);
    }

    static String deletedEmail(UUID userId) {
        return "deleted+" + userId + DELETED_EMAIL_DOMAIN;
    }
}
