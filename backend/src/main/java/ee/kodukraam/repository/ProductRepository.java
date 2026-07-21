package ee.kodukraam.repository;

import ee.kodukraam.domain.Product;
import ee.kodukraam.domain.ProductCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProductRepository extends JpaRepository<Product, UUID> {

    List<Product> findByProducerIdAndActiveTrueOrderByCreatedAtDesc(UUID producerId);

    @Query("""
            SELECT DISTINCT p FROM Product p
            JOIN FETCH p.producer pr
            JOIN FETCH pr.user
            WHERE p.active = true
              AND (:category IS NULL OR p.category = :category)
              AND (
                :q IS NULL OR LOWER(p.name) LIKE LOWER(CONCAT('%', CAST(:q AS string), '%'))
                OR LOWER(COALESCE(p.description, '')) LIKE LOWER(CONCAT('%', CAST(:q AS string), '%'))
              )
            ORDER BY p.createdAt DESC
            """)
    List<Product> searchActive(
            @Param("category") ProductCategory category,
            @Param("q") String q
    );

    @Query("""
            SELECT p FROM Product p
            JOIN FETCH p.producer pr
            JOIN FETCH pr.user
            WHERE p.id = :id
            """)
    Optional<Product> findDetailedById(@Param("id") UUID id);
}
