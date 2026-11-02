package com.lokal.service;

import java.util.Optional;

/** Maps public URLs returned by {@link StorageService#store} back to object keys / filenames. */
final class StorageUrlSupport {

    private StorageUrlSupport() {
    }

    static Optional<String> relativeKey(String publicUrl, String publicBaseUrl) {
        if (publicUrl == null || publicUrl.isBlank()) {
            return Optional.empty();
        }
        String base = LocalStorageService.trimTrailingSlash(publicBaseUrl);
        String prefix = base + "/";
        if (!publicUrl.startsWith(prefix)) {
            return Optional.empty();
        }
        String key = publicUrl.substring(prefix.length());
        if (key.isEmpty() || key.contains("..")) {
            return Optional.empty();
        }
        return Optional.of(key);
    }
}
