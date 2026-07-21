package com.pawket.shared.error;

import jakarta.ws.rs.core.Response;

public final class ApiException extends RuntimeException {
    private final Response.Status status;
    private final String code;

    private ApiException(Response.Status status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public static ApiException badRequest(String code, String message) {
        return new ApiException(Response.Status.BAD_REQUEST, code, message);
    }

    public static ApiException unauthorized(String code, String message) {
        return new ApiException(Response.Status.UNAUTHORIZED, code, message);
    }

    public static ApiException notFound(String code, String message) {
        return new ApiException(Response.Status.NOT_FOUND, code, message);
    }

    public static ApiException forbidden(String code, String message) {
        return new ApiException(Response.Status.FORBIDDEN, code, message);
    }

    public static ApiException conflict(String code, String message) {
        return new ApiException(Response.Status.CONFLICT, code, message);
    }

    public Response.Status status() {
        return status;
    }

    public String code() {
        return code;
    }
}
