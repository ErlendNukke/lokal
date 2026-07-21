package ee.kodukraam.service;

import ee.kodukraam.domain.*;
import ee.kodukraam.repository.ProducerProfileRepository;
import ee.kodukraam.repository.ProductRepository;
import ee.kodukraam.util.GeoUtils;
import ee.kodukraam.web.dto.ApiDtos.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class ProductService {

    private final ProductRepository productRepository;
    private final ProducerProfileRepository producerProfileRepository;

    public ProductService(ProductRepository productRepository, ProducerProfileRepository producerProfileRepository) {
        this.productRepository = productRepository;
        this.producerProfileRepository = producerProfileRepository;
    }

    @Transactional(readOnly = true)
    public List<ProductDto> search(Double lat, Double lng, Integer radiusKm, ProductCategory category, String q) {
        List<Product> products = productRepository.searchActive(category, blankToNull(q));
        return products.stream()
                .filter(p -> withinRadius(p, lat, lng, radiusKm))
                .map(p -> {
                    p.getPhotos().size();
                    return toDto(p, lat, lng);
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public ProductDto get(UUID id, Double lat, Double lng) {
        Product product = productRepository.findDetailedById(id)
                .orElseThrow(() -> new IllegalArgumentException("Product not found"));
        product.getPhotos().size();
        return toDto(product, lat, lng);
    }

    @Transactional(readOnly = true)
    public List<ProductDto> myProducts(User user) {
        ProducerProfile producer = requireProducer(user);
        return productRepository.findByProducerIdAndActiveTrueOrderByCreatedAtDesc(producer.getId()).stream()
                .map(p -> {
                    p.getPhotos().size();
                    return toDto(p, user.getLatitude(), user.getLongitude());
                })
                .toList();
    }

    @Transactional
    public ProductDto create(User user, ProductRequest request) {
        ProducerProfile producer = requireProducer(user);
        Product product = Product.builder()
                .producer(producer)
                .name(request.name().trim())
                .description(request.description())
                .category(request.category())
                .price(request.price())
                .unit(request.unit())
                .quantity(request.quantity())
                .latitude(request.latitude())
                .longitude(request.longitude())
                .locationLabel(request.locationLabel())
                .pickupAvailable(request.pickupAvailable() != null ? request.pickupAvailable() : true)
                .deliveryAvailable(request.deliveryAvailable() != null ? request.deliveryAvailable() : false)
                .build();

        if (request.photoUrls() != null) {
            int i = 0;
            for (String url : request.photoUrls()) {
                if (url != null && !url.isBlank()) {
                    product.addPhoto(ProductPhoto.builder().url(url.trim()).sortOrder(i++).build());
                }
            }
        }

        return toDto(productRepository.save(product), user.getLatitude(), user.getLongitude());
    }

    @Transactional
    public ProductDto update(User user, UUID id, ProductRequest request) {
        ProducerProfile producer = requireProducer(user);
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Product not found"));
        if (!product.getProducer().getId().equals(producer.getId())) {
            throw new IllegalArgumentException("Not your product");
        }

        product.setName(request.name().trim());
        product.setDescription(request.description());
        product.setCategory(request.category());
        product.setPrice(request.price());
        product.setUnit(request.unit());
        product.setQuantity(request.quantity());
        product.setLatitude(request.latitude());
        product.setLongitude(request.longitude());
        product.setLocationLabel(request.locationLabel());
        if (request.pickupAvailable() != null) {
            product.setPickupAvailable(request.pickupAvailable());
        }
        if (request.deliveryAvailable() != null) {
            product.setDeliveryAvailable(request.deliveryAvailable());
        }

        if (request.photoUrls() != null) {
            product.getPhotos().clear();
            int i = 0;
            for (String url : request.photoUrls()) {
                if (url != null && !url.isBlank()) {
                    product.addPhoto(ProductPhoto.builder().url(url.trim()).sortOrder(i++).build());
                }
            }
        }

        return toDto(productRepository.save(product), user.getLatitude(), user.getLongitude());
    }

    @Transactional
    public void deactivate(User user, UUID id) {
        ProducerProfile producer = requireProducer(user);
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Product not found"));
        if (!product.getProducer().getId().equals(producer.getId())) {
            throw new IllegalArgumentException("Not your product");
        }
        product.setActive(false);
        productRepository.save(product);
    }

    @Transactional(readOnly = true)
    public ProducerDto getProducer(UUID id) {
        ProducerProfile profile = producerProfileRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Producer not found"));
        User owner = profile.getUser();
        return new ProducerDto(
                profile.getId(),
                owner.getId(),
                profile.getFarmName(),
                profile.getDescription(),
                owner.getName(),
                profile.getRatingAvg(),
                profile.getRatingCount(),
                profile.getPickupAvailable(),
                profile.getDeliveryAvailable(),
                profile.getDeliveryRadiusKm(),
                owner.getLatitude(),
                owner.getLongitude(),
                owner.getCity()
        );
    }

    private ProducerProfile requireProducer(User user) {
        if (user.getRole() != UserRole.PRODUCER && user.getRole() != UserRole.BOTH) {
            throw new IllegalArgumentException("Producer role required");
        }
        return producerProfileRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Producer profile missing — update your profile first"));
    }

    private ProductDto toDto(Product product, Double lat, Double lng) {
        Double distance = null;
        if (lat != null && lng != null) {
            distance = GeoUtils.distanceKm(lat, lng, product.getLatitude(), product.getLongitude());
            distance = Math.round(distance * 10.0) / 10.0;
        }
        ProducerProfile producer = product.getProducer();
        User owner = producer.getUser();
        List<String> photos = product.getPhotos().stream().map(ProductPhoto::getUrl).toList();
        return new ProductDto(
                product.getId(),
                product.getName(),
                product.getDescription(),
                product.getCategory(),
                product.getPrice(),
                product.getUnit(),
                product.getQuantity(),
                product.getLatitude(),
                product.getLongitude(),
                product.getLocationLabel(),
                product.getPickupAvailable(),
                product.getDeliveryAvailable(),
                photos,
                distance,
                new ProducerSummaryDto(
                        producer.getId(),
                        producer.getFarmName(),
                        owner.getName(),
                        producer.getRatingAvg(),
                        producer.getRatingCount()
                ),
                product.getCreatedAt()
        );
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private boolean withinRadius(Product product, Double lat, Double lng, Integer radiusKm) {
        if (lat == null || lng == null || radiusKm == null) {
            return true;
        }
        return GeoUtils.distanceKm(lat, lng, product.getLatitude(), product.getLongitude()) <= radiusKm;
    }
}
