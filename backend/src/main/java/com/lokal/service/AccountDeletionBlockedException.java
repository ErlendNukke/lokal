package com.lokal.service;

import org.springframework.http.HttpStatus;

/** Account deletion refused for a known reason; {@link #getCode()} lets clients show a localized message. */
public class AccountDeletionBlockedException extends RuntimeException {

    public static final String PENDING_ORDERS = "PENDING_ORDERS";
    public static final String PENDING_SELLER_ORDERS = "PENDING_SELLER_ORDERS";
    public static final String DEMO_ACCOUNT = "DEMO_ACCOUNT";

    private final String code;
    private final HttpStatus status;

    public AccountDeletionBlockedException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public String getCode() {
        return code;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
