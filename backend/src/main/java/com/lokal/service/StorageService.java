package com.lokal.service;

import org.springframework.web.multipart.MultipartFile;

/**
 * Stores product images and returns a publicly reachable URL.
 * Implementations: local filesystem (dev) or S3-compatible (MinIO / R2 / AWS).
 */
public interface StorageService {

    String store(MultipartFile file);
}
