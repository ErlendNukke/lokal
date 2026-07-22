package com.lokal.service;

/**
 * Stores product images and returns a publicly reachable URL.
 * Implementations: local filesystem (dev) or S3-compatible (MinIO / R2 / AWS).
 */
public interface StorageService {

    /**
     * @param data        image bytes (already validated / resized by {@link ImageOptimizer})
     * @param contentType MIME type, e.g. {@code image/jpeg}
     * @param extension   including dot, e.g. {@code .jpg}
     */
    String store(byte[] data, String contentType, String extension);
}
