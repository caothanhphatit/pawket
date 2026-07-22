package com.pawket.safety;

import com.pawket.audit.AuditService;
import com.pawket.posts.authorization.PetAuthorization;
import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class ReportService {
    private static final Set<String> TARGETS = Set.of("POST", "COMMENT");
    private static final Set<String> REASONS = Set.of("SPAM", "HARASSMENT", "PRIVACY", "INAPPROPRIATE", "OTHER");

    private final EntityManager entityManager;
    private final PetAuthorization authorization;
    private final AuditService auditService;
    private final Set<UUID> adminIds;

    public ReportService(
            EntityManager entityManager,
            PetAuthorization authorization,
            AuditService auditService,
            @ConfigProperty(name = "pawket.admin.user-ids") Optional<String> configuredAdminIds) {
        this.entityManager = entityManager;
        this.authorization = authorization;
        this.auditService = auditService;
        this.adminIds = Arrays.stream(configuredAdminIds.orElse("").split(","))
                .map(String::strip).filter(value -> !value.isEmpty()).map(UUID::fromString).collect(java.util.stream.Collectors.toSet());
    }

    @Transactional
    public ReportResponse create(UUID actorId, CreateReportRequest request) {
        var targetType = request.targetType().strip().toUpperCase(Locale.ROOT);
        var reason = request.reason().strip().toUpperCase(Locale.ROOT);
        if (!TARGETS.contains(targetType)) throw ApiException.badRequest("INVALID_REPORT_TARGET", "Report target is not supported.");
        if (!REASONS.contains(reason)) throw ApiException.badRequest("INVALID_REPORT_REASON", "Report reason is not supported.");
        requireTargetAccess(actorId, targetType, request.targetId());
        var id = UUID.randomUUID();
        var now = Instant.now();
        entityManager.createNativeQuery("""
                        insert into content_reports (
                            id, reporter_user_id, target_type, target_id, reason, details, status, created_at, updated_at
                        ) values (:id, :actorId, :targetType, :targetId, :reason, :details, 'PENDING', :now, :now)
                        on conflict (reporter_user_id, target_type, target_id) do update
                        set reason = excluded.reason, details = excluded.details, updated_at = excluded.updated_at
                        returning id
                        """, UUID.class)
                .setParameter("id", id).setParameter("actorId", actorId)
                .setParameter("targetType", targetType).setParameter("targetId", request.targetId())
                .setParameter("reason", reason).setParameter("details", normalize(request.details()))
                .setParameter("now", now).getSingleResult();
        auditService.record(actorId, "CONTENT_REPORTED", targetType, request.targetId());
        return findMine(actorId, targetType, request.targetId());
    }

    public List<ReportResponse> listMine(UUID actorId) {
        return query("where reporter_user_id = :actorId order by created_at desc", actorId);
    }

    public List<ReportResponse> moderationQueue(UUID actorId) {
        if (!adminIds.contains(actorId)) throw ApiException.forbidden("ADMIN_REQUIRED", "Administrator access is required.");
        return query("where status = 'PENDING' order by created_at", null);
    }

    private ReportResponse findMine(UUID actorId, String targetType, UUID targetId) {
        return query("where reporter_user_id = :actorId and target_type = :targetType and target_id = :targetId", actorId,
                targetType, targetId).getFirst();
    }

    private void requireTargetAccess(UUID actorId, String targetType, UUID targetId) {
        if ("POST".equals(targetType)) {
            authorization.requirePostAccess(actorId, targetId);
            return;
        }
        @SuppressWarnings("unchecked")
        List<UUID> postIds = entityManager.createNativeQuery("""
                        select post_id from comments
                        where id = :commentId and status = 'ACTIVE'
                        """, UUID.class)
                .setParameter("commentId", targetId)
                .getResultList();
        if (postIds.isEmpty()) {
            throw ApiException.notFound("COMMENT_NOT_FOUND", "Comment was not found.");
        }
        authorization.requirePostAccess(actorId, postIds.getFirst());
    }

    @SuppressWarnings("unchecked")
    private List<ReportResponse> query(String clause, UUID actorId, Object... target) {
        var query = entityManager.createNativeQuery("""
                        select id, reporter_user_id, target_type, target_id, reason, details, status, created_at, updated_at
                        from content_reports
                        """ + clause);
        if (actorId != null) query.setParameter("actorId", actorId);
        if (target.length == 2) query.setParameter("targetType", target[0]).setParameter("targetId", target[1]);
        List<Object[]> rows = query.getResultList();
        return rows.stream().map(row -> new ReportResponse(
                (UUID) row[0], (UUID) row[1], (String) row[2], (UUID) row[3], (String) row[4],
                (String) row[5], (String) row[6], (Instant) row[7], (Instant) row[8])).toList();
    }

    private static String normalize(String value) { return value == null || value.isBlank() ? null : value.strip(); }

    public record CreateReportRequest(String targetType, UUID targetId, String reason, String details) {}
    public record ReportResponse(UUID id, UUID reporterUserId, String targetType, UUID targetId, String reason,
                                 String details, String status, Instant createdAt, Instant updatedAt) {}
}
