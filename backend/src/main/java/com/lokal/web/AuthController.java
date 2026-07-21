package com.lokal.web;

import com.lokal.domain.User;
import com.lokal.security.SecurityUtils;
import com.lokal.service.AuthService;
import com.lokal.web.dto.ApiDtos.*;
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
