package com.lokal.service;

import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Turns a typed address (e.g. "Pirita tee 26, Tallinn") into coordinates using
 * OpenStreetMap Nominatim. Called server-side so the web build has no CORS issues
 * and requests carry a proper User-Agent as Nominatim's usage policy requires.
 */
@Service
public class GeocodingService {

    public record GeoPoint(double latitude, double longitude, String displayName) {}

    private static final Pattern LAT = Pattern.compile("\"lat\"\\s*:\\s*\"(-?[0-9.]+)\"");
    private static final Pattern LON = Pattern.compile("\"lon\"\\s*:\\s*\"(-?[0-9.]+)\"");
    private static final Pattern NAME = Pattern.compile("\"display_name\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"");

    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

    public Optional<GeoPoint> geocode(String address) {
        if (address == null || address.isBlank()) {
            return Optional.empty();
        }
        String url = "https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&countrycodes=ee&q="
                + URLEncoder.encode(address.trim(), StandardCharsets.UTF_8);
        try {
            HttpRequest req = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(8))
                    .header("User-Agent", "Lokal/1.0 (https://lokal-eu.web.app)")
                    .header("Accept-Language", "et,en")
                    .GET()
                    .build();
            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
            if (res.statusCode() != 200) {
                return Optional.empty();
            }
            return parseFirst(res.body());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return Optional.empty();
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    /** Parses the first hit of a Nominatim jsonv2 search response. */
    static Optional<GeoPoint> parseFirst(String body) {
        if (body == null) {
            return Optional.empty();
        }
        Matcher lat = LAT.matcher(body);
        Matcher lon = LON.matcher(body);
        if (!lat.find() || !lon.find()) {
            return Optional.empty();
        }
        Matcher name = NAME.matcher(body);
        String display = name.find() ? name.group(1) : null;
        return Optional.of(new GeoPoint(Double.parseDouble(lat.group(1)), Double.parseDouble(lon.group(1)), display));
    }
}
