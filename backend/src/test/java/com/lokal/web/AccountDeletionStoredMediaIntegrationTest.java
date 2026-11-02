package com.lokal.web;

import com.lokal.domain.UserRole;
import com.lokal.service.StorageService;
import com.lokal.support.ApiIntegrationSupport;
import com.lokal.support.ApiIntegrationSupport.AuthTokens;
import com.lokal.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.JsonNode;
import com.lokal.domain.ProductCategory;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class AccountDeletionStoredMediaIntegrationTest extends IntegrationTestBase {

    private static final String PASSWORD = "secret12";

    @Autowired
    MockMvc mvc;

    @Value("${lokal.storage.local-path}")
    String localUploadPath;

    @Test
    void deleteAccount_removesUploadedFilesFromLocalStorage() throws Exception {
        AuthTokens producer = ApiIntegrationSupport.register(
                mvc, JSON, "Producer", ApiIntegrationSupport.uniqueEmail("media"), PASSWORD, UserRole.PRODUCER, null, null);
        String photoUrl = uploadPhoto(producer.token());
        String filename = photoUrl.substring(photoUrl.lastIndexOf('/') + 1);
        Path file = Path.of(localUploadPath).resolve(filename).normalize();
        assertTrue(Files.exists(file), "upload should create file on disk");

        createProduct(producer.token(), List.of(photoUrl));

        mvc.perform(delete("/api/auth/me")
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(producer.token())))
                .andExpect(status().isNoContent());

        assertFalse(Files.exists(file), "account deletion should remove stored photo file");
    }

    private String uploadPhoto(String token) throws Exception {
        BufferedImage image = new BufferedImage(32, 32, BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics();
        g.setColor(Color.GREEN);
        g.fillRect(0, 0, 32, 32);
        g.dispose();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "png", out);

        JsonNode body = JSON.readTree(mvc.perform(multipart("/api/uploads")
                        .file(new MockMultipartFile("file", "photo.png", "image/png", out.toByteArray()))
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(token)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        return body.get("url").asText();
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
