package com.lokal.repository;

import com.lokal.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmailIgnoreCase(String email);
    boolean existsByEmailIgnoreCase(String email);

    @org.springframework.data.jpa.repository.Query(
            "SELECT COUNT(u) FROM User u WHERE u.avatarUrl = :url AND u.id <> :userId")
    long countAvatarUrlUsedByOtherUsers(
            @org.springframework.data.repository.query.Param("url") String url,
            @org.springframework.data.repository.query.Param("userId") java.util.UUID userId);
}
