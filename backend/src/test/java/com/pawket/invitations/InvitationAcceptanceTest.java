package com.pawket.invitations;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.UserTransaction;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
class InvitationAcceptanceTest {
    private static final UUID FIRST_USER = UUID.randomUUID();
    private static final UUID SECOND_USER = UUID.randomUUID();

    @Inject
    EntityManager entityManager;

    @Inject
    UserTransaction transaction;

    private UUID petId;
    private UUID invitationId;

    @BeforeEach
    void seedUsers() throws Exception {
        inTransaction(() -> {
            entityManager.createNativeQuery("insert into users (id, display_name) values (:id, 'First acceptor')")
                    .setParameter("id", FIRST_USER)
                    .executeUpdate();
            entityManager.createNativeQuery("insert into users (id, display_name) values (:id, 'Second acceptor')")
                    .setParameter("id", SECOND_USER)
                    .executeUpdate();
        });
    }

    @AfterEach
    void cleanUp() throws Exception {
        inTransaction(() -> {
            if (invitationId != null) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :id")
                        .setParameter("id", invitationId)
                        .executeUpdate();
                entityManager.createNativeQuery("delete from invitations where id = :id")
                        .setParameter("id", invitationId)
                        .executeUpdate();
            }
            if (petId != null) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :id")
                        .setParameter("id", petId)
                        .executeUpdate();
                entityManager.createNativeQuery("delete from pets where id = :id")
                        .setParameter("id", petId)
                        .executeUpdate();
            }
            entityManager.createNativeQuery("delete from users where id in (:first, :second)")
                    .setParameter("first", FIRST_USER)
                    .setParameter("second", SECOND_USER)
                    .executeUpdate();
        });
    }

    @Test
    void onlyOneUserCanAcceptAnInvitation() throws Exception {
        petId = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .body("{\"name\":\"Invite race pet\",\"species\":\"DOG\"}")
                .when().post("/api/v1/pets")
                .then().statusCode(201)
                .extract().path("data.id"));

        var invitation = given()
                .contentType(ContentType.JSON)
                .body("{\"petId\":\"%s\",\"role\":\"FOLLOWER\",\"expiresInDays\":7}".formatted(petId))
                .when().post("/api/v1/invitations")
                .then().statusCode(201)
                .extract();
        invitationId = UUID.fromString(invitation.path("data.id"));
        String token = invitation.path("data.token");

        var start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            var first = executor.submit(() -> accept(start, FIRST_USER, token));
            var second = executor.submit(() -> accept(start, SECOND_USER, token));
            start.countDown();
            var statuses = List.of(first.get(), second.get()).stream().sorted().toList();
            assertEquals(List.of(200, 400), statuses);
        }

        var memberCount = ((Number) entityManager.createNativeQuery("""
                        select count(*) from pet_memberships
                        where pet_id = :petId and user_id in (:first, :second) and status = 'ACTIVE'
                        """, Long.class)
                .setParameter("petId", petId)
                .setParameter("first", FIRST_USER)
                .setParameter("second", SECOND_USER)
                .getSingleResult()).longValue();
        assertEquals(1, memberCount);
        UUID acceptedBy = (UUID) entityManager.createNativeQuery(
                        "select accepted_by_user_id from invitations where id = :id", UUID.class)
                .setParameter("id", invitationId)
                .getSingleResult();
        assertTrue(acceptedBy.equals(FIRST_USER) || acceptedBy.equals(SECOND_USER));

        given()
                .when().get("/api/v1/notifications")
                .then().statusCode(200)
                .body("data.find { it.type == 'INVITATION_ACCEPTED' && it.invitationId == '%s' }.actor.id"
                                .formatted(invitationId),
                        equalTo(acceptedBy.toString()));
    }

    private int accept(CountDownLatch start, UUID actorId, String token) throws InterruptedException {
        start.await();
        return given()
                .header("X-User-Id", actorId)
                .contentType(ContentType.JSON)
                .body("{\"token\":\"%s\"}".formatted(token))
                .when().post("/api/v1/invitations/accept")
                .statusCode();
    }

    private void inTransaction(Runnable work) throws Exception {
        transaction.begin();
        try {
            work.run();
            transaction.commit();
        } catch (Throwable throwable) {
            if (transaction.getStatus() != jakarta.transaction.Status.STATUS_NO_TRANSACTION) transaction.rollback();
            throw throwable;
        }
    }
}
