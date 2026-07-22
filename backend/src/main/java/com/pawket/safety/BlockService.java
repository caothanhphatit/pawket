package com.pawket.safety;

import com.pawket.audit.AuditService;
import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class BlockService {
    private final EntityManager entityManager;
    private final AuditService auditService;

    public BlockService(EntityManager entityManager, AuditService auditService) {
        this.entityManager = entityManager;
        this.auditService = auditService;
    }

    public boolean blockedEitherDirection(UUID first, UUID second) {
        if (first.equals(second)) return false;
        var count = (Number) entityManager.createNativeQuery("""
                        select count(*) from user_blocks
                        where (blocker_user_id = :first and blocked_user_id = :second)
                           or (blocker_user_id = :second and blocked_user_id = :first)
                        """, Long.class)
                .setParameter("first", first)
                .setParameter("second", second)
                .getSingleResult();
        return count.longValue() > 0;
    }

    @SuppressWarnings("unchecked")
    public List<BlockedUserResponse> list(UUID actorId) {
        List<Object[]> rows = entityManager.createNativeQuery("""
                        select u.id, u.display_name, u.avatar_media_id, b.created_at
                        from user_blocks b join users u on u.id = b.blocked_user_id
                        where b.blocker_user_id = :actorId
                        order by b.created_at desc
                        """)
                .setParameter("actorId", actorId)
                .getResultList();
        return rows.stream().map(row -> new BlockedUserResponse(
                (UUID) row[0], (String) row[1], (UUID) row[2], (Instant) row[3])).toList();
    }

    @Transactional
    public void block(UUID actorId, UUID targetId) {
        if (actorId.equals(targetId)) throw ApiException.badRequest("CANNOT_BLOCK_SELF", "You cannot block yourself.");
        var exists = (Number) entityManager.createNativeQuery(
                        "select count(*) from users where id = :id and status = 'ACTIVE'", Long.class)
                .setParameter("id", targetId).getSingleResult();
        if (exists.longValue() == 0) throw ApiException.notFound("USER_NOT_FOUND", "User was not found.");
        entityManager.createNativeQuery("""
                        insert into user_blocks (blocker_user_id, blocked_user_id)
                        values (:actorId, :targetId) on conflict do nothing
                        """)
                .setParameter("actorId", actorId).setParameter("targetId", targetId).executeUpdate();
        auditService.record(actorId, "USER_BLOCKED", "USER", targetId);
    }

    @Transactional
    public void unblock(UUID actorId, UUID targetId) {
        entityManager.createNativeQuery("delete from user_blocks where blocker_user_id = :actorId and blocked_user_id = :targetId")
                .setParameter("actorId", actorId).setParameter("targetId", targetId).executeUpdate();
        auditService.record(actorId, "USER_UNBLOCKED", "USER", targetId);
    }

    public record BlockedUserResponse(UUID userId, String displayName, UUID avatarMediaId, Instant blockedAt) {}
}
