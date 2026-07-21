package com.pawket.pets.adapter.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;
import static org.hamcrest.Matchers.startsWith;

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
class PetResourceTest {
    private static final UUID DEV_USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");
    private static final UUID OTHER_USER_ID = UUID.randomUUID();

    @Inject
    EntityManager entityManager;

    @Inject
    UserTransaction transaction;

    private final Set<UUID> createdPetIds = new HashSet<>();
    private final Set<UUID> createdMediaIds = new HashSet<>();
    private final Set<UUID> createdPostIds = new HashSet<>();
    private final Set<String> idempotencyKeys = new HashSet<>();

    @BeforeEach
    void seedSecondUser() throws Exception {
        inTransaction(() -> entityManager.createNativeQuery("""
                        insert into users (id, display_name)
                        values (:id, 'Pawket API test user')
                        on conflict (id) do nothing
                        """)
                .setParameter("id", OTHER_USER_ID)
                .executeUpdate());
    }

    @AfterEach
    void cleanTestData() throws Exception {
        inTransaction(() -> {
            for (var key : idempotencyKeys) {
                entityManager.createNativeQuery("delete from idempotency_records where idempotency_key = :key")
                        .setParameter("key", key)
                        .executeUpdate();
            }
            for (var postId : createdPostIds) {
                entityManager.createNativeQuery("delete from reactions where post_id = :postId")
                        .setParameter("postId", postId)
                        .executeUpdate();
                entityManager.createNativeQuery("delete from audit_events where resource_id = :postId")
                        .setParameter("postId", postId)
                        .executeUpdate();
            }
            for (var mediaId : createdMediaIds) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :mediaId")
                        .setParameter("mediaId", mediaId)
                        .executeUpdate();
                entityManager.createNativeQuery("delete from media where id = :mediaId")
                        .setParameter("mediaId", mediaId)
                        .executeUpdate();
            }
            for (var postId : createdPostIds) {
                entityManager.createNativeQuery("delete from posts where id = :postId")
                        .setParameter("postId", postId)
                        .executeUpdate();
            }
            for (var petId : createdPetIds) {
                entityManager.createNativeQuery("delete from audit_events where resource_id = :petId")
                        .setParameter("petId", petId)
                        .executeUpdate();
                entityManager.createNativeQuery("delete from pets where id = :petId")
                        .setParameter("petId", petId)
                        .executeUpdate();
            }
            entityManager.createNativeQuery("delete from users where id = :id")
                    .setParameter("id", OTHER_USER_ID)
                    .executeUpdate();
        });
    }

    @Test
    void devActorReturnsCurrentUserInDataEnvelope() {
        given()
                .when().get("/api/v1/users/me")
                .then()
                .statusCode(200)
                .contentType(ContentType.JSON)
                .body("data.id", equalTo(DEV_USER_ID.toString()))
                .body("data.displayName", equalTo("Local Developer"))
                .body("data.version", equalTo(0));
    }

    @Test
    void ownerCanCreateListGetAndUpdatePet() {
        var petId = createPet("Mochi API test");

        given()
                .when().get("/api/v1/pets")
                .then()
                .statusCode(200)
                .body("data.id", hasItem(petId.toString()))
                .body("data.find { it.id == '%s' }.name".formatted(petId), equalTo("Mochi API test"));

        given()
                .when().get("/api/v1/pets/{petId}", petId)
                .then()
                .statusCode(200)
                .header("ETag", notNullValue())
                .body("data.id", equalTo(petId.toString()))
                .body("data.species", equalTo("CAT"))
                .body("data.birthDate", equalTo("2022-04-03"))
                .body("data.estimatedBirth", equalTo(true));

        given()
                .contentType(ContentType.JSON)
                .body("""
                        {
                          "name": "Mochi Updated",
                          "breed": "Domestic Shorthair",
                          "bio": "Likes sunny windows"
                        }
                        """)
                .when().patch("/api/v1/pets/{petId}", petId)
                .then()
                .statusCode(200)
                .header("ETag", notNullValue())
                .body("data.id", equalTo(petId.toString()))
                .body("data.name", equalTo("Mochi Updated"))
                .body("data.breed", equalTo("Domestic Shorthair"))
                .body("data.bio", equalTo("Likes sunny windows"))
                .body("data.species", equalTo("CAT"));
    }

    @Test
    void createPetReplaysTheOriginalResponseForTheSameIdempotencyKey() {
        var key = UUID.randomUUID().toString();
        idempotencyKeys.add(key);
        var body = """
                {
                  "name": "Idempotent Mochi",
                  "species": "CAT"
                }
                """;

        var firstId = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", key)
                .body(body)
                .when().post("/api/v1/pets")
                .then()
                .statusCode(201)
                .extract().path("data.id"));
        createdPetIds.add(firstId);

        var replayedId = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", key)
                .body(body)
                .when().post("/api/v1/pets")
                .then()
                .statusCode(201)
                .extract().path("data.id"));

        org.junit.jupiter.api.Assertions.assertEquals(firstId, replayedId);
    }

    @Test
    void reusingAnIdempotencyKeyWithDifferentPayloadReturnsConflict() {
        var key = UUID.randomUUID().toString();
        idempotencyKeys.add(key);

        var petId = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", key)
                .body("{\"name\":\"First request\",\"species\":\"DOG\"}")
                .when().post("/api/v1/pets")
                .then()
                .statusCode(201)
                .extract().path("data.id"));
        createdPetIds.add(petId);

        given()
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", key)
                .body("{\"name\":\"Changed request\",\"species\":\"DOG\"}")
                .when().post("/api/v1/pets")
                .then()
                .statusCode(409)
                .body("code", equalTo("IDEMPOTENCY_KEY_REUSED"));
    }

    @Test
    void petIsHiddenFromAnUnrelatedActor() {
        var petId = createPet("Private API test pet");

        given()
                .header("X-User-Id", OTHER_USER_ID)
                .when().get("/api/v1/pets")
                .then()
                .statusCode(200)
                .body("data.id", not(hasItem(petId.toString())));

        given()
                .header("X-User-Id", OTHER_USER_ID)
                .when().get("/api/v1/pets/{petId}", petId)
                .then()
                .statusCode(404)
                .contentType("application/problem+json")
                .body("status", equalTo(404))
                .body("code", equalTo("PET_NOT_FOUND"))
                .body("detail", equalTo("Pet was not found."))
                .body("instance", equalTo("/api/v1/pets/" + petId))
                .body("type", startsWith("https://docs.pawket.app/problems/"));

        given()
                .header("X-User-Id", OTHER_USER_ID)
                .contentType(ContentType.JSON)
                .body("{\"name\":\"Stolen name\"}")
                .when().patch("/api/v1/pets/{petId}", petId)
                .then()
                .statusCode(404)
                .body("code", equalTo("PET_NOT_FOUND"));
    }

    @Test
    void invalidDevActorHeaderUsesProblemEnvelope() {
        given()
                .header("X-User-Id", "not-a-uuid")
                .when().get("/api/v1/pets")
                .then()
                .statusCode(400)
                .contentType("application/problem+json")
                .body("status", equalTo(400))
                .body("code", equalTo("INVALID_ACTOR"))
                .body("detail", equalTo("X-User-Id must be a valid UUID."));
    }

    @Test
    void ownerCanCreatePostFromReadyMediaAndReadItInFeed() throws Exception {
        var petId = createPet("Timeline API test pet");
        var mediaId = UUID.randomUUID();
        createdMediaIds.add(mediaId);
        inTransaction(() -> entityManager.createNativeQuery("""
                        insert into media (
                            id, owner_user_id, storage_key, media_type, mime_type,
                            byte_size, width, height, status, uploaded_at
                        ) values (
                            :id, :ownerId, :storageKey, 'IMAGE', 'image/jpeg',
                            2048, 1080, 1080, 'READY', now()
                        )
                        """)
                .setParameter("id", mediaId)
                .setParameter("ownerId", DEV_USER_ID)
                .setParameter("storageKey", "test/" + mediaId + ".jpg")
                .executeUpdate());

        var postId = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .body("""
                        {
                          "caption": "  First sunny memory  ",
                          "capturedAt": "2026-07-18T08:30:00Z",
                          "visibility": "PET_MEMBERS",
                          "petIds": ["%s"],
                          "mediaIds": ["%s"]
                        }
                        """.formatted(petId, mediaId))
                .when().post("/api/v1/posts")
                .then()
                .statusCode(201)
                .body("data.id", notNullValue())
                .body("data.authorId", equalTo(DEV_USER_ID.toString()))
                .body("data.caption", equalTo("First sunny memory"))
                .body("data.petIds", hasItem(petId.toString()))
                .body("data.media[0].id", equalTo(mediaId.toString()))
                .body("data.media[0].status", equalTo("READY"))
                .extract().path("data.id"));
        createdPostIds.add(postId);

        given()
                .when().get("/api/v1/posts/{postId}", postId)
                .then()
                .statusCode(200)
                .body("data.id", equalTo(postId.toString()))
                .body("data.media[0].id", equalTo(mediaId.toString()));

        given()
                .queryParam("petId", petId)
                .queryParam("limit", 10)
                .when().get("/api/v1/feed")
                .then()
                .statusCode(200)
                .body("data[0].id", equalTo(postId.toString()))
                .body("data[0].media[0].id", equalTo(mediaId.toString()))
                .body("page.hasMore", equalTo(false));

        given()
                .queryParam("limit", 10)
                .when().get("/api/v1/pets/{petId}/timeline", petId)
                .then()
                .statusCode(200)
                .body("data[0].id", equalTo(postId.toString()))
                .body("data[0].petIds", hasItem(petId.toString()))
                .body("data[0].media[0].id", equalTo(mediaId.toString()))
                .body("page.hasMore", equalTo(false));

        given()
                .contentType(ContentType.JSON)
                .body("{\"type\":\"LOVE\"}")
                .when().put("/api/v1/posts/{postId}/reaction", postId)
                .then()
                .statusCode(200)
                .body("data.counts.LOVE", equalTo(1))
                .body("data.currentUserReaction", equalTo("LOVE"));

        given()
                .when().get("/api/v1/posts/{postId}", postId)
                .then()
                .statusCode(200)
                .body("data.reactions.LOVE", equalTo(1))
                .body("data.myReaction", equalTo("LOVE"));

        given()
                .when().delete("/api/v1/posts/{postId}/reaction", postId)
                .then()
                .statusCode(200)
                .body("data.counts.isEmpty()", equalTo(true))
                .body("data.currentUserReaction", nullValue());

        given()
                .when().get("/api/v1/posts/{postId}", postId)
                .then()
                .statusCode(200)
                .body("data.reactions.isEmpty()", equalTo(true))
                .body("data.myReaction", nullValue());
    }

    @Test
    void friendsVisibilityIsRejectedUntilFriendshipsExist() {
        var petId = createPet("Friends visibility test pet");

        given()
                .contentType(ContentType.JSON)
                .body("""
                        {
                          "capturedAt": "2026-07-18T08:30:00Z",
                          "visibility": "FRIENDS",
                          "petIds": ["%s"],
                          "mediaIds": ["%s"]
                        }
                        """.formatted(petId, UUID.randomUUID()))
                .when().post("/api/v1/posts")
                .then()
                .statusCode(400)
                .contentType("application/problem+json")
                .body("code", equalTo("BAD_REQUEST"))
                .body("detail", equalTo("Invalid post visibility"));
    }

    @Test
    void readyMediaCannotBeAttachedToASecondPost() throws Exception {
        var petId = createPet("Single attachment test pet");
        var mediaId = createReadyMedia();
        var request = """
                {
                  "capturedAt": "2026-07-18T08:30:00Z",
                  "visibility": "PET_MEMBERS",
                  "petIds": ["%s"],
                  "mediaIds": ["%s"]
                }
                """.formatted(petId, mediaId);

        var firstPostId = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .body(request)
                .when().post("/api/v1/posts")
                .then()
                .statusCode(201)
                .extract().path("data.id"));
        createdPostIds.add(firstPostId);

        given()
                .contentType(ContentType.JSON)
                .body(request)
                .when().post("/api/v1/posts")
                .then()
                .statusCode(400)
                .body("detail", equalTo("All media must be ready, owned by the author, and unused"));

        var attachedPostId = (UUID) entityManager.createNativeQuery(
                        "select post_id from media where id = :mediaId", UUID.class)
                .setParameter("mediaId", mediaId)
                .getSingleResult();
        org.junit.jupiter.api.Assertions.assertEquals(firstPostId, attachedPostId);
    }

    private UUID createPet(String name) {
        var id = UUID.fromString(given()
                .contentType(ContentType.JSON)
                .body("""
                        {
                          "name": "%s",
                          "species": "CAT",
                          "birthDate": "2022-04-03",
                          "estimatedBirth": true,
                          "gender": "FEMALE",
                          "adoptionDate": "2022-06-10"
                        }
                        """.formatted(name))
                .when().post("/api/v1/pets")
                .then()
                .statusCode(201)
                .header("Location", startsWith("http://localhost:"))
                .header("ETag", notNullValue())
                .body("data.name", equalTo(name))
                .body("data.species", equalTo("CAT"))
                .extract().path("data.id"));
        createdPetIds.add(id);
        return id;
    }

    private UUID createReadyMedia() throws Exception {
        var mediaId = UUID.randomUUID();
        createdMediaIds.add(mediaId);
        inTransaction(() -> entityManager.createNativeQuery("""
                        insert into media (
                            id, owner_user_id, storage_key, media_type, mime_type,
                            byte_size, width, height, status, uploaded_at
                        ) values (
                            :id, :ownerId, :storageKey, 'IMAGE', 'image/jpeg',
                            2048, 1080, 1080, 'READY', now()
                        )
                        """)
                .setParameter("id", mediaId)
                .setParameter("ownerId", DEV_USER_ID)
                .setParameter("storageKey", "test/" + mediaId + ".jpg")
                .executeUpdate());
        return mediaId;
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
