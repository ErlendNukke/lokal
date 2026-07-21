package com.lokal.repository;

import com.lokal.domain.Order;
import com.lokal.domain.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface OrderRepository extends JpaRepository<Order, UUID> {

    @Query("""
            SELECT o FROM Order o
            JOIN FETCH o.product p
            JOIN FETCH o.buyer
            JOIN FETCH o.producer pr
            WHERE o.buyer.id = :buyerId
            ORDER BY o.createdAt DESC
            """)
    List<Order> findByBuyerId(@Param("buyerId") UUID buyerId);

    @Query("""
            SELECT o FROM Order o
            JOIN FETCH o.product p
            JOIN FETCH o.buyer
            JOIN FETCH o.producer pr
            WHERE o.producer.id = :producerId
            ORDER BY o.createdAt DESC
            """)
    List<Order> findByProducerId(@Param("producerId") UUID producerId);

    long countByProducerIdAndStatus(UUID producerId, OrderStatus status);
}
