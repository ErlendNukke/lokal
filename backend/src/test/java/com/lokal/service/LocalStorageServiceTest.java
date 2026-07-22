package com.lokal.service;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class LocalStorageServiceTest {

    @Test
    void validateAcceptsJpeg() {
        var file = new MockMultipartFile("file", "a.jpg", "image/jpeg", new byte[]{1, 2, 3});
        assertEquals("image/jpeg", LocalStorageService.validate(file));
        assertEquals(".jpg", LocalStorageService.extensionFor("image/jpeg"));
    }

    @Test
    void validateRejectsEmptyAndNonImage() {
        assertThrows(IllegalArgumentException.class,
                () -> LocalStorageService.validate(new MockMultipartFile("file", new byte[0])));
        assertThrows(IllegalArgumentException.class,
                () -> LocalStorageService.validate(
                        new MockMultipartFile("file", "a.txt", "text/plain", new byte[]{1})));
    }

    @Test
    void trimTrailingSlash() {
        assertEquals("http://localhost:9000/lokal",
                LocalStorageService.trimTrailingSlash("http://localhost:9000/lokal/"));
    }
}
