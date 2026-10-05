package com.lokal.web;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler handler;

    @BeforeEach
    void setUp() {
        handler = new GlobalExceptionHandler();
    }

    @Test
    void illegalStateNotAuthenticatedReturns401() {
        ResponseEntity<Map<String, Object>> response =
                handler.handleIllegalState(new IllegalStateException("Not authenticated"));
        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }

    @Test
    void illegalStateStorageFailureReturns500() {
        ResponseEntity<Map<String, Object>> response =
                handler.handleIllegalState(new IllegalStateException("Failed to store file in S3"));
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
    }

    @Test
    void typeMismatchReturns400() {
        var ex = new MethodArgumentTypeMismatchException("nearby", UUID.class, "id", null, null);
        ResponseEntity<Map<String, Object>> response = handler.handleTypeMismatch(ex);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(400, response.getBody().get("status"));
        assertEquals("Invalid value 'nearby' for id", response.getBody().get("error"));
    }
}
