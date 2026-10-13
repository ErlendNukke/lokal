package com.lokal.config;

import org.junit.jupiter.api.Test;
import org.yaml.snakeyaml.Yaml;

import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

/**
 * Asserts prod-profile YAML keeps Neon suspend-friendly settings (no full Spring context / DB).
 */
class ProdNeonIdleConfigTest {

    @Test
    @SuppressWarnings("unchecked")
    void prodProfileDisablesDbHealthCheckAndUsesIdleFriendlyHikari() throws Exception {
        Map<String, Object> prod = loadProdDocument();
        assertNotNull(prod, "prod profile document missing in application.yml");

        Map<String, Object> management = (Map<String, Object>) prod.get("management");
        assertNotNull(management);
        Map<String, Object> health = (Map<String, Object>) management.get("health");
        Map<String, Object> db = (Map<String, Object>) health.get("db");
        assertEquals(false, db.get("enabled"));

        Map<String, Object> spring = (Map<String, Object>) prod.get("spring");
        Map<String, Object> datasource = (Map<String, Object>) spring.get("datasource");
        Map<String, Object> hikari = (Map<String, Object>) datasource.get("hikari");
        assertEquals(5, hikari.get("maximum-pool-size"));
        assertEquals(0, hikari.get("minimum-idle"));
        assertEquals(60_000, hikari.get("idle-timeout"));
        assertEquals(0, hikari.get("keepalive-time"));
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> loadProdDocument() throws Exception {
        try (var reader = new InputStreamReader(
                ProdNeonIdleConfigTest.class.getClassLoader().getResourceAsStream("application.yml"),
                StandardCharsets.UTF_8)) {
            Yaml yaml = new Yaml();
            for (Object doc : yaml.loadAll(reader)) {
                Map<String, Object> root = (Map<String, Object>) doc;
                Map<String, Object> spring = (Map<String, Object>) root.get("spring");
                if (spring == null) {
                    continue;
                }
                Map<String, Object> config = (Map<String, Object>) spring.get("config");
                if (config == null) {
                    continue;
                }
                Map<String, Object> activate = (Map<String, Object>) config.get("activate");
                if (activate != null && "prod".equals(activate.get("on-profile"))) {
                    return root;
                }
            }
        }
        return null;
    }
}
