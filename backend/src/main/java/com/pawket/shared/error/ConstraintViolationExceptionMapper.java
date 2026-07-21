package com.pawket.shared.error;

import com.pawket.shared.error.ProblemResponse.FieldError;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import java.util.Comparator;

@Provider
public final class ConstraintViolationExceptionMapper implements ExceptionMapper<ConstraintViolationException> {
    private final UriInfo uriInfo;
    private final HttpHeaders headers;

    public ConstraintViolationExceptionMapper(UriInfo uriInfo, HttpHeaders headers) {
        this.uriInfo = uriInfo;
        this.headers = headers;
    }

    @Override
    public Response toResponse(ConstraintViolationException exception) {
        var correlationId = ProblemResponses.correlationId(headers);
        var errors = exception.getConstraintViolations().stream()
                .map(this::fieldError)
                .sorted(Comparator.comparing(FieldError::field).thenComparing(FieldError::code))
                .toList();
        var problem = new ProblemResponse(
                ProblemResponses.type("VALIDATION_ERROR"),
                "Request validation failed",
                Response.Status.BAD_REQUEST.getStatusCode(),
                "VALIDATION_ERROR",
                "One or more fields are invalid.",
                uriInfo.getPath(),
                correlationId,
                errors);
        return Response.status(Response.Status.BAD_REQUEST)
                .type("application/problem+json")
                .header("X-Correlation-Id", correlationId)
                .entity(problem)
                .build();
    }

    private FieldError fieldError(ConstraintViolation<?> violation) {
        var path = violation.getPropertyPath().toString();
        var field = path.substring(path.lastIndexOf('.') + 1);
        var annotation = violation.getConstraintDescriptor().getAnnotation().annotationType().getSimpleName();
        var code = switch (annotation) {
            case "NotBlank", "NotEmpty", "NotNull" -> "REQUIRED";
            case "Size" -> "INVALID_SIZE";
            case "Min" -> "MIN_VALUE";
            case "Max" -> "MAX_VALUE";
            case "Positive" -> "POSITIVE_REQUIRED";
            default -> "INVALID";
        };
        return new FieldError(field, code, violation.getMessage());
    }
}
