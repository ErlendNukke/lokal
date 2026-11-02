package com.lokal.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collection;
import java.util.UUID;

@Service
@ConditionalOnProperty(name = "lokal.storage.type", havingValue = "local", matchIfMissing = true)
public class LocalStorageService implements StorageService {

    private static final Logger log = LoggerFactory.getLogger(LocalStorageService.class);

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
    public String store(byte[] data, String contentType, String extension) {
        if (data == null || data.length == 0) {
            throw new IllegalArgumentException("Empty file");
        }
        String filename = UUID.randomUUID() + (extension.startsWith(".") ? extension : "." + extension);
        try {
            Files.write(uploadRoot.resolve(filename), data);
        } catch (IOException e) {
            throw new IllegalStateException("Failed to store file", e);
        }
        return publicBaseUrl + "/" + filename;
    }

    @Override
    public void deleteManagedUrls(Collection<String> publicUrls) {
        if (publicUrls == null || publicUrls.isEmpty()) {
            return;
        }
        for (String url : publicUrls) {
            StorageUrlSupport.relativeKey(url, publicBaseUrl).ifPresent(key -> {
                Path file = uploadRoot.resolve(key).normalize();
                if (!file.startsWith(uploadRoot)) {
                    log.warn("Refusing to delete path outside upload root: {}", url);
                    return;
                }
                try {
                    Files.deleteIfExists(file);
                } catch (IOException e) {
                    log.warn("Failed to delete local upload {} (from URL {}): {}", file, url, e.toString());
                }
            });
        }
    }

    static String trimTrailingSlash(String url) {
        return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
    }
}
