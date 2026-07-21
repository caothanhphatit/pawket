package com.pawket.shared.error;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProblemResponse(
        String type,
        String title,
        int status,
        String code,
        String detail,
        String instance,
        String correlationId,
        List<FieldError> errors) {

    public record FieldError(String field, String code, String message) {}
}
