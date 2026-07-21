package com.pawket.shared.auth;

import com.pawket.shared.error.ApiException;
import io.quarkus.arc.profile.UnlessBuildProfile;
import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.core.HttpHeaders;
import java.util.UUID;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@RequestScoped
@UnlessBuildProfile("prod")
public class DevCurrentActorProvider implements CurrentActorProvider {
    private static final String USER_HEADER = "X-User-Id";

    private final HttpHeaders headers;
    private final UUID defaultUserId;

    public DevCurrentActorProvider(
            HttpHeaders headers,
            @ConfigProperty(name = "pawket.auth.dev-user-id") UUID defaultUserId) {
        this.headers = headers;
        this.defaultUserId = defaultUserId;
    }

    @Override
    public UUID userId() {
        var suppliedUserId = headers.getHeaderString(USER_HEADER);
        if (suppliedUserId == null || suppliedUserId.isBlank()) {
            return defaultUserId;
        }
        try {
            return UUID.fromString(suppliedUserId);
        } catch (IllegalArgumentException exception) {
            throw ApiException.badRequest("INVALID_ACTOR", "X-User-Id must be a valid UUID.");
        }
    }
}
