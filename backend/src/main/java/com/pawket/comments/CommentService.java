package com.pawket.comments;

import com.pawket.audit.AuditService;
import com.pawket.comments.CommentDtos.CommentAuthor;
import com.pawket.comments.CommentDtos.CommentPage;
import com.pawket.comments.CommentDtos.CommentResponse;
import com.pawket.comments.CommentDtos.PageMeta;
import com.pawket.notifications.NotificationService;
import com.pawket.posts.authorization.PetAuthorization;
import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class CommentService {
    private final EntityManager entityManager;
    private final PetAuthorization authorization;
    private final AuditService auditService;
    private final NotificationService notifications;

    public CommentService(
            EntityManager entityManager,
            PetAuthorization authorization,
            AuditService auditService,
            NotificationService notifications) {
        this.entityManager = entityManager;
        this.authorization = authorization;
        this.auditService = auditService;
        this.notifications = notifications;
    }

    @Transactional
    public CommentResponse create(UUID actorId, UUID postId, String rawBody) {
        authorization.requirePostAccess(actorId, postId);
        var body = normalize(rawBody);
        var id = UUID.randomUUID();
        var now = Instant.now();
        entityManager.createNativeQuery("""
                        insert into comments (id, post_id, author_id, body, status, created_at, updated_at)
                        values (:id, :postId, :authorId, :body, 'ACTIVE', :now, :now)
                        """)
                .setParameter("id", id)
                .setParameter("postId", postId)
                .setParameter("authorId", actorId)
                .setParameter("body", body)
                .setParameter("now", now)
                .executeUpdate();
        auditService.record(actorId, "COMMENT_CREATED", "COMMENT", id);
        notifications.notifyComment(actorId, postId, id);
        return findResponse(id);
    }

    public CommentPage list(UUID actorId, UUID postId, String cursor, int requestedLimit) {
        authorization.requirePostAccess(actorId, postId);
        var limit = Math.max(1, Math.min(requestedLimit, 100));
        var boundary = decodeCursor(cursor);
        var sql = new StringBuilder("""
                select c.id, c.post_id, c.author_id, u.display_name, u.avatar_media_id,
                       c.body, c.created_at, c.updated_at, c.version
                from comments c join users u on u.id = c.author_id
                where c.post_id = :postId and c.status = 'ACTIVE'
                """);
        if (boundary != null) sql.append(" and (c.created_at, c.id) > (:createdAt, :commentId)");
        sql.append(" order by c.created_at, c.id");
        var query = entityManager.createNativeQuery(sql.toString())
                .setParameter("postId", postId)
                .setMaxResults(limit + 1);
        if (boundary != null) {
            query.setParameter("createdAt", boundary.createdAt());
            query.setParameter("commentId", boundary.id());
        }
        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();
        var hasMore = rows.size() > limit;
        if (hasMore) rows = rows.subList(0, limit);
        var items = rows.stream().map(CommentService::response).toList();
        var nextCursor = hasMore && !rows.isEmpty()
                ? encodeCursor((Instant) rows.getLast()[6], (UUID) rows.getLast()[0])
                : null;
        return new CommentPage(items, new PageMeta(nextCursor, hasMore));
    }

    @Transactional
    public CommentResponse update(UUID actorId, UUID commentId, String rawBody, long expectedVersion) {
        var row = findAuthorAndStatus(commentId);
        if (!actorId.equals(row.authorId())) {
            throw ApiException.forbidden("COMMENT_UPDATE_FORBIDDEN", "Only the comment author can edit it.");
        }
        if (!"ACTIVE".equals(row.status())) throw ApiException.notFound("COMMENT_NOT_FOUND", "Comment was not found.");
        authorization.requirePostAccess(actorId, row.postId());
        var updated = entityManager.createNativeQuery("""
                        update comments set body = :body, updated_at = now(), version = version + 1
                        where id = :id and author_id = :actorId and status = 'ACTIVE' and version = :version
                        """)
                .setParameter("body", normalize(rawBody))
                .setParameter("id", commentId)
                .setParameter("actorId", actorId)
                .setParameter("version", expectedVersion)
                .executeUpdate();
        if (updated != 1) {
            throw ApiException.conflict("COMMENT_VERSION_CONFLICT", "The comment was changed by another request.");
        }
        auditService.record(actorId, "COMMENT_UPDATED", "COMMENT", commentId);
        return findResponse(commentId);
    }

    @Transactional
    public void delete(UUID actorId, UUID commentId) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = entityManager.createNativeQuery("""
                        select c.author_id, p.author_id, c.status,
                               exists (
                                   select 1 from post_pets pp
                                   join pet_memberships pm on pm.pet_id = pp.pet_id
                                   where pp.post_id = c.post_id and pm.user_id = :actorId
                                     and pm.status = 'ACTIVE' and pm.role = 'OWNER'
                               )
                        from comments c join posts p on p.id = c.post_id
                        where c.id = :commentId
                        """)
                .setParameter("actorId", actorId)
                .setParameter("commentId", commentId)
                .getResultList();
        if (rows.isEmpty()) throw ApiException.notFound("COMMENT_NOT_FOUND", "Comment was not found.");
        var row = rows.getFirst();
        var allowed = actorId.equals(row[0]) || actorId.equals(row[1]) || (Boolean) row[3];
        if (!allowed) {
            throw ApiException.forbidden("COMMENT_DELETE_FORBIDDEN", "You cannot delete this comment.");
        }
        if ("DELETED".equals(row[2])) return;
        entityManager.createNativeQuery("""
                        update comments
                        set body = null, status = 'DELETED', updated_at = now(), version = version + 1
                        where id = :commentId and status = 'ACTIVE'
                        """)
                .setParameter("commentId", commentId)
                .executeUpdate();
        auditService.record(actorId, "COMMENT_DELETED", "COMMENT", commentId);
    }

    private CommentResponse findResponse(UUID commentId) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = entityManager.createNativeQuery("""
                        select c.id, c.post_id, c.author_id, u.display_name, u.avatar_media_id,
                               c.body, c.created_at, c.updated_at, c.version
                        from comments c join users u on u.id = c.author_id
                        where c.id = :id and c.status = 'ACTIVE'
                        """)
                .setParameter("id", commentId)
                .getResultList();
        if (rows.isEmpty()) throw ApiException.notFound("COMMENT_NOT_FOUND", "Comment was not found.");
        return response(rows.getFirst());
    }

    private AuthorStatus findAuthorAndStatus(UUID commentId) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = entityManager.createNativeQuery(
                        "select author_id, post_id, status from comments where id = :id")
                .setParameter("id", commentId)
                .getResultList();
        if (rows.isEmpty()) throw ApiException.notFound("COMMENT_NOT_FOUND", "Comment was not found.");
        return new AuthorStatus((UUID) rows.getFirst()[0], (UUID) rows.getFirst()[1], (String) rows.getFirst()[2]);
    }

    private static CommentResponse response(Object[] row) {
        return new CommentResponse(
                (UUID) row[0], (UUID) row[1],
                new CommentAuthor((UUID) row[2], (String) row[3], (UUID) row[4]),
                (String) row[5], (Instant) row[6], (Instant) row[7], ((Number) row[8]).longValue());
    }

    private static String normalize(String body) {
        var normalized = body == null ? "" : body.strip();
        if (normalized.isEmpty() || normalized.length() > 500) {
            throw ApiException.badRequest("INVALID_COMMENT", "Comment must contain 1 to 500 characters.");
        }
        return normalized;
    }

    private static String encodeCursor(Instant createdAt, UUID id) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(
                (createdAt + "|" + id).getBytes(StandardCharsets.UTF_8));
    }

    private static Cursor decodeCursor(String cursor) {
        if (cursor == null || cursor.isBlank()) return null;
        try {
            var parts = new String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8).split("\\|", 2);
            return new Cursor(Instant.parse(parts[0]), UUID.fromString(parts[1]));
        } catch (RuntimeException exception) {
            throw ApiException.badRequest("INVALID_CURSOR", "Comment cursor is invalid.");
        }
    }

    private record Cursor(Instant createdAt, UUID id) {}

    private record AuthorStatus(UUID authorId, UUID postId, String status) {}
}
