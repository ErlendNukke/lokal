package com.lokal.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Set;
import java.util.UUID;

@Service
@ConditionalOnProperty(name = "lokal.storage.type", havingValue = "local", matchIfMissing = true)
public class LocalStorageService implements StorageService {

    private static final Set<String> ALLOWED = Set.of("image/jpeg", "image/png", "image/webp", "image/gif");

    private final Path uploadRoot;
    private final String publicBaseUrl;

    public LocalStorageService(
            @Value("${lokal.storage.local-path}") String localPath,
            @Value("${lokal.storage.public-base-url}") String publicBaseUrl
    ) throws IOException {
        this.uploadRoot = Path.of(localPath).toAbsolutePath().normalize();
        this.publicBaseUrl = trimTrailingSlash(publicBaseUrl);
        Files.createDirectories(this.uploadRoot);
    }

    @Override
    public String store(MultipartFile file) {
        String contentType = validate(file);
        String filename = UUID.randomUUID() + extensionFor(contentType);
        try {
            Files.copy(file.getInputStream(), uploadRoot.resolve(filename), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new IllegalStateException("Failed to store file", e);
        }
        return publicBaseUrl + "/" + filename;
    }

    static String validate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Empty file");
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED.contains(contentType)) {
            throw new IllegalArgumentException("Only JPEG, PNG, WEBP, GIF images are allowed");
        }
        return contentType;
    }

    static String extensionFor(String contentType) {
        return switch (contentType) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            case "image/gif" -> ".gif";
            default -> ".jpg";
        };
    }

    static String trimTrailingSlash(String url) {
        return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
    }
}
