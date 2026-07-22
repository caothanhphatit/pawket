package com.pawket.milestones;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;

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
class MilestoneResourceTest {
    private static final UUID CARETAKER_ID = UUID.randomUUID();
    private static final UUID FOLLOWER_ID = UUID.randomUUID();

    @Inject
    EntityManager entityManager;

    @Inject
    UserTransaction transaction;

    private final Set<UUID> petIds = new HashSet<>();
    private final Set<UUID> milestoneIds = new HashSet<>();

    @BeforeEach
    void seedUsers() throws Exception {
        inTransaction(() -> {
            entityManager.createNativeQuery("insert into users (id, display_name) values (:id, 'Milestone caretaker')")
                    .setParameter("id", CARETAKER_ID)
                    .executeUpdate();
            entityManager.createNativeQuery("insert into users (id, display_name) values (:id, 'Milestone follower')")
                    .setParameter("id", FOLLOWER_ID)
                    .executeUpdate();
        });
    }

    @AfterEach
    void cleanData() throws Exception {
        inTransaction(() -> {
            for (var milestoneId : milestoneIds) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :id")
                        .setParameter("id", milestoneId)
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
            entityManager.createNativeQuery("delete from users where id in (:caretaker, :follower)")
                    .setParameter("caretaker", CARETAKER_ID)
                    .setParameter("follower", FOLLOWER_ID)
                    .executeUpdate();
        });
    }

    @Test
    void membersCanListAndContributorsCanCreateMilestones() throws Exception {
        var petId = createPetWithMembers();
        var milestoneId = UUID.fromString(given()
                .header("X-User-Id", CARETAKER_ID)
                .contentType(ContentType.JSON)
                .body("""
                        {
                          "type": "FIRST_TRIP",
                          "occurredOn": "2026-08-02",
                          "note": "First beach day"
                        }
                        """)
                .when().post("/api/v1/pets/{petId}/milestones", petId)
                .then()
                .statusCode(201)
                .body("data.creatorUserId", equalTo(CARETAKER_ID.toString()))
                .body("data.type", equalTo("FIRST_TRIP"))
                .extract().path("data.id"));
        milestoneIds.add(milestoneId);

        given()
                .header("X-User-Id", FOLLOWER_ID)
                .when().get("/api/v1/pets/{petId}/milestones", petId)
                .then()
                .statusCode(200)
                .body("data.id", hasItem(milestoneId.toString()));

        given()
                .header("X-User-Id", FOLLOWER_ID)
                .contentType(ContentType.JSON)
                .body("{\"type\":\"BIRTHDAY\",\"occurredOn\":\"2026-09-01\"}")
                .when().post("/api/v1/pets/{petId}/milestones", petId)
                .then()
                .statusCode(403);
    }

    @Test
    void creatorOrOwnerCanDeleteButFollowerCannot() throws Exception {
        var petId = createPetWithMembers();
        var milestoneId = createCustomMilestone(petId, CARETAKER_ID, "Learned to swim");

        given()
                .header("X-User-Id", FOLLOWER_ID)
                .when().delete("/api/v1/pets/{petId}/milestones/{milestoneId}", petId, milestoneId)
                .then()
                .statusCode(403)
                .body("code", equalTo("MILESTONE_DELETE_FORBIDDEN"));

        given()
                .when().delete("/api/v1/pets/{petId}/milestones/{milestoneId}", petId, milestoneId)
                .then()
                .statusCode(204);

        var auditCount = (Number) entityManager.createNativeQuery("""
                        select count(*) from audit_events
                        where resource_id = :id and action = 'PET_MILESTONE_DELETED'
                        """, Long.class)
                .setParameter("id", milestoneId)
                .getSingleResult();
        org.junit.jupiter.api.Assertions.assertEquals(1L, auditCount.longValue());
    }

    @Test
    void customMilestoneRequiresATitle() throws Exception {
        var petId = createPetWithMembers();
        given()
                .contentType(ContentType.JSON)
                .body("{\"type\":\"CUSTOM\",\"occurredOn\":\"2026-07-22\"}")
                .when().post("/api/v1/pets/{petId}/milestones", petId)
                .then()
                .statusCode(400)
                .body("code", equalTo("MILESTONE_TITLE_REQUIRED"));
    }

    private UUID createPetWithMembers() throws Exception {
        var petId = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .body("{\"name\":\"Milestone pet\",\"species\":\"DOG\"}")
                .when().post("/api/v1/pets")
                .then().statusCode(201)
                .extract().path("data.id"));
        petIds.add(petId);
        inTransaction(() -> {
            addMembership(petId, CARETAKER_ID, "CARETAKER");
            addMembership(petId, FOLLOWER_ID, "FOLLOWER");
        });
        return petId;
    }

    private UUID createCustomMilestone(UUID petId, UUID actorId, String title) {
        var id = UUID.fromString(given()
                .header("X-User-Id", actorId)
                .contentType(ContentType.JSON)
                .body("""
                        {"type":"CUSTOM","customTitle":"%s","occurredOn":"2026-07-20"}
                        """.formatted(title))
                .when().post("/api/v1/pets/{petId}/milestones", petId)
                .then().statusCode(201)
                .extract().path("data.id"));
        milestoneIds.add(id);
        return id;
    }

    private void addMembership(UUID petId, UUID userId, String role) {
        entityManager.createNativeQuery("""
                        insert into pet_memberships (id, pet_id, user_id, role, status, created_at, joined_at)
                        values (:id, :petId, :userId, :role, 'ACTIVE', now(), now())
                        """)
                .setParameter("id", UUID.randomUUID())
                .setParameter("petId", petId)
                .setParameter("userId", userId)
                .setParameter("role", role)
                .executeUpdate();
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
