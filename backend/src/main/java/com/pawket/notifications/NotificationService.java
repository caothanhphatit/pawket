package com.pawket.notifications;

import com.pawket.notifications.NotificationDtos.MarkAllReadResponse;
import com.pawket.notifications.NotificationDtos.NotificationActor;
import com.pawket.notifications.NotificationDtos.NotificationPage;
import com.pawket.notifications.NotificationDtos.NotificationResponse;
import com.pawket.notifications.NotificationDtos.PageMeta;
import com.pawket.notifications.NotificationDtos.UnreadCountResponse;
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
public class NotificationService {
    private final EntityManager entityManager;

    public NotificationService(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    public void notifyNewPost(UUID actorId, UUID postId) {
        entityManager.createNativeQuery("""
                        insert into user_notifications (
                            id, user_id, type, actor_user_id, post_id, dedupe_key, created_at
                        )
                        select gen_random_uuid(), recipients.user_id, 'NEW_POST', :actorId, :postId,
                               'NEW_POST:' || cast(:postId as text), now()
                        from (
                            select distinct pm.user_id
                            from posts p
                            join post_pets pp on pp.post_id = p.id
                            join pet_memberships pm on pm.pet_id = pp.pet_id
                            where p.id = :postId and p.status = 'PUBLISHED'
                              and p.visibility = 'PET_MEMBERS'
                              and pm.status = 'ACTIVE' and pm.user_id <> :actorId
                              and not exists (
                                  select 1 from user_blocks b
                                  where (b.blocker_user_id = pm.user_id and b.blocked_user_id = :actorId)
                                     or (b.blocker_user_id = :actorId and b.blocked_user_id = pm.user_id)
                              )
                        ) recipients
                        on conflict (user_id, dedupe_key) do nothing
                        """)
                .setParameter("actorId", actorId)
                .setParameter("postId", postId)
                .executeUpdate();
    }

    public void notifyReaction(UUID actorId, UUID postId) {
        notifyPostAuthor("REACTION", actorId, postId, null, "REACTION:" + postId + ":" + actorId);
    }

    public void notifyComment(UUID actorId, UUID postId, UUID commentId) {
        notifyPostAuthor("COMMENT", actorId, postId, commentId, "COMMENT:" + commentId);
    }

    public void notifyInvitationAccepted(UUID actorId, UUID inviterId, UUID invitationId, UUID petId) {
        if (actorId.equals(inviterId)) return;
        entityManager.createNativeQuery("""
                        insert into user_notifications (
                            id, user_id, type, actor_user_id, pet_id, invitation_id, dedupe_key, created_at
                        ) values (
                            :id, :userId, 'INVITATION_ACCEPTED', :actorId, :petId, :invitationId, :dedupeKey, now()
                        ) on conflict (user_id, dedupe_key) do nothing
                        """)
                .setParameter("id", UUID.randomUUID())
                .setParameter("userId", inviterId)
                .setParameter("actorId", actorId)
                .setParameter("petId", petId)
                .setParameter("invitationId", invitationId)
                .setParameter("dedupeKey", "INVITATION_ACCEPTED:" + invitationId)
                .executeUpdate();
    }

    @Transactional
    public NotificationResponse markRead(UUID actorId, UUID notificationId) {
        var updated = entityManager.createNativeQuery("""
                        update user_notifications set read_at = coalesce(read_at, now())
                        where id = :id and user_id = :userId
                        """)
                .setParameter("id", notificationId)
                .setParameter("userId", actorId)
                .executeUpdate();
        if (updated == 0) throw ApiException.notFound("NOTIFICATION_NOT_FOUND", "Notification was not found.");
        return find(actorId, notificationId);
    }

    @Transactional
    public MarkAllReadResponse markAllRead(UUID actorId) {
        var updated = entityManager.createNativeQuery("""
                        update user_notifications set read_at = now()
                        where user_id = :userId and read_at is null
                        """)
                .setParameter("userId", actorId)
                .executeUpdate();
        return new MarkAllReadResponse(updated);
    }

    public UnreadCountResponse unreadCount(UUID actorId) {
        var count = (Number) entityManager.createNativeQuery("""
                        select count(*) from user_notifications
                        where user_id = :userId and read_at is null
                        """, Long.class)
                .setParameter("userId", actorId)
                .getSingleResult();
        return new UnreadCountResponse(count.longValue());
    }

    public NotificationPage list(UUID actorId, boolean unreadOnly, String cursor, int requestedLimit) {
        var limit = Math.max(1, Math.min(requestedLimit, 100));
        var boundary = decodeCursor(cursor);
        var sql = new StringBuilder("""
                select n.id, n.type, n.actor_user_id, u.display_name, n.post_id, n.pet_id,
                       n.comment_id, n.invitation_id, n.created_at, n.read_at
                from user_notifications n
                left join users u on u.id = n.actor_user_id
                where n.user_id = :userId
                """);
        if (unreadOnly) sql.append(" and n.read_at is null");
        if (boundary != null) sql.append(" and (n.created_at, n.id) < (:createdAt, :notificationId)");
        sql.append(" order by n.created_at desc, n.id desc");
        var query = entityManager.createNativeQuery(sql.toString())
                .setParameter("userId", actorId)
                .setMaxResults(limit + 1);
        if (boundary != null) {
            query.setParameter("createdAt", boundary.createdAt());
            query.setParameter("notificationId", boundary.id());
        }
        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();
        var hasMore = rows.size() > limit;
        if (hasMore) rows = rows.subList(0, limit);
        var items = rows.stream().map(this::response).toList();
        var nextCursor = hasMore && !rows.isEmpty()
                ? encodeCursor((Instant) rows.getLast()[8], (UUID) rows.getLast()[0])
                : null;
        return new NotificationPage(items, new PageMeta(nextCursor, hasMore));
    }

    private void notifyPostAuthor(String type, UUID actorId, UUID postId, UUID commentId, String dedupeKey) {
        entityManager.createNativeQuery("""
                        insert into user_notifications (
                            id, user_id, type, actor_user_id, post_id, comment_id, dedupe_key, created_at
                        )
                        select :id, p.author_id, :type, :actorId, p.id, :commentId, :dedupeKey, now()
                        from posts p
                        where p.id = :postId and p.status = 'PUBLISHED' and p.author_id <> :actorId
                        on conflict (user_id, dedupe_key) do nothing
                        """)
                .setParameter("id", UUID.randomUUID())
                .setParameter("type", type)
                .setParameter("actorId", actorId)
                .setParameter("postId", postId)
                .setParameter("commentId", commentId)
                .setParameter("dedupeKey", dedupeKey)
                .executeUpdate();
    }

    private NotificationResponse find(UUID actorId, UUID id) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = entityManager.createNativeQuery("""
                        select n.id, n.type, n.actor_user_id, u.display_name, n.post_id, n.pet_id,
                               n.comment_id, n.invitation_id, n.created_at, n.read_at
                        from user_notifications n
                        left join users u on u.id = n.actor_user_id
                        where n.id = :id and n.user_id = :userId
                        """)
                .setParameter("id", id)
                .setParameter("userId", actorId)
                .getResultList();
        if (rows.isEmpty()) throw ApiException.notFound("NOTIFICATION_NOT_FOUND", "Notification was not found.");
        return response(rows.getFirst());
    }

    private NotificationResponse response(Object[] row) {
        var type = (String) row[1];
        var actorId = (UUID) row[2];
        var actor = actorId == null ? null : new NotificationActor(actorId, (String) row[3]);
        var actorName = actor == null || actor.displayName() == null ? "A Pawket member" : actor.displayName();
        return new NotificationResponse(
                (UUID) row[0], type, title(type), body(type, actorName), actor, (UUID) row[4], (UUID) row[5],
                (UUID) row[6], (UUID) row[7], (Instant) row[8], (Instant) row[9]);
    }

    private static String title(String type) {
        return switch (type) {
            case "NEW_POST" -> "New memory";
            case "REACTION" -> "New reaction";
            case "COMMENT" -> "New comment";
            case "INVITATION_ACCEPTED" -> "Invitation accepted";
            default -> "Pawket update";
        };
    }

    private static String body(String type, String actorName) {
        return switch (type) {
            case "NEW_POST" -> actorName + " shared a new pet memory.";
            case "REACTION" -> actorName + " reacted to your memory.";
            case "COMMENT" -> actorName + " commented on your memory.";
            case "INVITATION_ACCEPTED" -> actorName + " joined your pet's circle.";
            default -> "There is an update in Pawket.";
        };
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
            throw ApiException.badRequest("INVALID_CURSOR", "Notification cursor is invalid.");
        }
    }

    private record Cursor(Instant createdAt, UUID id) {}
}
