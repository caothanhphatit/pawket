package com.pawket.shared.error;

import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

@Provider
public final class ApiExceptionMapper implements ExceptionMapper<ApiException> {
    private final UriInfo uriInfo;
    private final HttpHeaders headers;

    public ApiExceptionMapper(UriInfo uriInfo, HttpHeaders headers) {
        this.uriInfo = uriInfo;
        this.headers = headers;
    }

    @Override
    public Response toResponse(ApiException exception) {
        var status = exception.status();
        var problem = new ProblemResponse(
                "https://docs.pawket.app/problems/" + exception.code().toLowerCase().replace('_', '-'),
                status.getReasonPhrase(),
                status.getStatusCode(),
                exception.code(),
                exception.getMessage(),
                uriInfo.getPath(),
                ProblemResponses.correlationId(headers),
                null);
        return Response.status(status)
                .type("application/problem+json")
                .header("X-Correlation-Id", problem.correlationId())
                .entity(problem)
                .build();
    }
}
