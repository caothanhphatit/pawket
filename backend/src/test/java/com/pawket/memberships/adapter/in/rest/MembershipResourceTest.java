package com.pawket.memberships.adapter.in.rest;

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
class MembershipResourceTest {
    private static final UUID OWNER_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");
    private static final UUID OTHER_USER_ID = UUID.randomUUID();

    @Inject
    EntityManager entityManager;

    @Inject
    UserTransaction transaction;

    private final Set<UUID> petIds = new HashSet<>();
    private final Set<UUID> membershipIds = new HashSet<>();

    @BeforeEach
    void seedUser() throws Exception {
        inTransaction(() -> entityManager.createNativeQuery("""
                        insert into users (id, display_name)
                        values (:id, 'Removable Pawket member')
                        on conflict (id) do nothing
                        """)
                .setParameter("id", OTHER_USER_ID)
                .executeUpdate());
    }

    @AfterEach
    void cleanData() throws Exception {
        inTransaction(() -> {
            for (var membershipId : membershipIds) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :id")
                        .setParameter("id", membershipId)
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
    void ownerCanRemoveANonOwnerMember() throws Exception {
        var petId = createPet();
        var membershipId = addMember(petId, OTHER_USER_ID, "FOLLOWER");

        given()
                .when().get("/api/v1/pets/{petId}/members", petId)
                .then()
                .statusCode(200)
                .body("data.userId", hasItem(OTHER_USER_ID.toString()));

        given()
                .when().delete("/api/v1/pets/{petId}/members/{userId}", petId, OTHER_USER_ID)
                .then()
                .statusCode(204);

        given()
                .when().get("/api/v1/pets/{petId}/members", petId)
                .then()
                .statusCode(200)
                .body("data.userId", not(hasItem(OTHER_USER_ID.toString())));

        inTransaction(() -> {
            var status = entityManager.createNativeQuery(
                            "select status from pet_memberships where id = :id", String.class)
                    .setParameter("id", membershipId)
                    .getSingleResult();
            org.junit.jupiter.api.Assertions.assertEquals("REMOVED", status);
            var audits = (Number) entityManager.createNativeQuery("""
                            select count(*) from audit_events
                            where action = 'PET_MEMBER_REMOVED' and resource_id = :id
                            """, Long.class)
                    .setParameter("id", membershipId)
                    .getSingleResult();
            org.junit.jupiter.api.Assertions.assertEquals(1L, audits.longValue());
        });
    }

    @Test
    void caretakerCannotRemoveMembersAndOwnerCannotBeRemoved() throws Exception {
        var petId = createPet();
        addMember(petId, OTHER_USER_ID, "CARETAKER");

        given()
                .header("X-User-Id", OTHER_USER_ID)
                .when().delete("/api/v1/pets/{petId}/members/{userId}", petId, OWNER_ID)
                .then()
                .statusCode(403)
                .body("code", equalTo("MEMBER_REMOVE_FORBIDDEN"));

        given()
                .when().delete("/api/v1/pets/{petId}/members/{userId}", petId, OWNER_ID)
                .then()
                .statusCode(400)
                .body("code", equalTo("OWNER_REMOVAL_NOT_ALLOWED"));
    }

    private UUID createPet() {
        var petId = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .body("{\"name\":\"Membership test pet\",\"species\":\"DOG\"}")
                .when().post("/api/v1/pets")
                .then()
                .statusCode(201)
                .extract().path("data.id"));
        petIds.add(petId);
        return petId;
    }

    private UUID addMember(UUID petId, UUID userId, String role) throws Exception {
        var id = UUID.randomUUID();
        membershipIds.add(id);
        inTransaction(() -> entityManager.createNativeQuery("""
                        insert into pet_memberships (
                            id, pet_id, user_id, role, status, created_at, joined_at
                        ) values (:id, :petId, :userId, :role, 'ACTIVE', now(), now())
                        """)
                .setParameter("id", id)
                .setParameter("petId", petId)
                .setParameter("userId", userId)
                .setParameter("role", role)
                .executeUpdate());
        return id;
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
}
