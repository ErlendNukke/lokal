package ee.kodukraam.web;

import ee.kodukraam.domain.User;
import ee.kodukraam.security.SecurityUtils;
import ee.kodukraam.service.AuthService;
import ee.kodukraam.web.dto.ApiDtos.*;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/google")
    public AuthResponse google(@Valid @RequestBody GoogleLoginRequest request) {
        return authService.googleLogin(request);
    }

    @GetMapping("/me")
    public UserDto me() {
        return authService.me(SecurityUtils.currentUser());
    }

    @PutMapping("/me")
    public UserDto updateMe(@Valid @RequestBody UpdateProfileRequest request) {
        return authService.updateProfile(SecurityUtils.currentUser(), request);
    }
}
