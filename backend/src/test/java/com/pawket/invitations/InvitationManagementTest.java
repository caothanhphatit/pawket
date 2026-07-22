package com.pawket.invitations;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.UserTransaction;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
class InvitationManagementTest {
    private static final UUID OTHER_USER_ID = UUID.randomUUID();

    @Inject
    EntityManager entityManager;

    @Inject
    UserTransaction transaction;

    private final Set<UUID> petIds = new HashSet<>();
    private final Set<UUID> invitationIds = new HashSet<>();

    @BeforeEach
    void seedUser() throws Exception {
        inTransaction(() -> entityManager.createNativeQuery("""
                        insert into users (id, display_name)
                        values (:id, 'Invitation management user')
                        on conflict (id) do nothing
                        """)
                .setParameter("id", OTHER_USER_ID)
                .executeUpdate());
    }

    @AfterEach
    void cleanData() throws Exception {
        inTransaction(() -> {
            for (var invitationId : invitationIds) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :id")
                        .setParameter("id", invitationId)
                        .executeUpdate();
                entityManager.createNativeQuery("delete from invitations where id = :id")
                        .setParameter("id", invitationId)
                        .executeUpdate();
            }
            for (var petId : petIds) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :id")
                        .setParameter("id", petId)
                        .executeUpdate();
                entityManager.createNativeQuery("delete from pets where id = :id")
                        .setParameter("id", petId)
                        .executeUpdate();
            }
            entityManager.createNativeQuery("delete from users where id = :id")
                    .setParameter("id", OTHER_USER_ID)
                    .executeUpdate();
        });
    }

    @Test
    void ownerCanListAndRevokePendingInvitations() {
        var petId = createPet();
        var invitation = createInvitation(petId);
        var invitationId = invitation.id();

        given()
                .queryParam("petId", petId)
                .when().get("/api/v1/invitations")
                .then()
                .statusCode(200)
                .body("data.id", hasItem(invitationId.toString()))
                .body("data.find { it.id == '%s' }.requestedRole".formatted(invitationId), equalTo("FOLLOWER"));

        given()
                .when().delete("/api/v1/invitations/{invitationId}", invitationId)
                .then()
                .statusCode(204);

        given()
                .header("X-User-Id", OTHER_USER_ID)
                .contentType(ContentType.JSON)
                .body("{\"token\":\"%s\"}".formatted(invitation.token()))
                .when().post("/api/v1/invitations/accept")
                .then()
                .statusCode(400);

        given()
                .queryParam("petId", petId)
                .when().get("/api/v1/invitations")
                .then()
                .statusCode(200)
                .body("data.id", not(hasItem(invitationId.toString())));

        var status = entityManager.createNativeQuery(
                        "select status from invitations where id = :id", String.class)
                .setParameter("id", invitationId)
                .getSingleResult();
        org.junit.jupiter.api.Assertions.assertEquals("REVOKED", status);
        var audits = (Number) entityManager.createNativeQuery("""
                        select count(*) from audit_events
                        where action = 'INVITATION_REVOKED' and resource_id = :id
                        """, Long.class)
                .setParameter("id", invitationId)
                .getSingleResult();
        org.junit.jupiter.api.Assertions.assertEquals(1L, audits.longValue());
    }

    @Test
    void nonOwnerCannotListOrRevokeInvitations() {
        var petId = createPet();
        var invitationId = createInvitation(petId).id();

        given()
                .header("X-User-Id", OTHER_USER_ID)
                .queryParam("petId", petId)
                .when().get("/api/v1/invitations")
                .then()
                .statusCode(403);

        given()
                .header("X-User-Id", OTHER_USER_ID)
                .when().delete("/api/v1/invitations/{invitationId}", invitationId)
                .then()
                .statusCode(403);
    }

    private UUID createPet() {
        var id = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .body("{\"name\":\"Invite management pet\",\"species\":\"CAT\"}")
                .when().post("/api/v1/pets")
                .then().statusCode(201)
                .extract().path("data.id"));
        petIds.add(id);
        return id;
    }

    private CreatedInvitation createInvitation(UUID petId) {
        var response = given()
                .contentType(ContentType.JSON)
                .body("{\"petId\":\"%s\",\"role\":\"FOLLOWER\",\"expiresInDays\":7}".formatted(petId))
                .when().post("/api/v1/invitations")
                .then().statusCode(201)
                .extract();
        var id = UUID.fromString(response.path("data.id"));
        invitationIds.add(id);
        return new CreatedInvitation(id, response.path("data.token"));
    }

    private void inTransaction(Runnable work) throws Exception {
        transaction.begin();
        try {
            work.run();
            transaction.commit();
        } catch (Throwable throwable) {
            if (transaction.getStatus() != jakarta.transaction.Status.STATUS_NO_TRANSACTION) {
                transaction.rollback();
            }
            throw throwable;
        }
    }

    private record CreatedInvitation(UUID id, String token) {}
}
