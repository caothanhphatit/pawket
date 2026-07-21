package com.pawket.shared.error;

import jakarta.ws.rs.core.HttpHeaders;
import java.util.UUID;

final class ProblemResponses {
    private static final int MAX_CORRELATION_ID_LENGTH = 120;

    private ProblemResponses() {}

    static String correlationId(HttpHeaders headers) {
        var supplied = headers.getHeaderString("X-Correlation-Id");
        if (supplied == null || supplied.isBlank() || supplied.length() > MAX_CORRELATION_ID_LENGTH) {
            return UUID.randomUUID().toString();
        }
        return supplied;
    }

    static String type(String code) {
        return "https://docs.pawket.app/problems/" + code.toLowerCase().replace('_', '-');
    }
}
