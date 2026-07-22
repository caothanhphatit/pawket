package com.pawket.comments;

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
class CommentNotificationApiTest {
    private static final UUID DEV_USER = UUID.fromString("00000000-0000-0000-0000-000000000001");
    private static final UUID AUTHOR = UUID.randomUUID();
    private static final UUID FOLLOWER = UUID.randomUUID();

    @Inject
    EntityManager entityManager;

    @Inject
    UserTransaction transaction;

    private final Set<UUID> postIds = new HashSet<>();
    private final Set<UUID> mediaIds = new HashSet<>();
    private final Set<UUID> commentIds = new HashSet<>();
    private UUID petId;

    @BeforeEach
    void seedUsers() throws Exception {
        inTransaction(() -> {
            entityManager.createNativeQuery("insert into users (id, display_name) values (:id, 'Memory author')")
                    .setParameter("id", AUTHOR)
                    .executeUpdate();
            entityManager.createNativeQuery("insert into users (id, display_name) values (:id, 'Memory follower')")
                    .setParameter("id", FOLLOWER)
                    .executeUpdate();
        });
    }

    @AfterEach
    void cleanUp() throws Exception {
        inTransaction(() -> {
            for (var commentId : commentIds) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :id")
                        .setParameter("id", commentId)
                        .executeUpdate();
            }
            for (var postId : postIds) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :id")
                        .setParameter("id", postId)
                        .executeUpdate();
            }
            for (var mediaId : mediaIds) {
                entityManager.createNativeQuery("delete from media where id = :id")
                        .setParameter("id", mediaId)
                        .executeUpdate();
            }
            for (var postId : postIds) {
                entityManager.createNativeQuery("delete from posts where id = :id")
                        .setParameter("id", postId)
                        .executeUpdate();
            }
            if (petId != null) {
                entityManager.createNativeQuery("delete from pets where id = :id")
                        .setParameter("id", petId)
                        .executeUpdate();
            }
            entityManager.createNativeQuery("delete from users where id in (:author, :follower)")
                    .setParameter("author", AUTHOR)
                    .setParameter("follower", FOLLOWER)
                    .executeUpdate();
        });
    }

    @Test
    void commentsRespectVisibilityOwnershipModerationAndCreateNotifications() throws Exception {
        petId = createPetAndMembers();
        var postId = createPost(AUTHOR, "PET_MEMBERS");

        var followerInbox = given()
                .header("X-User-Id", FOLLOWER)
                .when().get("/api/v1/notifications")
                .then().statusCode(200)
                .body("data.type", hasItem("NEW_POST"))
                .body("data.find { it.type == 'NEW_POST' }.title", equalTo("New memory"))
                .body("data.find { it.type == 'NEW_POST' }.body", equalTo("Memory author shared a new pet memory."))
                .extract();
        var newPostNotificationId = UUID.fromString(followerInbox.path(
                "data.find { it.type == 'NEW_POST' && it.postId == '%s' }.id".formatted(postId)));

        var commentId = UUID.fromString(given()
                .header("X-User-Id", FOLLOWER)
                .contentType(ContentType.JSON)
                .body("{\"body\":\"  Such a good photo!  \"}")
                .when().post("/api/v1/posts/{postId}/comments", postId)
                .then().statusCode(201)
                .body("data.body", equalTo("Such a good photo!"))
                .body("data.version", equalTo(0))
                .extract().path("data.id"));
        commentIds.add(commentId);

        given()
                .header("X-User-Id", FOLLOWER)
                .contentType(ContentType.JSON)
                .body("{\"body\":\"Edited comment\",\"version\":0}")
                .when().patch("/api/v1/comments/{commentId}", commentId)
                .then().statusCode(200)
                .body("data.body", equalTo("Edited comment"))
                .body("data.version", equalTo(1));

        given()
                .contentType(ContentType.JSON)
                .body("{\"body\":\"Owner cannot rewrite it\",\"version\":1}")
                .when().patch("/api/v1/comments/{commentId}", commentId)
                .then().statusCode(403)
                .body("code", equalTo("COMMENT_UPDATE_FORBIDDEN"));

        var secondCommentId = UUID.fromString(given()
                .header("X-User-Id", FOLLOWER)
                .contentType(ContentType.JSON)
                .body("{\"body\":\"Second comment\"}")
                .when().post("/api/v1/posts/{postId}/comments", postId)
                .then().statusCode(201)
                .extract().path("data.id"));
        commentIds.add(secondCommentId);
        var firstPage = given()
                .header("X-User-Id", FOLLOWER)
                .queryParam("limit", 1)
                .when().get("/api/v1/posts/{postId}/comments", postId)
                .then().statusCode(200)
                .body("data[0].id", equalTo(commentId.toString()))
                .body("page.hasMore", equalTo(true))
                .extract();
        String commentCursor = firstPage.path("page.nextCursor");
        given()
                .header("X-User-Id", FOLLOWER)
                .queryParam("limit", 1)
                .queryParam("cursor", commentCursor)
                .when().get("/api/v1/posts/{postId}/comments", postId)
                .then().statusCode(200)
                .body("data[0].id", equalTo(secondCommentId.toString()));

        // The post author can moderate comments even without being the pet owner.
        given()
                .header("X-User-Id", AUTHOR)
                .when().delete("/api/v1/comments/{commentId}", secondCommentId)
                .then().statusCode(204);

        given()
                .header("X-User-Id", FOLLOWER)
                .contentType(ContentType.JSON)
                .body("{\"type\":\"LOVE\"}")
                .when().put("/api/v1/posts/{postId}/reaction", postId)
                .then().statusCode(200);

        given()
                .header("X-User-Id", AUTHOR)
                .when().get("/api/v1/notifications")
                .then().statusCode(200)
                .body("data.findAll { it.type == 'COMMENT' }.commentId", hasItem(commentId.toString()))
                .body("data.find { it.type == 'REACTION' }.postId", equalTo(postId.toString()))
                .body("data.type", not(hasItem("NEW_POST")));

        // The pet owner can moderate a comment even though another member authored the post.
        given().when().delete("/api/v1/comments/{commentId}", commentId).then().statusCode(204);
        given()
                .header("X-User-Id", FOLLOWER)
                .when().get("/api/v1/posts/{postId}/comments", postId)
                .then().statusCode(200)
                .body("data.id", not(hasItem(commentId.toString())));

        given()
                .header("X-User-Id", FOLLOWER)
                .when().get("/api/v1/notifications/unread-count")
                .then().statusCode(200)
                .body("data.count", equalTo(1));
        given()
                .header("X-User-Id", FOLLOWER)
                .when().post("/api/v1/notifications/{id}/read", newPostNotificationId)
                .then().statusCode(200)
                .body("data.readAt", not(equalTo(null)));
        given()
                .header("X-User-Id", FOLLOWER)
                .when().post("/api/v1/notifications/read-all")
                .then().statusCode(200);
        given()
                .header("X-User-Id", FOLLOWER)
                .when().get("/api/v1/notifications/unread-count")
                .then().statusCode(200)
                .body("data.count", equalTo(0));

        var privatePostId = createPost(AUTHOR, "PRIVATE");
        given()
                .header("X-User-Id", FOLLOWER)
                .contentType(ContentType.JSON)
                .body("{\"body\":\"Should be blocked\"}")
                .when().post("/api/v1/posts/{postId}/comments", privatePostId)
                .then().statusCode(403);

        var secondPublicPost = createPost(AUTHOR, "PET_MEMBERS");
        var notificationPage = given()
                .header("X-User-Id", FOLLOWER)
                .queryParam("limit", 1)
                .when().get("/api/v1/notifications")
                .then().statusCode(200)
                .body("data[0].postId", equalTo(secondPublicPost.toString()))
                .body("page.hasMore", equalTo(true))
                .extract();
        String notificationCursor = notificationPage.path("page.nextCursor");
        given()
                .header("X-User-Id", FOLLOWER)
                .queryParam("limit", 1)
                .queryParam("cursor", notificationCursor)
                .when().get("/api/v1/notifications")
                .then().statusCode(200)
                .body("data[0].id", not(equalTo(notificationPage.path("data[0].id"))));
    }

    private UUID createPetAndMembers() throws Exception {
        var id = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .body("{\"name\":\"Social pet\",\"species\":\"DOG\"}")
                .when().post("/api/v1/pets")
                .then().statusCode(201)
                .extract().path("data.id"));
        inTransaction(() -> {
            addMembership(id, AUTHOR, "CARETAKER");
            addMembership(id, FOLLOWER, "FOLLOWER");
        });
        return id;
    }

    private void addMembership(UUID targetPetId, UUID userId, String role) {
        entityManager.createNativeQuery("""
                        insert into pet_memberships (id, pet_id, user_id, role, status, created_at, joined_at)
                        values (:id, :petId, :userId, :role, 'ACTIVE', now(), now())
                        """)
                .setParameter("id", UUID.randomUUID())
                .setParameter("petId", targetPetId)
                .setParameter("userId", userId)
                .setParameter("role", role)
                .executeUpdate();
    }

    private UUID createPost(UUID authorId, String visibility) throws Exception {
        var mediaId = UUID.randomUUID();
        mediaIds.add(mediaId);
        inTransaction(() -> entityManager.createNativeQuery("""
                        insert into media (
                            id, owner_user_id, storage_key, media_type, mime_type,
                            byte_size, status, created_at, uploaded_at
                        ) values (
                            :id, :ownerId, :key, 'IMAGE', 'image/jpeg', 1024, 'READY', now(), now()
                        )
                        """)
                .setParameter("id", mediaId)
                .setParameter("ownerId", authorId)
                .setParameter("key", "social-test/" + mediaId + ".jpg")
                .executeUpdate());
        var postId = UUID.fromString(given()
                .header("X-User-Id", authorId)
                .contentType(ContentType.JSON)
                .body("""
                        {
                          "caption":"Social memory",
                          "capturedAt":"2026-07-18T08:30:00Z",
                          "visibility":"%s",
                          "petIds":["%s"],
                          "mediaIds":["%s"]
                        }
                        """.formatted(visibility, petId, mediaId))
                .when().post("/api/v1/posts")
                .then().statusCode(201)
                .extract().path("data.id"));
        postIds.add(postId);
        return postId;
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
