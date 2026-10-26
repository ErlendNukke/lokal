package com.lokal.web;

import com.fasterxml.jackson.databind.JsonNode;
import com.lokal.domain.FulfillmentType;
import com.lokal.domain.ProductCategory;
import com.lokal.domain.User;
import com.lokal.domain.UserRole;
import com.lokal.repository.UserRepository;
import com.lokal.support.ApiIntegrationSupport;
import com.lokal.support.ApiIntegrationSupport.AuthTokens;
import com.lokal.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class AccountDeletionApiIntegrationTest extends IntegrationTestBase {

    private static final String PASSWORD = "secret12";

    @Autowired
    MockMvc mvc;

    @Autowired
    UserRepository userRepository;

    @Test
    void deleteAccount_requiresAuthentication() throws Exception {
        mvc.perform(delete("/api/auth/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Not authenticated"));
    }

    @Test
    void deleteAccount_withoutHistory_hardDeletes_rejectsOldToken_andFreesEmail() throws Exception {
        String email = ApiIntegrationSupport.uniqueEmail("delete-me");
        AuthTokens tokens = register("Delete Me", email, UserRole.BUYER);

        deleteMe(tokens.token()).andExpect(status().isNoContent());

        assertTrue(userRepository.findById(UUID.fromString(tokens.userId())).isEmpty());
        assertOldTokenRejected(tokens.token());
        assertLoginFails(email);

        AuthTokens again = register("New Me", email, UserRole.BUYER);
        assertFalse(again.userId().equals(tokens.userId()));
        ApiIntegrationSupport.login(mvc, JSON, email, PASSWORD);
    }

    @Test
    void deleteAccount_withOrderHistory_anonymizesBuyer() throws Exception {
        AuthTokens producer = register("Seller", ApiIntegrationSupport.uniqueEmail("seller"), UserRole.PRODUCER);
        String productId = createProduct(producer.token(), List.of("https://example.test/p.jpg"));
        String buyerEmail = ApiIntegrationSupport.uniqueEmail("buyer");
        AuthTokens buyer = register("Buyer Person", buyerEmail, UserRole.BUYER);
        String orderId = ApiIntegrationSupport.placeOrder(
                mvc, JSON, buyer.token(), productId, FulfillmentType.PICKUP, "Call me on 5551234");
        ApiIntegrationSupport.patchOrderStatus(mvc, JSON, producer.token(), orderId, "ACCEPTED");
        ApiIntegrationSupport.patchOrderStatus(mvc, JSON, producer.token(), orderId, "COMPLETED");

        deleteMe(buyer.token()).andExpect(status().isNoContent());

        User row = userRepository.findById(UUID.fromString(buyer.userId())).orElseThrow();
        assertEquals("Kustutatud konto", row.getName());
        assertEquals("deleted+" + buyer.userId() + "@deleted.lokal", row.getEmail());
        assertNull(row.getPasswordHash());
        assertNull(row.getLatitude());
        assertNull(row.getLongitude());
        assertNull(row.getCity());
        assertNull(row.getAvatarUrl());
        assertNotNull(row.getDeletedAt());

        assertOldTokenRejected(buyer.token());
        assertLoginFails(buyerEmail);
        assertLoginFails(row.getEmail());

        JsonNode sellerOrders = json(mvc.perform(get("/api/producer/orders")
                .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producer.token())))
                .andExpect(status().isOk()));
        assertEquals("Kustutatud konto", sellerOrders.get(0).get("buyerName").asText());
        assertTrue(sellerOrders.get(0).get("message").isNull());

        register("Buyer Again", buyerEmail, UserRole.BUYER);
        ApiIntegrationSupport.login(mvc, JSON, buyerEmail, PASSWORD);
    }

    @Test
    void deleteAccount_producerWithOrderHistory_scrubsListingsAndProfile() throws Exception {
        AuthTokens producer = register("Farmer Person", ApiIntegrationSupport.uniqueEmail("farmer"), UserRole.PRODUCER);
        String soldId = createProduct(producer.token(), List.of("https://example.test/sold.jpg"));
        String unsoldId = createProduct(producer.token(), List.of("https://example.test/unsold.jpg"));
        AuthTokens buyer = register("Buyer", ApiIntegrationSupport.uniqueEmail("b"), UserRole.BUYER);
        String orderId = ApiIntegrationSupport.placeOrder(
                mvc, JSON, buyer.token(), soldId, FulfillmentType.PICKUP, null);
        ApiIntegrationSupport.patchOrderStatus(mvc, JSON, producer.token(), orderId, "REJECTED");

        deleteMe(producer.token()).andExpect(status().isNoContent());

        JsonNode sold = json(mvc.perform(get("/api/products/" + soldId)).andExpect(status().isOk()));
        assertFalse(sold.get("active") != null && sold.get("active").asBoolean());
        assertTrue(sold.get("description").isNull());
        assertTrue(sold.get("locationLabel").isNull());
        assertEquals(0.0, sold.get("latitude").asDouble());
        assertEquals(0, sold.get("photos").size());
        assertEquals("Kustutatud tootja", sold.get("producer").get("farmName").asText());
        assertEquals("Kustutatud konto", sold.get("producer").get("ownerName").asText());

        mvc.perform(get("/api/products/" + unsoldId)).andExpect(status().isBadRequest());
        assertOldTokenRejected(producer.token());
    }

    @Test
    void deleteAccount_blockedByOpenBuyerOrder() throws Exception {
        AuthTokens producer = register("Seller", ApiIntegrationSupport.uniqueEmail("s"), UserRole.PRODUCER);
        String productId = createProduct(producer.token(), List.of());
        String buyerEmail = ApiIntegrationSupport.uniqueEmail("pending");
        AuthTokens buyer = register("Pending Buyer", buyerEmail, UserRole.BUYER);
        String orderId = ApiIntegrationSupport.placeOrder(
                mvc, JSON, buyer.token(), productId, FulfillmentType.PICKUP, null);

        deleteMe(buyer.token())
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("PENDING_ORDERS"));
        deleteMe(producer.token())
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("PENDING_SELLER_ORDERS"));

        ApiIntegrationSupport.patchOrderStatus(mvc, JSON, producer.token(), orderId, "ACCEPTED");
        deleteMe(buyer.token())
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("PENDING_ORDERS"));

        ApiIntegrationSupport.login(mvc, JSON, buyerEmail, PASSWORD);
        mvc.perform(get("/api/auth/me")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(buyer.token())))
                .andExpect(status().isOk());
    }

    @Test
    void deleteAccount_demoAccountsAreProtected() throws Exception {
        for (String email : List.of("anna@lokal.app", "mari@lokal.app", "juri@lokal.app")) {
            String token = ApiIntegrationSupport.login(mvc, JSON, email, "password123");
            deleteMe(token)
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("DEMO_ACCOUNT"));
            ApiIntegrationSupport.login(mvc, JSON, email, "password123");
        }
    }

    @Test
    void register_rejectsReservedDeletedDomain() throws Exception {
        Map<String, Object> body = Map.of(
                "name", "Sneaky", "email", "deleted+" + UUID.randomUUID() + "@deleted.lokal",
                "password", PASSWORD, "role", "BUYER");
        mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(body)))
                .andExpect(status().isBadRequest());
    }

    private AuthTokens register(String name, String email, UserRole role) throws Exception {
        return ApiIntegrationSupport.register(mvc, JSON, name, email, PASSWORD, role, null, null);
    }

    private ResultActions deleteMe(String token) throws Exception {
        return mvc.perform(delete("/api/auth/me")
                .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(token)));
    }

    private void assertOldTokenRejected(String token) throws Exception {
        String bearer = ApiIntegrationSupport.bearer(token);
        mvc.perform(get("/api/auth/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/orders/mine").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isUnauthorized());
        // Even public endpoints must not accept the stale token.
        mvc.perform(get("/api/products").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isUnauthorized());
        mvc.perform(delete("/api/auth/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isUnauthorized());
    }

    private void assertLoginFails(String email) throws Exception {
        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(Map.of("email", email, "password", PASSWORD))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Invalid email or password"));
    }

    private String createProduct(String producerToken, List<String> photoUrls) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", "Kartul");
        body.put("description", "Farm at Tamme tee 5, call 5551234");
        body.put("category", ProductCategory.values()[0].name());
        body.put("price", "2.00");
        body.put("unit", "kg");
        body.put("quantity", "10");
        body.put("latitude", 59.4);
        body.put("longitude", 24.7);
        body.put("locationLabel", "Tamme tee 5");
        body.put("pickupAvailable", true);
        body.put("deliveryAvailable", false);
        body.put("photoUrls", photoUrls);
        return json(mvc.perform(post("/api/producer/products")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(body)))
                .andExpect(status().isOk())).get("id").asText();
    }

    private JsonNode json(ResultActions result) throws Exception {
        return JSON.readTree(result.andReturn().getResponse().getContentAsString());
    }
}
