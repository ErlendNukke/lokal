package com.lokal.service;

import com.lokal.domain.ProducerProfile;
import com.lokal.domain.Product;
import com.lokal.domain.ProductPhoto;
import com.lokal.domain.User;
import com.lokal.domain.UserRole;
import com.lokal.repository.OrderRepository;
import com.lokal.repository.ProducerProfileRepository;
import com.lokal.repository.ProductRepository;
import com.lokal.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AccountDeletionServiceTest {

    @Mock
    UserRepository userRepository;
    @Mock
    ProducerProfileRepository producerProfileRepository;
    @Mock
    ProductRepository productRepository;
    @Mock
    OrderRepository orderRepository;
    @Mock
    ReviewService reviewService;
    @Mock
    StorageService storageService;

    @InjectMocks
    AccountDeletionService accountDeletionService;

    @Test
    void deleteAccount_collectsPhotoAndAvatarUrlsBeforeDbDelete() {
        UUID userId = UUID.randomUUID();
        UUID producerId = UUID.randomUUID();
        User user = User.builder()
                .id(userId)
                .name("Farmer")
                .email("farmer@example.com")
                .role(UserRole.PRODUCER)
                .avatarUrl("http://localhost/uploads/avatar.jpg")
                .build();
        ProducerProfile profile = ProducerProfile.builder().id(producerId).user(user).farmName("Farm").build();
        Product product = Product.builder().id(UUID.randomUUID()).producer(profile).name("Honey").build();
        product.getPhotos().add(ProductPhoto.builder().url("http://localhost/uploads/p1.jpg").build());
        product.getPhotos().add(ProductPhoto.builder().url("https://images.unsplash.com/x.jpg").build());

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(orderRepository.countByBuyerIdAndStatusIn(any(), any())).thenReturn(0L);
        when(producerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(profile), Optional.empty());
        when(orderRepository.countByProducerIdAndStatusIn(any(), any())).thenReturn(0L);
        when(orderRepository.findByBuyerId(userId)).thenReturn(List.of());
        when(orderRepository.existsByProducerId(producerId)).thenReturn(false);
        when(orderRepository.existsByBuyerId(userId)).thenReturn(false);
        when(productRepository.findByProducerId(producerId)).thenReturn(List.of(product));

        accountDeletionService.deleteAccount(user);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<String>> urlsCaptor = ArgumentCaptor.forClass(List.class);
        verify(storageService).deleteManagedUrls(urlsCaptor.capture());
        List<String> urls = urlsCaptor.getValue();
        assertTrue(urls.contains("http://localhost/uploads/avatar.jpg"));
        assertTrue(urls.contains("http://localhost/uploads/p1.jpg"));
        assertTrue(urls.contains("https://images.unsplash.com/x.jpg"));
        verify(producerProfileRepository).delete(profile);
        verify(userRepository).delete(user);
    }

    @Test
    void deleteAccount_completesWhenStorageCleanupThrows() {
        UUID userId = UUID.randomUUID();
        UUID producerId = UUID.randomUUID();
        User user = User.builder()
                .id(userId)
                .name("Producer")
                .email("producer@example.com")
                .role(UserRole.PRODUCER)
                .build();
        ProducerProfile profile = ProducerProfile.builder().id(producerId).user(user).farmName("Farm").build();
        Product product = Product.builder().id(UUID.randomUUID()).producer(profile).name("Honey").build();
        product.getPhotos().add(ProductPhoto.builder().url("http://localhost/uploads/p1.jpg").build());

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(orderRepository.countByBuyerIdAndStatusIn(any(), any())).thenReturn(0L);
        when(producerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(profile), Optional.empty());
        when(orderRepository.countByProducerIdAndStatusIn(any(), any())).thenReturn(0L);
        when(orderRepository.findByBuyerId(userId)).thenReturn(List.of());
        when(orderRepository.existsByProducerId(producerId)).thenReturn(false);
        when(orderRepository.existsByBuyerId(userId)).thenReturn(false);
        when(productRepository.findByProducerId(producerId)).thenReturn(List.of(product));
        doThrow(new RuntimeException("R2 down")).when(storageService).deleteManagedUrls(anyList());

        accountDeletionService.deleteAccount(user);

        verify(userRepository).delete(user);
    }
}
