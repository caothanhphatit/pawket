package com.pawket.media;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.UserTransaction;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
class MediaHardeningTest {
    private static final UUID DEV_USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");

    @Inject
    EntityManager entityManager;

    @Inject
    UserTransaction transaction;

    @Inject
    MediaCleanupService cleanupService;

    private final Set<UUID> mediaIds = new HashSet<>();

    @AfterEach
    void cleanUp() throws Exception {
        inTransaction(() -> {
            for (var mediaId : mediaIds) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :id")
                        .setParameter("id", mediaId)
                        .executeUpdate();
                entityManager.createNativeQuery("delete from media where id = :id")
                        .setParameter("id", mediaId)
                        .executeUpdate();
            }
        });
    }

    @Test
    void uploadIntentRejectsVideoOversizeAndInvalidDimensions() {
        given()
                .contentType(ContentType.JSON)
                .body("{\"fileName\":\"clip.mp4\",\"mimeType\":\"video/mp4\",\"byteSize\":1024}")
                .when().post("/api/v1/media/upload-intents")
                .then().statusCode(400)
                .body("detail", equalTo("Only JPEG, PNG, WebP, HEIC, or HEIF images are supported"));

        given()
                .contentType(ContentType.JSON)
                .body("{\"fileName\":\"huge.jpg\",\"mimeType\":\"image/jpeg\",\"byteSize\":15728641}")
                .when().post("/api/v1/media/upload-intents")
                .then().statusCode(400)
                .body("code", equalTo("VALIDATION_ERROR"));

        given()
                .contentType(ContentType.JSON)
                .body("{\"fileName\":\"bad.jpg\",\"mimeType\":\"image/jpeg\",\"byteSize\":1024,\"width\":1000}")
                .when().post("/api/v1/media/upload-intents")
                .then().statusCode(400)
                .body("detail", equalTo("Image width and height must be provided together"));
    }

    @Test
    void readinessIncludesObjectStorage() {
        given()
                .when().get("/q/health/ready")
                .then().statusCode(200)
                .body("status", equalTo("UP"))
                .body("checks.name", hasItem("object-storage"));
    }

    @Test
    void cleanupDeletesOnlyExpiredUnattachedMedia() throws Exception {
        var expired = insertPending(Instant.now().minus(3, ChronoUnit.HOURS));
        var recent = insertPending(Instant.now());

        assertTrue(cleanupService.cleanup() >= 1);
        assertEquals("DELETED", status(expired));
        assertEquals("PENDING_UPLOAD", status(recent));
    }

    private UUID insertPending(Instant createdAt) throws Exception {
        var id = UUID.randomUUID();
        mediaIds.add(id);
        inTransaction(() -> entityManager.createNativeQuery("""
                        insert into media (
                            id, owner_user_id, storage_key, media_type, mime_type,
                            byte_size, status, created_at
                        ) values (
                            :id, :ownerId, :storageKey, 'IMAGE', 'image/jpeg',
                            1024, 'PENDING_UPLOAD', :createdAt
                        )
                        """)
                .setParameter("id", id)
                .setParameter("ownerId", DEV_USER_ID)
                .setParameter("storageKey", "cleanup-test/" + id + ".jpg")
                .setParameter("createdAt", createdAt)
                .executeUpdate());
        return id;
    }

    private String status(UUID id) {
        return (String) entityManager.createNativeQuery(
                        "select status from media where id = :id", String.class)
                .setParameter("id", id)
                .getSingleResult();
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
