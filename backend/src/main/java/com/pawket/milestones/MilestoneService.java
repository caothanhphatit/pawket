package com.pawket.milestones;

import com.pawket.audit.AuditService;
import com.pawket.milestones.MilestoneDtos.CreateMilestoneRequest;
import com.pawket.milestones.MilestoneDtos.MilestoneResponse;
import com.pawket.posts.authorization.PetAuthorization;
import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@ApplicationScoped
public class MilestoneService {
    private static final Set<String> TYPES = Set.of("BIRTHDAY", "HOME_DAY", "FIRST_TRIP", "CUSTOM");

    private final EntityManager entityManager;
    private final PetAuthorization authorization;
    private final AuditService auditService;
    private final Clock clock;

    public MilestoneService(
            EntityManager entityManager,
            PetAuthorization authorization,
            AuditService auditService,
            Clock clock) {
        this.entityManager = entityManager;
        this.authorization = authorization;
        this.auditService = auditService;
        this.clock = clock;
    }

    public List<MilestoneResponse> list(UUID actorId, UUID petId) {
        authorization.requireActiveMember(actorId, petId);
        return entityManager.createQuery("""
                        select m from MilestoneEntity m
                        where m.petId = :petId
                        order by m.occurredOn desc, m.createdAt desc, m.id desc
                        """, MilestoneEntity.class)
                .setParameter("petId", petId)
                .getResultList()
                .stream()
                .map(MilestoneResponse::from)
                .toList();
    }

    @Transactional
    public MilestoneResponse create(UUID actorId, UUID petId, CreateMilestoneRequest request) {
        authorization.requireContributor(actorId, petId);
        var type = request.type().strip().toUpperCase(Locale.ROOT);
        if (!TYPES.contains(type)) {
            throw ApiException.badRequest("INVALID_MILESTONE_TYPE", "Milestone type is not supported.");
        }
        var customTitle = normalize(request.customTitle());
        if ("CUSTOM".equals(type) && customTitle == null) {
            throw ApiException.badRequest("MILESTONE_TITLE_REQUIRED", "A custom milestone needs a title.");
        }
        if (!"CUSTOM".equals(type)) customTitle = null;

        var entity = new MilestoneEntity();
        entity.id = UUID.randomUUID();
        entity.petId = petId;
        entity.creatorUserId = actorId;
        entity.type = type;
        entity.customTitle = customTitle;
        entity.occurredOn = request.occurredOn();
        entity.note = normalize(request.note());
        entity.createdAt = clock.instant();
        entityManager.persist(entity);
        auditService.record(actorId, "PET_MILESTONE_CREATED", "PET_MILESTONE", entity.id);
        return MilestoneResponse.from(entity);
    }

    @Transactional
    public void delete(UUID actorId, UUID petId, UUID milestoneId) {
        authorization.requireActiveMember(actorId, petId);
        var entity = entityManager.find(MilestoneEntity.class, milestoneId);
        if (entity == null || !entity.petId.equals(petId)) {
            throw ApiException.notFound("MILESTONE_NOT_FOUND", "Milestone was not found.");
        }
        if (!entity.creatorUserId.equals(actorId) && !isOwner(actorId, petId)) {
            throw ApiException.forbidden(
                    "MILESTONE_DELETE_FORBIDDEN",
                    "Only the creator or a pet owner can delete this milestone.");
        }
        entityManager.remove(entity);
        auditService.record(actorId, "PET_MILESTONE_DELETED", "PET_MILESTONE", milestoneId);
    }

    private boolean isOwner(UUID actorId, UUID petId) {
        var count = (Number) entityManager.createNativeQuery("""
                        select count(*) from pet_memberships
                        where pet_id = :petId and user_id = :actorId
                          and role = 'OWNER' and status = 'ACTIVE'
                        """, Long.class)
                .setParameter("petId", petId)
                .setParameter("actorId", actorId)
                .getSingleResult();
        return count.longValue() > 0;
    }

    private static String normalize(String value) {
        if (value == null || value.isBlank()) return null;
        return value.strip();
    }
}
