package com.pawket.shared.auth;

import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class ActorProvisioningService {
    private final EntityManager entityManager;

    public ActorProvisioningService(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    @Transactional
    @SuppressWarnings("unchecked")
    public UUID resolveOrProvision(String issuer, String subject, String email, String displayName) {
        // Serialize first-login provisioning for one external identity without a process-local lock.
        entityManager.createNativeQuery("select pg_advisory_xact_lock(hashtextextended(:identityKey, 0))")
                .setParameter("identityKey", issuer + "\n" + subject)
                .getSingleResult();

        List<Object[]> existing = entityManager.createNativeQuery("""
                        select u.id, u.status
                        from user_identities i
                        join users u on u.id = i.user_id
                        where i.issuer = :issuer and i.subject = :subject
                        """)
                .setParameter("issuer", issuer)
                .setParameter("subject", subject)
                .getResultList();
        if (!existing.isEmpty()) {
            var row = existing.getFirst();
            if (!"ACTIVE".equals(row[1])) {
                throw ApiException.forbidden("ACCOUNT_UNAVAILABLE", "This Pawket account is unavailable.");
            }
            return (UUID) row[0];
        }

        var userId = UUID.randomUUID();
        var now = Instant.now();
        entityManager.createNativeQuery("""
                        insert into users (id, display_name, status, created_at, updated_at)
                        values (:id, :displayName, 'ACTIVE', :now, :now)
                        """)
                .setParameter("id", userId)
                .setParameter("displayName", normalizedDisplayName(displayName, email))
                .setParameter("now", now)
                .executeUpdate();
        entityManager.createNativeQuery("""
                        insert into user_identities (id, user_id, issuer, subject, email, created_at)
                        values (:id, :userId, :issuer, :subject, :email, :now)
                        """)
                .setParameter("id", UUID.randomUUID())
                .setParameter("userId", userId)
                .setParameter("issuer", issuer)
                .setParameter("subject", subject)
                .setParameter("email", normalizedEmail(email))
                .setParameter("now", now)
                .executeUpdate();
        return userId;
    }

    private static String normalizedDisplayName(String displayName, String email) {
        var candidate = displayName;
        if (candidate == null || candidate.isBlank()) {
            if (email != null) {
                var separator = email.indexOf('@');
                candidate = separator > 0 ? email.substring(0, separator) : email;
            }
        }
        if (candidate == null || candidate.isBlank()) candidate = "Pawket member";
        candidate = candidate.strip();
        return candidate.length() <= 120 ? candidate : candidate.substring(0, 120);
    }

    private static String normalizedEmail(String email) {
        if (email == null || email.isBlank()) return null;
        var normalized = email.strip().toLowerCase();
        return normalized.length() <= 320 ? normalized : normalized.substring(0, 320);
    }
}
