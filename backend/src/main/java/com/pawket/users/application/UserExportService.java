package com.pawket.users.application;

import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
public class UserExportService {
    private static final int MAX_PETS = 500;
    private static final int MAX_POSTS = 10_000;
    private static final int MAX_POST_PET_TAGS = 50_000;
    private static final int MAX_MEDIA = 20_000;
    private static final int MAX_REACTIONS = 20_000;

    private final EntityManager entityManager;
    private final UserQueryService users;

    public UserExportService(EntityManager entityManager, UserQueryService users) {
        this.entityManager = entityManager;
        this.users = users;
    }

    @Transactional
    @SuppressWarnings("unchecked")
    public UserExport export(UUID actorId) {
        var user = users.getCurrent(actorId);
        List<Object[]> petRows = bounded(entityManager.createNativeQuery("""
                        select p.id, p.name, p.species, p.avatar_media_id, p.birth_date,
                               p.estimated_birth, p.gender, p.breed, p.adoption_date, p.bio,
                               p.status, p.created_at, p.updated_at, p.version,
                               pm.role, pm.joined_at
                        from pet_memberships pm
                        join pets p on p.id = pm.pet_id
                        where pm.user_id = :actorId and pm.status = 'ACTIVE' and p.status <> 'DELETED'
                        order by p.created_at, p.id
                        """)
                .setParameter("actorId", actorId)
                .setMaxResults(MAX_PETS + 1)
                .getResultList(), MAX_PETS, "pet profiles");
        var pets = petRows.stream().map(row -> new ExportPet(
                (UUID) row[0], (String) row[1], (String) row[2], (UUID) row[3],
                (LocalDate) row[4], (Boolean) row[5], (String) row[6], (String) row[7],
                (LocalDate) row[8], (String) row[9], (String) row[10], (Instant) row[11],
                (Instant) row[12], ((Number) row[13]).longValue(), (String) row[14], (Instant) row[15]))
                .toList();

        List<Object[]> postRows = bounded(entityManager.createNativeQuery("""
                        select id, caption, visibility, captured_at, status, created_at, updated_at, version
                        from posts where author_id = :actorId
                        order by created_at, id
                        """)
                .setParameter("actorId", actorId)
                .setMaxResults(MAX_POSTS + 1)
                .getResultList(), MAX_POSTS, "authored memories");
        var postIds = postRows.stream().map(row -> (UUID) row[0]).toList();
        Map<UUID, List<UUID>> petIdsByPost = new LinkedHashMap<>();
        Map<UUID, List<ExportMedia>> mediaByPost = new LinkedHashMap<>();
        if (!postIds.isEmpty()) {
            List<Object[]> tagRows = bounded(entityManager.createNativeQuery("""
                            select post_id, pet_id from post_pets
                            where post_id in (:postIds) order by post_id, pet_id
                            """)
                    .setParameter("postIds", postIds)
                    .setMaxResults(MAX_POST_PET_TAGS + 1)
                    .getResultList(), MAX_POST_PET_TAGS, "memory pet tags");
            tagRows.forEach(row -> petIdsByPost
                    .computeIfAbsent((UUID) row[0], ignored -> new ArrayList<>())
                    .add((UUID) row[1]));
            List<Object[]> mediaRows = bounded(entityManager.createNativeQuery("""
                            select post_id, id, media_type, mime_type, byte_size, width, height,
                                   checksum, status, created_at, uploaded_at, deleted_at, purged_at
                            from media where post_id in (:postIds) order by post_id, created_at, id
                            """)
                    .setParameter("postIds", postIds)
                    .setMaxResults(MAX_MEDIA + 1)
                    .getResultList(), MAX_MEDIA, "media records");
            mediaRows.forEach(row -> mediaByPost
                    .computeIfAbsent((UUID) row[0], ignored -> new ArrayList<>())
                    .add(new ExportMedia(
                            (UUID) row[1], (String) row[2], (String) row[3], ((Number) row[4]).longValue(),
                            (Integer) row[5], (Integer) row[6], (String) row[7], (String) row[8],
                            (Instant) row[9], (Instant) row[10], (Instant) row[11], (Instant) row[12])));
        }
        var posts = postRows.stream().map(row -> {
            var postId = (UUID) row[0];
            return new ExportPost(
                    postId, (String) row[1], (String) row[2], (Instant) row[3], (String) row[4],
                    (Instant) row[5], (Instant) row[6], ((Number) row[7]).longValue(),
                    List.copyOf(petIdsByPost.getOrDefault(postId, List.of())),
                    List.copyOf(mediaByPost.getOrDefault(postId, List.of())));
        }).toList();

        List<Object[]> reactionRows = bounded(entityManager.createNativeQuery("""
                        select id, post_id, type, created_at, updated_at
                        from reactions where user_id = :actorId
                        order by created_at, id
                        """)
                .setParameter("actorId", actorId)
                .setMaxResults(MAX_REACTIONS + 1)
                .getResultList(), MAX_REACTIONS, "reactions");
        var reactions = reactionRows.stream().map(row -> new ExportReaction(
                (UUID) row[0], (UUID) row[1], (String) row[2], (Instant) row[3], (Instant) row[4]))
                .toList();

        return new UserExport(
                "pawket-user-export-v1",
                Instant.now(),
                new ExportUser(user.id(), user.displayName(), user.avatarMediaId(), user.createdAt(), user.updatedAt()),
                pets,
                posts,
                reactions);
    }

    private static <T> List<T> bounded(List<T> rows, int limit, String resource) {
        if (rows.size() > limit) {
            throw ApiException.conflict(
                    "EXPORT_TOO_LARGE",
                    "The export contains too many " + resource + "; contact Pawket support for a full export.");
        }
        return rows;
    }

    public record UserExport(
            String format,
            Instant exportedAt,
            ExportUser user,
            List<ExportPet> pets,
            List<ExportPost> authoredPosts,
            List<ExportReaction> reactions) {}

    public record ExportUser(UUID id, String displayName, UUID avatarMediaId, Instant createdAt, Instant updatedAt) {}

    public record ExportPet(
            UUID id,
            String name,
            String species,
            UUID avatarMediaId,
            LocalDate birthDate,
            boolean estimatedBirth,
            String gender,
            String breed,
            LocalDate adoptionDate,
            String bio,
            String status,
            Instant createdAt,
            Instant updatedAt,
            long version,
            String membershipRole,
            Instant joinedAt) {}

    public record ExportPost(
            UUID id,
            String caption,
            String visibility,
            Instant capturedAt,
            String status,
            Instant createdAt,
            Instant updatedAt,
            long version,
            List<UUID> petIds,
            List<ExportMedia> media) {}

    public record ExportMedia(
            UUID id,
            String type,
            String mimeType,
            long byteSize,
            Integer width,
            Integer height,
            String checksum,
            String status,
            Instant createdAt,
            Instant uploadedAt,
            Instant deletedAt,
            Instant purgedAt) {}

    public record ExportReaction(UUID id, UUID postId, String type, Instant createdAt, Instant updatedAt) {}
}
