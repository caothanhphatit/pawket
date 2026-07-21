package com.pawket.shared.auth;

import com.pawket.shared.error.ApiException;
import io.quarkus.arc.profile.IfBuildProfile;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.RequestScoped;
import org.eclipse.microprofile.jwt.JsonWebToken;

@RequestScoped
@IfBuildProfile("prod")
public class OidcCurrentActorProvider implements CurrentActorProvider {
    private final SecurityIdentity securityIdentity;
    private final ActorProvisioningService provisioning;
    private java.util.UUID resolvedUserId;

    public OidcCurrentActorProvider(SecurityIdentity securityIdentity, ActorProvisioningService provisioning) {
        this.securityIdentity = securityIdentity;
        this.provisioning = provisioning;
    }

    @Override
    public java.util.UUID userId() {
        if (resolvedUserId != null) return resolvedUserId;
        if (securityIdentity.isAnonymous() || !(securityIdentity.getPrincipal() instanceof JsonWebToken token)) {
            throw ApiException.unauthorized("AUTHENTICATION_REQUIRED", "A valid access token is required.");
        }
        var issuer = token.getIssuer();
        var subject = token.getSubject();
        if (issuer == null || issuer.isBlank() || subject == null || subject.isBlank()) {
            throw ApiException.unauthorized("INVALID_TOKEN_IDENTITY", "The access token has no stable identity.");
        }
        resolvedUserId = provisioning.resolveOrProvision(
                issuer,
                subject,
                claim(token, "email"),
                firstClaim(token, "name", "preferred_username", "given_name"));
        return resolvedUserId;
    }

    private static String firstClaim(JsonWebToken token, String... names) {
        for (var name : names) {
            var value = claim(token, name);
            if (value != null && !value.isBlank()) return value;
        }
        return null;
    }

    private static String claim(JsonWebToken token, String name) {
        Object value = token.getClaim(name);
        return value == null ? null : value.toString();
    }
}
