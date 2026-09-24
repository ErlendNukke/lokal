package com.lokal.web;

import com.lokal.domain.UserRole;
import com.lokal.support.ApiIntegrationSupport;
import com.lokal.support.ApiIntegrationSupport.AuthTokens;
import com.lokal.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;

import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class UploadApiIntegrationTest extends IntegrationTestBase {

    @Autowired
    MockMvc mvc;

    @Test
    void uploadWithoutAuthReturns401() throws Exception {
        mvc.perform(multipart("/api/uploads").file(imagePart()))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Not authenticated"));
    }

    @Test
    void uploadHappyPathReturnsPublicUrl() throws Exception {
        AuthTokens user = ApiIntegrationSupport.register(
                mvc,
                JSON,
                "Uploader",
                ApiIntegrationSupport.uniqueEmail("upload"),
                "secret12",
                UserRole.BUYER,
                null,
                null);

        mvc.perform(multipart("/api/uploads")
                        .file(imagePart())
                        .header(HttpHeaders.AUTHORIZATION, ApiIntegrationSupport.bearer(user.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.url", startsWith("http://localhost:8080/uploads/")));
    }

    private static MockMultipartFile imagePart() throws Exception {
        return new MockMultipartFile("file", "photo.png", "image/png", tinyPng());
    }

    private static byte[] tinyPng() throws Exception {
        BufferedImage image = new BufferedImage(32, 32, BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics();
        g.setColor(Color.BLUE);
        g.fillRect(0, 0, 32, 32);
        g.dispose();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "png", out);
        return out.toByteArray();
    }
}
