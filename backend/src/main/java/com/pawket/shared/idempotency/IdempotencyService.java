package com.pawket.shared.idempotency;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.HexFormat;
import java.util.UUID;
import java.util.function.Supplier;

@ApplicationScoped
public class IdempotencyService {
    private static final int MAX_KEY_LENGTH = 200;

    private final EntityManager entityManager;
    private final ObjectMapper objectMapper;

    public IdempotencyService(EntityManager entityManager, ObjectMapper objectMapper) {
        this.entityManager = entityManager;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public <T> T execute(
            UUID actorId,
            String operation,
            String rawKey,
            Object request,
            Class<T> responseType,
            Supplier<T> action) {
        var key = normalizeKey(rawKey);
        if (key == null) return action.get();

        var requestHash = hash(serialize(request));
        var lockScope = actorId + ":" + operation + ":" + key;
        entityManager.createNativeQuery("select pg_advisory_xact_lock(hashtextextended(:scope, 0))")
                .setParameter("scope", lockScope)
                .getSingleResult();

        var existing = entityManager.createNativeQuery("""
                        select request_hash, response_json::text
                        from idempotency_records
                        where actor_user_id = :actorId and operation = :operation and idempotency_key = :key
                        """)
                .setParameter("actorId", actorId)
                .setParameter("operation", operation)
                .setParameter("key", key)
                .getResultStream()
                .findFirst();
        if (existing.isPresent()) {
            var row = (Object[]) existing.get();
            if (!requestHash.equals(row[0])) {
                throw ApiException.conflict(
                        "IDEMPOTENCY_KEY_REUSED",
                        "The idempotency key was already used with a different request.");
            }
            return deserialize((String) row[1], responseType);
        }

        var response = action.get();
        entityManager.createNativeQuery("""
                        insert into idempotency_records (
                            id, actor_user_id, operation, idempotency_key, request_hash, response_json, created_at
                        ) values (
                            :id, :actorId, :operation, :key, :requestHash, cast(:responseJson as jsonb), :createdAt
                        )
                        """)
                .setParameter("id", UUID.randomUUID())
                .setParameter("actorId", actorId)
                .setParameter("operation", operation)
                .setParameter("key", key)
                .setParameter("requestHash", requestHash)
                .setParameter("responseJson", serialize(response))
                .setParameter("createdAt", Instant.now())
                .executeUpdate();
        return response;
    }

    private static String normalizeKey(String rawKey) {
        if (rawKey == null || rawKey.isBlank()) return null;
        var key = rawKey.strip();
        if (key.length() > MAX_KEY_LENGTH) {
            throw ApiException.badRequest("INVALID_IDEMPOTENCY_KEY", "Idempotency-Key is too long.");
        }
        return key;
    }

    private String serialize(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Could not serialize idempotency data", exception);
        }
    }

    private <T> T deserialize(String value, Class<T> type) {
        try {
            return objectMapper.readValue(value, type);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Could not deserialize idempotency response", exception);
        }
    }

    private static String hash(String value) {
        try {
            var digest = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }
}
