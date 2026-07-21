package com.lokal.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Set;
import java.util.UUID;

/**
 * Local filesystem storage for MVP. Swap for S3/MinIO by implementing the same contract.
 */
@Service
public class StorageService {

    private static final Set<String> ALLOWED = Set.of("image/jpeg", "image/png", "image/webp", "image/gif");

    private final Path uploadRoot;
    private final String publicBaseUrl;

    public StorageService(
            @Value("${lokal.storage.local-path}") String localPath,
            @Value("${lokal.storage.public-base-url}") String publicBaseUrl
    ) throws IOException {
        this.uploadRoot = Path.of(localPath).toAbsolutePath().normalize();
        this.publicBaseUrl = publicBaseUrl.endsWith("/") ? publicBaseUrl.substring(0, publicBaseUrl.length() - 1) : publicBaseUrl;
        Files.createDirectories(this.uploadRoot);
    }

    public String store(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Empty file");
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED.contains(contentType)) {
            throw new IllegalArgumentException("Only JPEG, PNG, WEBP, GIF images are allowed");
        }
        String ext = switch (contentType) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            case "image/gif" -> ".gif";
            default -> ".jpg";
        };
        String filename = UUID.randomUUID() + ext;
        try {
            Files.copy(file.getInputStream(), uploadRoot.resolve(filename), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new IllegalStateException("Failed to store file", e);
        }
        return publicBaseUrl + "/" + filename;
    }
}
