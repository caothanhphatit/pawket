package com.pawket.safety;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.UserTransaction;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
class SafetyApiTest {
    private static final UUID OWNER = UUID.fromString("00000000-0000-0000-0000-000000000001");
    private static final UUID MEMBER = UUID.randomUUID();
    private final UUID petId = UUID.randomUUID();
    private final UUID postId = UUID.randomUUID();

    @Inject EntityManager entityManager;
    @Inject UserTransaction transaction;

    @BeforeEach
    void seed() throws Exception {
        inTransaction(() -> {
            entityManager.createNativeQuery("insert into users (id, display_name) values (:id, 'Safety member')")
                    .setParameter("id", MEMBER).executeUpdate();
            entityManager.createNativeQuery("insert into pets (id, name, species) values (:id, 'Safe pet', 'DOG')")
                    .setParameter("id", petId).executeUpdate();
            addMembership(OWNER, "OWNER");
            addMembership(MEMBER, "FOLLOWER");
            entityManager.createNativeQuery("""
                            insert into posts (id, author_id, caption, visibility, captured_at, status)
                            values (:id, :owner, 'Shared safely', 'PET_MEMBERS', :now, 'PUBLISHED')
                            """).setParameter("id", postId).setParameter("owner", OWNER)
                    .setParameter("now", Instant.now()).executeUpdate();
            entityManager.createNativeQuery("insert into post_pets (post_id, pet_id) values (:postId, :petId)")
                    .setParameter("postId", postId).setParameter("petId", petId).executeUpdate();
            entityManager.createNativeQuery("insert into reactions (id, post_id, user_id, type) values (:id, :postId, :owner, 'LOVE')")
                    .setParameter("id", UUID.randomUUID()).setParameter("postId", postId).setParameter("owner", OWNER).executeUpdate();
        });
    }

    @AfterEach
    void clean() throws Exception {
        inTransaction(() -> {
            entityManager.createNativeQuery("delete from content_reports where target_id = :postId").setParameter("postId", postId).executeUpdate();
            entityManager.createNativeQuery("delete from user_blocks where blocker_user_id = :member or blocked_user_id = :member")
                    .setParameter("member", MEMBER).executeUpdate();
            entityManager.createNativeQuery("delete from audit_events where actor_user_id = :member or resource_id in (:postId, :member)")
                    .setParameter("member", MEMBER).setParameter("postId", postId).executeUpdate();
            entityManager.createNativeQuery("delete from posts where id = :postId").setParameter("postId", postId).executeUpdate();
            entityManager.createNativeQuery("delete from pets where id = :petId").setParameter("petId", petId).executeUpdate();
            entityManager.createNativeQuery("delete from users where id = :member").setParameter("member", MEMBER).executeUpdate();
        });
    }

    @Test
    void profileReactionPeopleBlockAndReportFlow() {
        given().header("X-User-Id", MEMBER).when().get("/api/v1/users/{id}", OWNER).then()
                .statusCode(200).body("data.sharedPets.id", hasItem(petId.toString()));
        given().header("X-User-Id", MEMBER).when().get("/api/v1/posts/{id}/reaction/people", postId).then()
                .statusCode(200).body("data.userId", hasItem(OWNER.toString()));

        given().header("X-User-Id", MEMBER).when().post("/api/v1/blocks/{id}", OWNER).then().statusCode(204);
        given().header("X-User-Id", MEMBER).when().get("/api/v1/posts/{id}", postId).then().statusCode(403);
        given().header("X-User-Id", MEMBER).contentType(ContentType.JSON).body("{\"type\":\"LOVE\"}")
                .when().put("/api/v1/posts/{id}/reaction", postId).then().statusCode(403);
        given().header("X-User-Id", MEMBER).when().delete("/api/v1/blocks/{id}", OWNER).then().statusCode(204);

        given().header("X-User-Id", MEMBER).contentType(ContentType.JSON)
                .body("{\"targetType\":\"POST\",\"targetId\":\"%s\",\"reason\":\"PRIVACY\"}".formatted(postId))
                .when().post("/api/v1/reports").then().statusCode(200).body("data.status", equalTo("PENDING"));
        given().header("X-User-Id", MEMBER).contentType(ContentType.JSON)
                .body("{\"targetType\":\"COMMENT\",\"targetId\":\"%s\",\"reason\":\"SPAM\"}"
                        .formatted(UUID.randomUUID()))
                .when().post("/api/v1/reports").then().statusCode(404)
                .body("code", equalTo("COMMENT_NOT_FOUND"));
        given().header("X-User-Id", MEMBER).when().get("/api/v1/reports").then()
                .statusCode(200).body("data.targetId", hasItem(postId.toString()));
        given().when().get("/api/v1/admin/reports").then()
                .statusCode(200).body("data.targetId", hasItem(postId.toString()));
    }

    private void addMembership(UUID userId, String role) {
        entityManager.createNativeQuery("""
                        insert into pet_memberships (id, pet_id, user_id, role, status, created_at, joined_at)
                        values (:id, :petId, :userId, :role, 'ACTIVE', now(), now())
                        """).setParameter("id", UUID.randomUUID()).setParameter("petId", petId)
                .setParameter("userId", userId).setParameter("role", role).executeUpdate();
    }

    private void inTransaction(Runnable work) throws Exception {
        transaction.begin();
        try { work.run(); transaction.commit(); }
        catch (Throwable throwable) { if (transaction.getStatus() != jakarta.transaction.Status.STATUS_NO_TRANSACTION) transaction.rollback(); throw throwable; }
    }
}
