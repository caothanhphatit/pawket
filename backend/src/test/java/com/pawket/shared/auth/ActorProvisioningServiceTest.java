package com.pawket.shared.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;

import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.UserTransaction;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
class ActorProvisioningServiceTest {
    private static final String ISSUER = "https://identity.test.pawket.app";
    private static final String SUBJECT = "actor-provisioning-test";

    @Inject
    ActorProvisioningService provisioning;

    @Inject
    EntityManager entityManager;

    @Inject
    UserTransaction transaction;

    @AfterEach
    void cleanUp() throws Exception {
        transaction.begin();
        try {
            entityManager.createNativeQuery("""
                            delete from users where id in (
                                select user_id from user_identities where issuer = :issuer and subject = :subject
                            )
                            """)
                    .setParameter("issuer", ISSUER)
                    .setParameter("subject", SUBJECT)
                    .executeUpdate();
            transaction.commit();
        } catch (Throwable throwable) {
            transaction.rollback();
            throw throwable;
        }
    }

    @Test
    void provisionsOnceAndReturnsStableInternalUser() {
        UUID first = provisioning.resolveOrProvision(ISSUER, SUBJECT, "paw@example.com", "Paw User");
        UUID second = provisioning.resolveOrProvision(ISSUER, SUBJECT, "changed@example.com", "Changed Name");

        assertEquals(first, second);
        Object[] row = (Object[]) entityManager.createNativeQuery("""
                        select u.display_name, i.email
                        from users u join user_identities i on i.user_id = u.id
                        where i.issuer = :issuer and i.subject = :subject
                        """)
                .setParameter("issuer", ISSUER)
                .setParameter("subject", SUBJECT)
                .getSingleResult();
        assertEquals("Paw User", row[0]);
        assertEquals("paw@example.com", row[1]);
    }
}
