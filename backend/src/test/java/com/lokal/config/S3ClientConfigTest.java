package com.lokal.config;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class S3ClientConfigTest {

    @Test
    void pathStyleDefaultsTrueWhenEndpointSet() {
        assertTrue(S3ClientConfig.resolvePathStyle("http://localhost:9000", ""));
        assertTrue(S3ClientConfig.resolvePathStyle("http://localhost:9000", null));
    }

    @Test
    void pathStyleDefaultsFalseForAwsStyle() {
        assertFalse(S3ClientConfig.resolvePathStyle("", ""));
        assertFalse(S3ClientConfig.resolvePathStyle(null, null));
    }

    @Test
    void pathStyleExplicitOverrideWins() {
        assertFalse(S3ClientConfig.resolvePathStyle("http://localhost:9000", "false"));
        assertTrue(S3ClientConfig.resolvePathStyle("", "true"));
    }
}
