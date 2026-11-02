package com.lokal.web;

import com.lokal.domain.ProductCategory;
import com.lokal.domain.UserRole;
import com.lokal.service.StorageService;
import com.lokal.support.ApiIntegrationSupport;
import com.lokal.support.ApiIntegrationSupport.AuthTokens;
import com.lokal.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class AccountDeletionStorageFailureIntegrationTest extends IntegrationTestBase {

    private static final String PASSWORD = "secret12";
    private static final String MANAGED_PHOTO = "http://localhost:8080/uploads/will-delete.jpg";

    @Autowired
    MockMvc mvc;

    @MockitoBean
    StorageService storageService;

    @Test
    void deleteAccount_completesWhenStorageCleanupFails() throws Exception {
        doThrow(new RuntimeException("R2 unavailable")).when(storageService).deleteManagedUrls(any());

        String email = ApiIntegrationSupport.uniqueEmail("storage-fail");
        AuthTokens producer = ApiIntegrationSupport.register(
                mvc, JSON, "Producer", email, PASSWORD, UserRole.PRODUCER, null, null);
        createProduct(producer.token(), List.of(MANAGED_PHOTO));

        mvc.perform(delete("/api/auth/me")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producer.token())))
                .andExpect(status().isNoContent());

        verify(storageService).deleteManagedUrls(any());
        ApiIntegrationSupport.register(mvc, JSON, "Again", email, PASSWORD, UserRole.PRODUCER, null, null);
    }

    private void createProduct(String producerToken, List<String> photoUrls) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", "Kartul");
        body.put("description", "Fresh");
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
        mvc.perform(post("/api/producer/products")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(JSON.writeValueAsString(body)))
                .andExpect(status().isOk());
    }
}
