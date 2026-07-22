package com.pawket.posts;

import com.pawket.audit.AuditService;
import com.pawket.media.MediaDtos.MediaResponse;
import com.pawket.media.MediaService;
import com.pawket.notifications.NotificationService;
import com.pawket.posts.PostDtos.CreatePostRequest;
import com.pawket.posts.PostDtos.PostPage;
import com.pawket.posts.PostDtos.PageMeta;
import com.pawket.posts.PostDtos.PostResponse;
import com.pawket.posts.PostDtos.UpdatePostRequest;
import com.pawket.posts.authorization.PetAuthorization;
import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.NotFoundException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@ApplicationScoped
public class PostService {
    private static final Set<String> VISIBILITIES = Set.of("PRIVATE", "PET_MEMBERS");

    private final EntityManager entityManager;
    private final PetAuthorization authorization;
    private final AuditService auditService;
    private final MediaService mediaService;
    private final NotificationService notifications;

    public PostService(
            EntityManager entityManager,
            PetAuthorization authorization,
            AuditService auditService,
            MediaService mediaService,
            NotificationService notifications) {
        this.entityManager = entityManager;
        this.authorization = authorization;
        this.auditService = auditService;
        this.mediaService = mediaService;
        this.notifications = notifications;
    }

    @Transactional
    @SuppressWarnings("unchecked")
    public PostResponse create(UUID actorId, CreatePostRequest request) {
        var petIds = request.petIds().stream().distinct().toList();
        var mediaIds = request.mediaIds().stream().distinct().toList();
        petIds.forEach(petId -> authorization.requireContributor(actorId, petId));
        var visibility = request.visibility() == null ? "PET_MEMBERS" : request.visibility().toUpperCase(Locale.ROOT);
        if (!VISIBILITIES.contains(visibility)) {
            throw new BadRequestException("Invalid post visibility");
        }
        if (request.capturedAt().isAfter(Instant.now().plusSeconds(300))) {
            throw new BadRequestException("capturedAt cannot be in the future");
        }
        // Lock in stable order so concurrent publishes cannot attach the same media twice.
        List<UUID> lockedMedia = entityManager.createNativeQuery("""
                        select id from media
                        where id in (:mediaIds)
                        order by id
                        for update
                        """, UUID.class)
                .setParameter("mediaIds", mediaIds)
                .getResultList();
        if (lockedMedia.size() != mediaIds.size()) {
            throw new BadRequestException("All media must be ready, owned by the author, and unused");
        }
        var readyMedia = (Number) entityManager.createNativeQuery("""
                        select count(*) from media
                        where id in (:mediaIds) and owner_user_id = :actorId
                          and media_type = 'IMAGE' and status = 'READY' and post_id is null
                        """, Long.class)
                .setParameter("mediaIds", mediaIds)
                .setParameter("actorId", actorId)
                .getSingleResult();
        if (readyMedia.longValue() != mediaIds.size()) {
            throw new BadRequestException("All media must be ready, owned by the author, and unused");
        }

        var now = Instant.now();
        var post = new PostEntity();
        post.id = UUID.randomUUID();
        post.authorId = actorId;
        post.caption = normalizeCaption(request.caption());
        post.visibility = visibility;
        post.capturedAt = request.capturedAt();
        post.status = "PUBLISHED";
        post.createdAt = now;
        post.updatedAt = now;
        entityManager.persist(post);
        petIds.forEach(petId -> entityManager.persist(new PostPetEntity(post.id, petId)));
        var attachedMedia = entityManager.createNativeQuery("""
                        update media set post_id = :postId
                        where id in (:mediaIds) and owner_user_id = :actorId
                          and media_type = 'IMAGE' and status = 'READY' and post_id is null
                        """)
                .setParameter("postId", post.id)
                .setParameter("mediaIds", mediaIds)
                .setParameter("actorId", actorId)
                .executeUpdate();
        if (attachedMedia != mediaIds.size()) {
            throw new BadRequestException("All media must be ready, owned by the author, and unused");
        }
        entityManager.flush();
        auditService.record(actorId, "POST_CREATED", "POST", post.id);
        notifications.notifyNewPost(actorId, post.id);
        return get(actorId, post.id);
    }

    public PostResponse get(UUID actorId, UUID postId) {
        var post = entityManager.find(PostEntity.class, postId);
        if (post == null || !"PUBLISHED".equals(post.status)) throw new NotFoundException("Post not found");
        authorization.requirePostAccess(actorId, postId);
        return toResponse(actorId, post);
    }

    @Transactional
    public PostResponse update(UUID actorId, UUID postId, UpdatePostRequest request) {
        var post = requireAuthor(actorId, postId);
        if (request.version() != post.version) {
            throw ApiException.conflict("POST_VERSION_CONFLICT", "The memory was changed by another request.");
        }

        var caption = request.caption() == null ? post.caption : normalizeCaptionNode(request.caption());
        var visibility = request.visibility() == null
                ? post.visibility
                : request.visibility().toUpperCase(Locale.ROOT);
        if (!VISIBILITIES.contains(visibility)) throw new BadRequestException("Invalid post visibility");
        if (java.util.Objects.equals(caption, post.caption) && visibility.equals(post.visibility)) {
            return toResponse(actorId, post);
        }

        var now = Instant.now();
        var updated = entityManager.createNativeQuery("""
                        update posts
                        set caption = :caption, visibility = :visibility, updated_at = :now, version = version + 1
                        where id = :postId and author_id = :actorId
                          and status = 'PUBLISHED' and version = :version
                        """)
                .setParameter("caption", caption)
                .setParameter("visibility", visibility)
                .setParameter("now", now)
                .setParameter("postId", postId)
                .setParameter("actorId", actorId)
                .setParameter("version", request.version())
                .executeUpdate();
        if (updated != 1) {
            throw ApiException.conflict("POST_VERSION_CONFLICT", "The memory was changed by another request.");
        }
        auditService.record(actorId, "POST_UPDATED", "POST", postId);
        entityManager.clear();
        return toResponse(actorId, entityManager.find(PostEntity.class, postId));
    }

    @Transactional
    public void delete(UUID actorId, UUID postId) {
        var post = entityManager.find(PostEntity.class, postId);
        if (post == null) throw new NotFoundException("Post not found");
        if (!post.authorId.equals(actorId)) throw ApiException.forbidden("POST_DELETE_FORBIDDEN", "Only the author can delete this memory.");
        if ("DELETED".equals(post.status)) return;
        if (!"PUBLISHED".equals(post.status)) throw new NotFoundException("Post not found");

        var now = Instant.now();
        post.status = "DELETED";
        post.updatedAt = now;
        entityManager.createNativeQuery("""
                        update media set status = 'DELETED', deleted_at = :now
                        where post_id = :postId and status <> 'DELETED'
                        """)
                .setParameter("now", now)
                .setParameter("postId", postId)
                .executeUpdate();
        auditService.record(actorId, "POST_DELETED", "POST", postId);
        entityManager.flush();
    }

    public PostPage feed(UUID actorId, UUID petId, String cursor, int requestedLimit) {
        var limit = Math.max(1, Math.min(requestedLimit, 50));
        if (petId != null) authorization.requireActiveMember(actorId, petId);
        var boundary = decodeCursor(cursor);
        // Memberships are schema-owned by another module, so feed uses a native query below.
        return nativeFeed(actorId, petId, boundary, limit);
    }

    @SuppressWarnings("unchecked")
    private PostPage nativeFeed(UUID actorId, UUID petId, Cursor boundary, int limit) {
        var sql = new StringBuilder("""
                select distinct p.id, p.captured_at
                from posts p
                join post_pets pp on pp.post_id = p.id
                where p.status = 'PUBLISHED'
                  and (p.author_id = :actorId or (p.visibility <> 'PRIVATE' and exists (
                    select 1 from post_pets app
                    join pet_memberships pm on pm.pet_id = app.pet_id
                    where app.post_id = p.id and pm.user_id = :actorId and pm.status = 'ACTIVE'
                  )))
                  and (p.author_id = :actorId or not exists (
                    select 1 from user_blocks b
                    where (b.blocker_user_id = :actorId and b.blocked_user_id = p.author_id)
                       or (b.blocker_user_id = p.author_id and b.blocked_user_id = :actorId)
                  ))
                """);
        if (petId != null) sql.append(" and pp.pet_id = :petId");
        if (boundary != null) sql.append(" and (p.captured_at, p.id) < (:capturedAt, :postId)");
        sql.append(" order by p.captured_at desc, p.id desc");
        var query = entityManager.createNativeQuery(sql.toString())
                .setParameter("actorId", actorId)
                .setMaxResults(limit + 1);
        if (petId != null) query.setParameter("petId", petId);
        if (boundary != null) {
            query.setParameter("capturedAt", boundary.capturedAt());
            query.setParameter("postId", boundary.postId());
        }
        List<Object[]> rows = query.getResultList();
        var hasNext = rows.size() > limit;
        if (hasNext) rows = rows.subList(0, limit);
        var items = rows.stream()
                .map(row -> toResponse(actorId, entityManager.find(PostEntity.class, (UUID) row[0])))
                .toList();
        var next = hasNext && !rows.isEmpty()
                ? encodeCursor((Instant) rows.getLast()[1], (UUID) rows.getLast()[0])
                : null;
        return new PostPage(items, new PageMeta(next, hasNext));
    }

    @SuppressWarnings("unchecked")
    private PostResponse toResponse(UUID actorId, PostEntity post) {
        List<UUID> petIds = entityManager.createNativeQuery(
                        "select pet_id from post_pets where post_id = :postId order by pet_id", UUID.class)
                .setParameter("postId", post.id)
                .getResultList();
        List<Object[]> mediaRows = entityManager.createNativeQuery("""
                        select id, media_type, mime_type, byte_size, width, height, status, storage_key
                        from media where post_id = :postId and status = 'READY' order by created_at, id
                        """)
                .setParameter("postId", post.id)
                .getResultList();
        var media = mediaRows.stream().map(row -> new MediaResponse(
                (UUID) row[0], (String) row[1], (String) row[2], ((Number) row[3]).longValue(),
                (Integer) row[4], (Integer) row[5], (String) row[6],
                mediaService.signedDownloadUrl((String) row[7])
        )).toList();
        List<Object[]> reactionRows = entityManager.createNativeQuery("""
                        select type, count(*) from reactions where post_id = :postId group by type order by type
                        """)
                .setParameter("postId", post.id)
                .getResultList();
        Map<String, Long> reactions = new LinkedHashMap<>();
        reactionRows.forEach(row -> reactions.put((String) row[0], ((Number) row[1]).longValue()));
        List<?> myReactionRows = entityManager.createNativeQuery(
                        "select type from reactions where post_id = :postId and user_id = :userId", String.class)
                .setParameter("postId", post.id)
                .setParameter("userId", actorId)
                .getResultList();
        var mine = myReactionRows.isEmpty() ? null : (String) myReactionRows.getFirst();
        return new PostResponse(post.id, post.authorId, post.caption, post.visibility, post.capturedAt,
                post.createdAt, post.updatedAt, post.version, petIds, media, reactions, mine);
    }

    private PostEntity requireAuthor(UUID actorId, UUID postId) {
        var post = entityManager.find(PostEntity.class, postId);
        if (post == null || !"PUBLISHED".equals(post.status)) throw new NotFoundException("Post not found");
        if (!post.authorId.equals(actorId)) {
            throw ApiException.forbidden("POST_UPDATE_FORBIDDEN", "Only the author can edit this memory.");
        }
        return post;
    }

    private static String normalizeCaptionNode(com.fasterxml.jackson.databind.JsonNode caption) {
        if (caption.isNull()) return null;
        if (!caption.isTextual()) throw new BadRequestException("caption must be a string or null");
        var value = normalizeCaption(caption.textValue());
        if (value != null && value.length() > 2000) throw new BadRequestException("caption is too long");
        return value;
    }

    private static String normalizeCaption(String caption) {
        if (caption == null || caption.isBlank()) return null;
        return caption.strip();
    }

    private static String encodeCursor(Instant capturedAt, UUID postId) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(
                (capturedAt + "|" + postId).getBytes(StandardCharsets.UTF_8));
    }

    private static Cursor decodeCursor(String cursor) {
        if (cursor == null || cursor.isBlank()) return null;
        try {
            var decoded = new String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8).split("\\|", 2);
            return new Cursor(Instant.parse(decoded[0]), UUID.fromString(decoded[1]));
        } catch (RuntimeException exception) {
            throw new BadRequestException("Invalid cursor");
        }
    }

    private record Cursor(Instant capturedAt, UUID postId) {}
}
