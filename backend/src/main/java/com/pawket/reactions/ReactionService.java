package com.pawket.reactions;

import com.pawket.audit.AuditService;
import com.pawket.posts.authorization.PetAuthorization;
import com.pawket.reactions.ReactionDtos.ReactionResponse;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import java.util.Locale;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@ApplicationScoped
public class ReactionService {
    private static final Set<String> TYPES = Set.of("LIKE", "LOVE", "PAW", "LAUGH", "WOW", "SAD");

    private final EntityManager entityManager;
    private final PetAuthorization authorization;
    private final AuditService auditService;

    public ReactionService(EntityManager entityManager, PetAuthorization authorization, AuditService auditService) {
        this.entityManager = entityManager;
        this.authorization = authorization;
        this.auditService = auditService;
    }

    @Transactional
    public ReactionResponse upsert(UUID actorId, UUID postId, String rawType) {
        authorization.requirePostAccess(actorId, postId);
        var type = rawType.toUpperCase(Locale.ROOT);
        if (!TYPES.contains(type)) throw new BadRequestException("Invalid reaction type");
        entityManager.createNativeQuery("""
                        insert into reactions (id, post_id, user_id, type)
                        values (:id, :postId, :userId, :type)
                        on conflict (post_id, user_id) do update
                        set type = excluded.type, updated_at = now()
                        """)
                .setParameter("id", UUID.randomUUID())
                .setParameter("postId", postId)
                .setParameter("userId", actorId)
                .setParameter("type", type)
                .executeUpdate();
        auditService.record(actorId, "REACTION_UPSERTED", "POST", postId);
        return summary(actorId, postId);
    }

    @Transactional
    public ReactionResponse delete(UUID actorId, UUID postId) {
        authorization.requirePostAccess(actorId, postId);
        entityManager.createNativeQuery("delete from reactions where post_id = :postId and user_id = :userId")
                .setParameter("postId", postId)
                .setParameter("userId", actorId)
                .executeUpdate();
        auditService.record(actorId, "REACTION_DELETED", "POST", postId);
        return summary(actorId, postId);
    }

    @SuppressWarnings("unchecked")
    private ReactionResponse summary(UUID actorId, UUID postId) {
        List<Object[]> rows = entityManager.createNativeQuery(
                        "select type, count(*) from reactions where post_id = :postId group by type order by type")
                .setParameter("postId", postId)
                .getResultList();
        Map<String, Long> counts = new LinkedHashMap<>();
        rows.forEach(row -> counts.put((String) row[0], ((Number) row[1]).longValue()));
        List<String> mine = entityManager.createNativeQuery(
                        "select type from reactions where post_id = :postId and user_id = :userId", String.class)
                .setParameter("postId", postId)
                .setParameter("userId", actorId)
                .getResultList();
        return new ReactionResponse(counts, mine.isEmpty() ? null : mine.getFirst());
    }
}
