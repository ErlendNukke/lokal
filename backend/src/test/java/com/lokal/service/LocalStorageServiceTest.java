package com.lokal.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LocalStorageServiceTest {

    @TempDir
    Path tempDir;

    @Test
    void trimTrailingSlash() {
        assertEquals("http://localhost:9000/lokal",
                LocalStorageService.trimTrailingSlash("http://localhost:9000/lokal/"));
    }

    @Test
    void deleteManagedUrls_removesStoredFile_andIgnoresExternalUrls() throws Exception {
        LocalStorageService service = new LocalStorageService(tempDir.toString(), "http://localhost/uploads");
        String url = service.store(new byte[] {1, 2, 3}, "image/jpeg", ".jpg");
        String filename = url.substring(url.lastIndexOf('/') + 1);
        Path file = tempDir.resolve(filename);
        assertTrue(Files.exists(file));

        service.deleteManagedUrls(List.of(url, "https://images.unsplash.com/photo.jpg"));
        assertFalse(Files.exists(file));
    }
}
