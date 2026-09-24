package com.lokal.web;

import com.lokal.domain.UserRole;
import com.lokal.service.StorageService;
import com.lokal.support.ApiIntegrationSupport;
import com.lokal.support.ApiIntegrationSupport.AuthTokens;
import com.lokal.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class UploadApiStorageFailureIntegrationTest extends IntegrationTestBase {

    @Autowired
    MockMvc mvc;

    @MockitoBean
    StorageService storageService;

    @Test
    void storageFailureReturns500() throws Exception {
        when(storageService.store(any(), anyString(), anyString()))
                .thenThrow(new IllegalStateException("Failed to store file"));

        AuthTokens user = ApiIntegrationSupport.register(
                mvc,
                JSON,
                "Uploader",
                ApiIntegrationSupport.uniqueEmail("upload-fail"),
                "secret12",
                UserRole.BUYER,
                null,
                null);

        BufferedImage image = new BufferedImage(32, 32, BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics();
        g.setColor(Color.RED);
        g.fillRect(0, 0, 32, 32);
        g.dispose();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "png", out);

        mvc.perform(multipart("/api/uploads")
                        .file(new MockMultipartFile("file", "photo.png", "image/png", out.toByteArray()))
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(user.token())))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value("Failed to store file"));
    }
}
