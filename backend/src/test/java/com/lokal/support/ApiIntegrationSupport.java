package com.lokal.support;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.lokal.domain.FulfillmentType;
import com.lokal.domain.ProductCategory;
import com.lokal.domain.ProductUnit;
import com.lokal.domain.UserRole;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public final class ApiIntegrationSupport {

    private ApiIntegrationSupport() {}

    public static String uniqueEmail(String prefix) {
        return prefix + "+" + UUID.randomUUID() + "@integration.test";
    }

    public static AuthTokens register(
            MockMvc mvc,
            ObjectMapper mapper,
            String name,
            String email,
            String password,
            UserRole role,
            Double lat,
            Double lng
    ) throws Exception {
        Map<String, Object> body = Map.of(
                "name", name,
                "email", email,
                "password", password,
                "role", role.name(),
                "latitude", lat != null ? lat : 59.4370,
                "longitude", lng != null ? lng : 24.7536,
                "city", "Tallinn"
        );
        MvcResult result = mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode json = mapper.readTree(result.getResponse().getContentAsString());
        return new AuthTokens(json.get("token").asText(), json.get("user").get("id").asText());
    }

    public static String login(MockMvc mvc, ObjectMapper mapper, String email, String password) throws Exception {
        Map<String, String> body = Map.of("email", email, "password", password);
        MvcResult result = mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andReturn();
        return mapper.readTree(result.getResponse().getContentAsString()).get("token").asText();
    }

    public static String createProduct(
            MockMvc mvc,
            ObjectMapper mapper,
            String producerToken,
            String name,
            ProductCategory category,
            double lat,
            double lng,
            boolean pickup,
            boolean delivery
    ) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", name);
        body.put("description", "Integration test product");
        body.put("category", category.name());
        body.put("price", "4.50");
        body.put("unit", ProductUnit.kg.name());
        body.put("quantity", "10");
        body.put("latitude", lat);
        body.put("longitude", lng);
        body.put("locationLabel", "Test farm");
        body.put("pickupAvailable", pickup);
        body.put("deliveryAvailable", delivery);
        MvcResult result = mvc.perform(post("/api/producer/products")
                        .header(HttpHeaders.AUTHORIZATION, bearer(producerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andReturn();
        return mapper.readTree(result.getResponse().getContentAsString()).get("id").asText();
    }

    public static String placeOrder(
            MockMvc mvc,
            ObjectMapper mapper,
            String buyerToken,
            String productId,
            FulfillmentType fulfillment,
            String message
    ) throws Exception {
        Map<String, Object> body = Map.of(
                "productId", productId,
                "quantity", "1",
                "fulfillment", fulfillment.name(),
                "message", message != null ? message : ""
        );
        MvcResult result = mvc.perform(post("/api/orders")
                        .header(HttpHeaders.AUTHORIZATION, bearer(buyerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andReturn();
        return mapper.readTree(result.getResponse().getContentAsString()).get("id").asText();
    }

    public static void patchOrderStatus(
            MockMvc mvc,
            ObjectMapper mapper,
            String token,
            String orderId,
            String status
    ) throws Exception {
        mvc.perform(patch("/api/orders/" + orderId + "/status")
                        .header(HttpHeaders.AUTHORIZATION, bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("status", status))))
                .andExpect(status().isOk());
    }

    public static String bearer(String token) {
        return "Bearer " + token;
    }

    public record AuthTokens(String token, String userId) {}
}
