package ee.kodukraam.web;

import ee.kodukraam.domain.ProductCategory;
import ee.kodukraam.security.SecurityUtils;
import ee.kodukraam.service.ProductService;
import ee.kodukraam.service.StorageService;
import ee.kodukraam.web.dto.ApiDtos.*;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api")
public class ProductController {

    private final ProductService productService;
    private final StorageService storageService;

    public ProductController(ProductService productService, StorageService storageService) {
        this.productService = productService;
        this.storageService = storageService;
    }

    @GetMapping("/products")
    public List<ProductDto> search(
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false, defaultValue = "20") Integer radiusKm,
            @RequestParam(required = false) ProductCategory category,
            @RequestParam(required = false) String q
    ) {
        return productService.search(lat, lng, radiusKm, category, q);
    }

    @GetMapping("/products/{id}")
    public ProductDto get(
            @PathVariable UUID id,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng
    ) {
        return productService.get(id, lat, lng);
    }

    @GetMapping("/producer/products")
    public List<ProductDto> myProducts() {
        return productService.myProducts(SecurityUtils.currentUser());
    }

    @PostMapping("/producer/products")
    public ProductDto create(@Valid @RequestBody ProductRequest request) {
        return productService.create(SecurityUtils.currentUser(), request);
    }

    @PutMapping("/producer/products/{id}")
    public ProductDto update(@PathVariable UUID id, @Valid @RequestBody ProductRequest request) {
        return productService.update(SecurityUtils.currentUser(), id, request);
    }

    @DeleteMapping("/producer/products/{id}")
    public MessageResponse delete(@PathVariable UUID id) {
        productService.deactivate(SecurityUtils.currentUser(), id);
        return new MessageResponse("Product deactivated");
    }

    @PostMapping("/uploads")
    public Map<String, String> upload(@RequestParam("file") MultipartFile file) {
        return Map.of("url", storageService.store(file));
    }

    @GetMapping("/producers/{id}")
    public ProducerDto producer(@PathVariable UUID id) {
        return productService.getProducer(id);
    }
}
