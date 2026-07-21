package ee.kodukraam.service;

import ee.kodukraam.domain.*;
import ee.kodukraam.repository.ProducerProfileRepository;
import ee.kodukraam.repository.UserRepository;
import ee.kodukraam.security.JwtService;
import ee.kodukraam.web.dto.ApiDtos.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final ProducerProfileRepository producerProfileRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(
            UserRepository userRepository,
            ProducerProfileRepository producerProfileRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService
    ) {
        this.userRepository = userRepository;
        this.producerProfileRepository = producerProfileRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmailIgnoreCase(request.email())) {
            throw new IllegalArgumentException("Email already registered");
        }
        User user = User.builder()
                .name(request.name().trim())
                .email(request.email().trim().toLowerCase())
                .passwordHash(passwordEncoder.encode(request.password()))
                .role(request.role())
                .latitude(request.latitude() != null ? request.latitude() : 59.4370)
                .longitude(request.longitude() != null ? request.longitude() : 24.7536)
                .city(request.city() != null ? request.city() : "Tallinn")
                .authProvider(AuthProvider.LOCAL)
                .build();
        userRepository.save(user);

        if (request.role() == UserRole.PRODUCER || request.role() == UserRole.BOTH) {
            ensureProducerProfile(user);
        }

        return new AuthResponse(jwtService.generateToken(user), toUserDto(user));
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmailIgnoreCase(request.email().trim())
                .orElseThrow(() -> new IllegalArgumentException("Invalid email or password"));
        if (user.getPasswordHash() == null || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid email or password");
        }
        return new AuthResponse(jwtService.generateToken(user), toUserDto(user));
    }

    /**
     * MVP Google login: accepts a verified client-side identity payload.
     * Production should verify the Google ID token against Google's tokeninfo/certs endpoint.
     */
    @Transactional
    public AuthResponse googleLogin(GoogleLoginRequest request) {
        if (request.idToken() == null || request.idToken().isBlank()) {
            throw new IllegalArgumentException("Missing Google token");
        }
        User user = userRepository.findByEmailIgnoreCase(request.email().trim())
                .orElseGet(() -> {
                    UserRole role = request.role() != null ? request.role() : UserRole.BUYER;
                    User created = User.builder()
                            .name(request.name().trim())
                            .email(request.email().trim().toLowerCase())
                            .role(role)
                            .latitude(59.4370)
                            .longitude(24.7536)
                            .city("Tallinn")
                            .authProvider(AuthProvider.GOOGLE)
                            .build();
                    userRepository.save(created);
                    if (role == UserRole.PRODUCER || role == UserRole.BOTH) {
                        ensureProducerProfile(created);
                    }
                    return created;
                });
        return new AuthResponse(jwtService.generateToken(user), toUserDto(user));
    }

    @Transactional(readOnly = true)
    public UserDto me(User user) {
        return toUserDto(user);
    }

    @Transactional
    public UserDto updateProfile(User current, UpdateProfileRequest request) {
        User user = userRepository.findById(current.getId()).orElseThrow();
        user.setName(request.name().trim());
        if (request.role() != null) {
            user.setRole(request.role());
        }
        if (request.latitude() != null) {
            user.setLatitude(request.latitude());
        }
        if (request.longitude() != null) {
            user.setLongitude(request.longitude());
        }
        if (request.city() != null) {
            user.setCity(request.city());
        }
        userRepository.save(user);

        if (user.getRole() == UserRole.PRODUCER || user.getRole() == UserRole.BOTH) {
            ProducerProfile profile = ensureProducerProfile(user);
            if (request.farmName() != null && !request.farmName().isBlank()) {
                profile.setFarmName(request.farmName().trim());
            }
            if (request.farmDescription() != null) {
                profile.setDescription(request.farmDescription());
            }
            if (request.pickupAvailable() != null) {
                profile.setPickupAvailable(request.pickupAvailable());
            }
            if (request.deliveryAvailable() != null) {
                profile.setDeliveryAvailable(request.deliveryAvailable());
            }
            if (request.deliveryRadiusKm() != null) {
                profile.setDeliveryRadiusKm(request.deliveryRadiusKm());
            }
            producerProfileRepository.save(profile);
        }

        return toUserDto(user);
    }

    private ProducerProfile ensureProducerProfile(User user) {
        return producerProfileRepository.findByUserId(user.getId())
                .orElseGet(() -> producerProfileRepository.save(ProducerProfile.builder()
                        .user(user)
                        .farmName(user.getName() + " talu")
                        .description("Kohalik tootja")
                        .build()));
    }

    public UserDto toUserDto(User user) {
        UUID producerId = null;
        String farmName = null;
        var profile = producerProfileRepository.findByUserId(user.getId());
        if (profile.isPresent()) {
            producerId = profile.get().getId();
            farmName = profile.get().getFarmName();
        }
        return new UserDto(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole(),
                user.getLatitude(),
                user.getLongitude(),
                user.getCity(),
                user.getAvatarUrl(),
                producerId,
                farmName
        );
    }
}
