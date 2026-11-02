package com.lokal.service;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class StorageUrlSupportTest {

    @Test
    void relativeKey_extractsPathUnderBase() {
        assertEquals("products/abc.jpg",
                StorageUrlSupport.relativeKey(
                        "https://cdn.example.com/products/abc.jpg",
                        "https://cdn.example.com").orElseThrow());
    }

    @Test
    void relativeKey_ignoresExternalUrls() {
        assertTrue(StorageUrlSupport.relativeKey("https://images.unsplash.com/x.jpg", "https://cdn.example.com").isEmpty());
        assertTrue(StorageUrlSupport.relativeKey("", "https://cdn.example.com").isEmpty());
        assertTrue(StorageUrlSupport.relativeKey("https://cdn.example.com/../secret", "https://cdn.example.com").isEmpty());
    }
}
