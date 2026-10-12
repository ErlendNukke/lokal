package com.lokal.web;

import com.lokal.domain.UserRole;
import com.lokal.support.ApiIntegrationSupport;
import com.lokal.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class AuthGoogleApiIntegrationTest extends IntegrationTestBase {

    @Autowired
    MockMvc mvc;

    private static Map<String, Object> googleBody(String email, String name) {
        return Map.of(
                "idToken", "unverified-demo-token",
                "email", email,
                "name", name,
                "role", UserRole.BUYER.name()
        );
    }

    @Test
    void googleLogin_rejectsTakeoverOfPasswordUser() throws Exception {
        String email = ApiIntegrationSupport.uniqueEmail("password-user");
        ApiIntegrationSupport.register(
                mvc, JSON, "Password User", email, "secret12", UserRole.BUYER, null, null);

        mvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(googleBody(email, "Attacker"))))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value(not("")));
    }

    @Test
    void googleLogin_rejectsTakeoverOfExistingGoogleUser() throws Exception {
        String email = "google.user." + System.currentTimeMillis() + "@gmail.com";

        mvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(googleBody(email, "Google Kasutaja"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());

        mvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(googleBody(email, "Attacker"))))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value(not("")));
    }

    @Test
    void googleLogin_createsNewDemoUser() throws Exception {
        String email = "google.user." + System.currentTimeMillis() + "@gmail.com";

        mvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(googleBody(email, "Google Kasutaja"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.user.email").value(email.toLowerCase()))
                .andExpect(jsonPath("$.user.role").value("BUYER"));
    }
}
