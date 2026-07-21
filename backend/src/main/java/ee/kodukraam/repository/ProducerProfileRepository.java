package ee.kodukraam.repository;

import ee.kodukraam.domain.ProducerProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface ProducerProfileRepository extends JpaRepository<ProducerProfile, UUID> {
    Optional<ProducerProfile> findByUserId(UUID userId);
}
