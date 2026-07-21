package com.pawket.shared.error;

import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

@Provider
public final class WebApplicationExceptionMapper implements ExceptionMapper<WebApplicationException> {
    private final UriInfo uriInfo;
    private final HttpHeaders headers;

    public WebApplicationExceptionMapper(UriInfo uriInfo, HttpHeaders headers) {
        this.uriInfo = uriInfo;
        this.headers = headers;
    }

    @Override
    public Response toResponse(WebApplicationException exception) {
        var source = exception.getResponse();
        var status = source.getStatus();
        var statusInfo = Response.Status.fromStatusCode(status);
        var title = statusInfo == null ? "Request failed" : statusInfo.getReasonPhrase();
        var code = codeFor(status);
        var correlationId = ProblemResponses.correlationId(headers);
        var detail = safeDetail(exception.getMessage(), title, status);
        var problem = new ProblemResponse(
                ProblemResponses.type(code), title, status, code, detail,
                uriInfo.getPath(), correlationId, null);
        return Response.fromResponse(source)
                .type("application/problem+json")
                .header("X-Correlation-Id", correlationId)
                .entity(problem)
                .build();
    }

    private static String codeFor(int status) {
        return switch (status) {
            case 400 -> "BAD_REQUEST";
            case 401 -> "UNAUTHORIZED";
            case 403 -> "FORBIDDEN";
            case 404 -> "NOT_FOUND";
            case 405 -> "METHOD_NOT_ALLOWED";
            case 409 -> "CONFLICT";
            case 412 -> "PRECONDITION_FAILED";
            case 415 -> "UNSUPPORTED_MEDIA_TYPE";
            case 429 -> "RATE_LIMITED";
            default -> status >= 500 ? "INTERNAL_ERROR" : "HTTP_ERROR";
        };
    }

    private static String safeDetail(String message, String fallback, int status) {
        if (status >= 500) return "Pawket could not complete the request.";
        if (message == null || message.isBlank() || message.startsWith("HTTP ")) {
            return fallback;
        }
        return message;
    }
}
