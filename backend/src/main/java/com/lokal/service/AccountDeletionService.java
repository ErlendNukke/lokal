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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Deletes or anonymizes a user account and related personal data.
 * <p>
 * Policy: block deletion while the user has pending orders (buyer or producer). Reviews they
 * wrote are removed and producer ratings recalculated. Listings are deactivated. Order messages
 * from the user as buyer are cleared. When order history would break foreign keys, the user and
 * producer profile rows are anonymized (scrubbed PII, login disabled) instead of hard-deleted;
 * other parties still see a generic "Kustutatud konto" / farm label on past orders.
 */
@Service
public class AccountDeletionService {

    static final String DELETED_DISPLAY_NAME = "Kustutatud konto";
    static final String DELETED_FARM_NAME = "Kustutatud tootja";

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

        if (orderRepository.countByBuyerIdAndStatus(user.getId(), OrderStatus.PENDING) > 0) {
            throw new IllegalArgumentException(
                    "Complete or cancel your pending orders before deleting your account");
        }

        var producerProfile = producerProfileRepository.findByUserId(user.getId());
        if (producerProfile.isPresent()) {
            UUID producerId = producerProfile.get().getId();
            if (orderRepository.countByProducerIdAndStatus(producerId, OrderStatus.PENDING) > 0) {
                throw new IllegalArgumentException(
                        "Accept, decline, or complete pending seller orders before deleting your account");
            }
        }

        reviewService.deleteReviewsByReviewer(user.getId());

        for (Order order : orderRepository.findByBuyerId(user.getId())) {
            order.setMessage(null);
        }

        if (producerProfile.isPresent()) {
            ProducerProfile profile = producerProfile.get();
            deactivateAllProducts(profile.getId());
            if (orderRepository.existsByProducerId(profile.getId())) {
                anonymizeProducerProfile(profile);
            } else {
                deleteProducerData(profile);
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

    private void deactivateAllProducts(UUID producerId) {
        for (Product product : productRepository.findByProducerId(producerId)) {
            product.setActive(false);
            productRepository.save(product);
        }
    }

    private void deleteProducerData(ProducerProfile profile) {
        List<Product> products = productRepository.findByProducerId(profile.getId());
        productRepository.deleteAll(products);
        producerProfileRepository.delete(profile);
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
        userRepository.save(user);
    }

    static String deletedEmail(UUID userId) {
        return "deleted+" + userId + "@deleted.lokal";
    }
}
