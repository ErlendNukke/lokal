package com.lokal.service;

import java.util.Collection;

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

    /**
     * Deletes objects previously stored by this backend when {@code publicUrls} use this service's
     * public base URL. External URLs are ignored. Failures are logged and do not propagate.
     */
    void deleteManagedUrls(Collection<String> publicUrls);
}
