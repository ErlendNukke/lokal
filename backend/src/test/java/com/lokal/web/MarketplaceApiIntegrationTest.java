package com.lokal.web;

import com.fasterxml.jackson.databind.JsonNode;
import com.lokal.domain.FulfillmentType;
import com.lokal.domain.ProductCategory;
import com.lokal.domain.UserRole;
import com.lokal.support.ApiIntegrationSupport;
import com.lokal.support.ApiIntegrationSupport.AuthTokens;
import com.lokal.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@AutoConfigureMockMvc
class MarketplaceApiIntegrationTest extends IntegrationTestBase {

    @Autowired
    MockMvc mvc;

    // Tallinn center — matches Flutter AppConfig.radiusKm default of 10 km
    private static final double TALLINN_LAT = 59.4370;
    private static final double TALLINN_LNG = 24.7536;
    // ~25 km north of Tallinn (outside 10 km radius)
    private static final double FAR_NORTH_LAT = 59.6620;
    private static final double FAR_NORTH_LNG = 24.7536;

    @Test
    void registerAndLoginAllRoles_rejectsBadCredentials() throws Exception {
        String buyerEmail = ApiIntegrationSupport.uniqueEmail("buyer");
        String producerEmail = ApiIntegrationSupport.uniqueEmail("producer");
        String bothEmail = ApiIntegrationSupport.uniqueEmail("both");

        AuthTokens buyer = ApiIntegrationSupport.register(
                mvc, JSON, "Buyer Test", buyerEmail, "secret12", UserRole.BUYER, null, null);
        assertNotNull(buyer.token());
        assertFalse(buyer.token().isBlank());

        AuthTokens producer = ApiIntegrationSupport.register(
                mvc, JSON, "Producer Test", producerEmail, "secret12", UserRole.PRODUCER, null, null);
        assertNotNull(producer.token());

        AuthTokens both = ApiIntegrationSupport.register(
                mvc, JSON, "Both Test", bothEmail, "secret12", UserRole.BOTH, null, null);
        assertNotNull(both.token());

        String loginToken = ApiIntegrationSupport.login(mvc, JSON, buyerEmail, "secret12");
        assertFalse(loginToken.isBlank());

        mvc.perform(get("/api/auth/me")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(loginToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(buyerEmail.toLowerCase()))
                .andExpect(jsonPath("$.role").value("BUYER"));

        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(Map.of(
                                "email", buyerEmail,
                                "password", "wrong-password"
                        ))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Invalid email or password"));
    }

    @Test
    void producerManagesOwnProducts_buyerCannotUpdateOthersProduct() throws Exception {
        String producerEmail = ApiIntegrationSupport.uniqueEmail("prod");
        String buyerEmail = ApiIntegrationSupport.uniqueEmail("buy");
        AuthTokens producer = ApiIntegrationSupport.register(
                mvc, JSON, "Farm Owner", producerEmail, "secret12", UserRole.PRODUCER, TALLINN_LAT, TALLINN_LNG);
        AuthTokens buyer = ApiIntegrationSupport.register(
                mvc, JSON, "Shopper", buyerEmail, "secret12", UserRole.BUYER, TALLINN_LAT, TALLINN_LNG);

        String productName = "UniqueBerry-" + UUID.randomUUID();
        String productId = ApiIntegrationSupport.createProduct(
                mvc, JSON, producer.token(), productName, ProductCategory.FOOD,
                TALLINN_LAT, TALLINN_LNG, true, true);

        mvc.perform(get("/api/producer/products")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producer.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].name", hasItem(productName)));

        String updatedName = productName + "-updated";
        Map<String, Object> updateBody = Map.of(
                "name", updatedName,
                "description", "Updated",
                "category", ProductCategory.FOOD.name(),
                "price", "5.00",
                "unit", "kg",
                "quantity", "8",
                "latitude", TALLINN_LAT,
                "longitude", TALLINN_LNG,
                "pickupAvailable", true,
                "deliveryAvailable", false
        );
        mvc.perform(put("/api/producer/products/" + productId)
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producer.token()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(updateBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value(updatedName));

        mvc.perform(put("/api/producer/products/" + productId)
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(buyer.token()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(updateBody)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Producer role required"));
    }

    @Test
    void browseProducts_respectsRadiusCategoryAndSearchQuery() throws Exception {
        String producerEmail = ApiIntegrationSupport.uniqueEmail("geo");
        AuthTokens producer = ApiIntegrationSupport.register(
                mvc, JSON, "Geo Producer", producerEmail, "secret12", UserRole.PRODUCER, TALLINN_LAT, TALLINN_LNG);

        String nearName = "NearMint-" + UUID.randomUUID();
        String farName = "FarMint-" + UUID.randomUUID();
        String plantName = "NearPlant-" + UUID.randomUUID();

        ApiIntegrationSupport.createProduct(
                mvc, JSON, producer.token(), nearName, ProductCategory.FOOD, TALLINN_LAT, TALLINN_LNG, true, false);
        ApiIntegrationSupport.createProduct(
                mvc, JSON, producer.token(), farName, ProductCategory.FOOD, FAR_NORTH_LAT, FAR_NORTH_LNG, true, false);
        ApiIntegrationSupport.createProduct(
                mvc, JSON, producer.token(), plantName, ProductCategory.PLANTS, TALLINN_LAT, TALLINN_LNG, true, false);

        mvc.perform(get("/api/products")
                        .param("lat", String.valueOf(TALLINN_LAT))
                        .param("lng", String.valueOf(TALLINN_LNG))
                        .param("radiusKm", "10")
                        .param("q", nearName))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].name", hasItem(nearName)))
                .andExpect(jsonPath("$[*].name", not(hasItem(farName))));

        mvc.perform(get("/api/products")
                        .param("lat", String.valueOf(TALLINN_LAT))
                        .param("lng", String.valueOf(TALLINN_LNG))
                        .param("radiusKm", "10")
                        .param("category", ProductCategory.PLANTS.name())
                        .param("q", plantName))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].name", hasItem(plantName)))
                .andExpect(jsonPath("$[*].category", everyItem(is(ProductCategory.PLANTS.name()))));
    }

    @Test
    void orderLifecycle_pickupAndDelivery_invalidTransitionsRejected() throws Exception {
        String producerEmail = ApiIntegrationSupport.uniqueEmail("order-prod");
        String buyerEmail = ApiIntegrationSupport.uniqueEmail("order-buy");
        AuthTokens producer = ApiIntegrationSupport.register(
                mvc, JSON, "Order Producer", producerEmail, "secret12", UserRole.PRODUCER, TALLINN_LAT, TALLINN_LNG);
        AuthTokens buyer = ApiIntegrationSupport.register(
                mvc, JSON, "Order Buyer", buyerEmail, "secret12", UserRole.BUYER, TALLINN_LAT, TALLINN_LNG);

        String pickupProduct = ApiIntegrationSupport.createProduct(
                mvc, JSON, producer.token(), "PickupOnly-" + UUID.randomUUID(), ProductCategory.FOOD,
                TALLINN_LAT, TALLINN_LNG, true, false);
        String deliveryProduct = ApiIntegrationSupport.createProduct(
                mvc, JSON, producer.token(), "DeliveryOnly-" + UUID.randomUUID(), ProductCategory.FOOD,
                TALLINN_LAT, TALLINN_LNG, false, true);

        String pickupOrderId = ApiIntegrationSupport.placeOrder(
                mvc, JSON, buyer.token(), pickupProduct, FulfillmentType.PICKUP, "Pick up Saturday");
        String deliveryOrderId = ApiIntegrationSupport.placeOrder(
                mvc, JSON, buyer.token(), deliveryProduct, FulfillmentType.DELIVERY, "Leave at door");

        mvc.perform(get("/api/orders/mine")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(buyer.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].id", hasItems(pickupOrderId, deliveryOrderId)));

        mvc.perform(patch("/api/orders/" + pickupOrderId + "/status")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producer.token()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"COMPLETED\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Invalid status transition"));

        ApiIntegrationSupport.patchOrderStatus(mvc, JSON, producer.token(), pickupOrderId, "ACCEPTED");
        ApiIntegrationSupport.patchOrderStatus(mvc, JSON, producer.token(), pickupOrderId, "COMPLETED");

        mvc.perform(patch("/api/orders/" + deliveryOrderId + "/status")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producer.token()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"REJECTED\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"));

        mvc.perform(get("/api/producer/orders")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producer.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id=='" + pickupOrderId + "')].status", hasItem("COMPLETED")))
                .andExpect(jsonPath("$[?(@.id=='" + deliveryOrderId + "')].status", hasItem("REJECTED")));
    }

    @Test
    void producerRoleCannotPlaceOrder_bothRoleCan() throws Exception {
        String producerOnlyEmail = ApiIntegrationSupport.uniqueEmail("prod-only");
        String bothEmail = ApiIntegrationSupport.uniqueEmail("both-buy");
        AuthTokens producerOnly = ApiIntegrationSupport.register(
                mvc, JSON, "Solo Producer", producerOnlyEmail, "secret12", UserRole.PRODUCER, TALLINN_LAT, TALLINN_LNG);
        AuthTokens both = ApiIntegrationSupport.register(
                mvc, JSON, "Dual Role", bothEmail, "secret12", UserRole.BOTH, TALLINN_LAT, TALLINN_LNG);

        String productId = ApiIntegrationSupport.createProduct(
                mvc, JSON, producerOnly.token(), "Stock-" + UUID.randomUUID(), ProductCategory.FOOD,
                TALLINN_LAT, TALLINN_LNG, true, true);

        mvc.perform(post("/api/orders")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producerOnly.token()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(Map.of(
                                "productId", productId,
                                "quantity", "1",
                                "fulfillment", FulfillmentType.PICKUP.name(),
                                "message", ""
                        ))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Switch to buyer role to place orders"));

        String orderId = ApiIntegrationSupport.placeOrder(
                mvc, JSON, both.token(), productId, FulfillmentType.PICKUP, "");
        assertNotNull(orderId);
    }

    @Test
    void reviewOnlyAfterCompletion_enforced() throws Exception {
        String producerEmail = ApiIntegrationSupport.uniqueEmail("rev-prod");
        String buyerEmail = ApiIntegrationSupport.uniqueEmail("rev-buy");
        AuthTokens producer = ApiIntegrationSupport.register(
                mvc, JSON, "Review Producer", producerEmail, "secret12", UserRole.PRODUCER, TALLINN_LAT, TALLINN_LNG);
        AuthTokens buyer = ApiIntegrationSupport.register(
                mvc, JSON, "Review Buyer", buyerEmail, "secret12", UserRole.BUYER, TALLINN_LAT, TALLINN_LNG);

        String productId = ApiIntegrationSupport.createProduct(
                mvc, JSON, producer.token(), "Reviewable-" + UUID.randomUUID(), ProductCategory.FOOD,
                TALLINN_LAT, TALLINN_LNG, true, false);
        String orderId = ApiIntegrationSupport.placeOrder(
                mvc, JSON, buyer.token(), productId, FulfillmentType.PICKUP, "");

        mvc.perform(post("/api/reviews")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(buyer.token()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(Map.of(
                                "orderId", orderId,
                                "rating", 5,
                                "comment", "Too early"
                        ))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Order must be completed before reviewing"));

        ApiIntegrationSupport.patchOrderStatus(mvc, JSON, producer.token(), orderId, "ACCEPTED");
        ApiIntegrationSupport.patchOrderStatus(mvc, JSON, producer.token(), orderId, "COMPLETED");

        mvc.perform(get("/api/orders/mine")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(buyer.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id=='" + orderId + "')].canReview", hasItem(true)));

        MvcResult reviewResult = mvc.perform(post("/api/reviews")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(buyer.token()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(Map.of(
                                "orderId", orderId,
                                "rating", 5,
                                "comment", "Great produce"
                        ))))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode review = JSON.readTree(reviewResult.getResponse().getContentAsString());
        String producerId = review.get("producerId").asText();

        mvc.perform(get("/api/producers/" + producerId + "/reviews"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].rating").value(5))
                .andExpect(jsonPath("$[0].comment").value("Great produce"));

        mvc.perform(post("/api/reviews")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(buyer.token()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(Map.of(
                                "orderId", orderId,
                                "rating", 4,
                                "comment", "Duplicate"
                        ))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Order already reviewed"));
    }
}
