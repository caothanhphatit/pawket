package com.pawket.shared.error;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItems;
import static org.hamcrest.Matchers.notNullValue;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;

@QuarkusTest
class ErrorResponseTest {
    @Test
    void beanValidationUsesProblemContract() {
        given()
                .header("X-Correlation-Id", "validation-test")
                .contentType(ContentType.JSON)
                .body("{}")
                .when().post("/api/v1/pets")
                .then()
                .statusCode(400)
                .contentType("application/problem+json")
                .header("X-Correlation-Id", equalTo("validation-test"))
                .body("code", equalTo("VALIDATION_ERROR"))
                .body("detail", equalTo("One or more fields are invalid."))
                .body("correlationId", equalTo("validation-test"))
                .body("errors.field", hasItems("name", "species"))
                .body("errors.code", hasItems("REQUIRED"));
    }

    @Test
    void commonJaxRsErrorsUseProblemContract() {
        given()
                .queryParam("cursor", "not-a-cursor")
                .when().get("/api/v1/feed")
                .then()
                .statusCode(400)
                .contentType("application/problem+json")
                .header("X-Correlation-Id", notNullValue())
                .body("code", equalTo("BAD_REQUEST"))
                .body("detail", equalTo("Invalid cursor"))
                .body("correlationId", notNullValue());
    }
}
