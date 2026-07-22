package com.lokal.service;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class LocalStorageServiceTest {

    @Test
    void trimTrailingSlash() {
        assertEquals("http://localhost:9000/lokal",
                LocalStorageService.trimTrailingSlash("http://localhost:9000/lokal/"));
    }
}
