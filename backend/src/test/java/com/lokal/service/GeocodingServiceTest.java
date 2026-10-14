package com.lokal.service;

import com.lokal.domain.ProductCategory;
import com.lokal.domain.ProductUnit;
import com.lokal.web.dto.ApiDtos.ProductRequest;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

class GeocodingServiceTest {

    @Test
    void parsesFirstNominatimHit() {
        String body = "[{\"place_id\":1,\"lat\":\"58.3776\",\"lon\":\"26.7290\",\"display_name\":\"Raekoja plats, Tartu, Eesti\"},"
                + "{\"lat\":\"1\",\"lon\":\"2\"}]";
        var p = GeocodingService.parseFirst(body).orElseThrow();
        assertEquals(58.3776, p.latitude(), 1e-9);
        assertEquals(26.7290, p.longitude(), 1e-9);
        assertEquals("Raekoja plats, Tartu, Eesti", p.displayName());
    }

    @Test
    void emptyResultIsEmpty() {
        assertTrue(GeocodingService.parseFirst("[]").isEmpty());
    }

    private static ProductRequest req(Double lat, Double lng, String label) {
        return new ProductRequest("x", null, ProductCategory.FOOD, BigDecimal.ONE, ProductUnit.piece, BigDecimal.ONE,
                lat, lng, label, true, false, List.of());
    }

    private static ProductService service(Optional<GeocodingService.GeoPoint> hit) {
        GeocodingService fake = new GeocodingService() {
            @Override
            public Optional<GeoPoint> geocode(String address) {
                return hit;
            }
        };
        return new ProductService(null, null, fake);
    }

    @Test
    void explicitCoordinatesWin() {
        double[] p = service(Optional.empty()).resolveLocation(req(58.0, 25.0, "Tartu"));
        assertArrayEquals(new double[] {58.0, 25.0}, p);
    }

    @Test
    void typedAddressIsGeocoded() {
        double[] p = service(Optional.of(new GeocodingService.GeoPoint(58.38, 26.72, "Tartu")))
                .resolveLocation(req(null, null, "Raekoja plats 1, Tartu"));
        assertArrayEquals(new double[] {58.38, 26.72}, p);
    }

    @Test
    void unknownAddressIsRejectedNotDefaulted() {
        assertThrows(IllegalArgumentException.class,
                () -> service(Optional.empty()).resolveLocation(req(null, null, "zzzz")));
        assertThrows(IllegalArgumentException.class,
                () -> service(Optional.empty()).resolveLocation(req(null, null, " ")));
    }
}
