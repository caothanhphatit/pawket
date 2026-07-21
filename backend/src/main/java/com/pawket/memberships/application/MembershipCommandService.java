package com.pawket.memberships.application;

import com.pawket.audit.AuditService;
import com.pawket.memberships.application.port.out.MembershipRepository;
import com.pawket.memberships.domain.model.MembershipRole;
import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.UUID;

@ApplicationScoped
public class MembershipCommandService {
    private final MembershipRepository memberships;
    private final AuditService auditService;
    private final Clock clock;

    public MembershipCommandService(
            MembershipRepository memberships,
            AuditService auditService,
            Clock clock) {
        this.memberships = memberships;
        this.auditService = auditService;
        this.clock = clock;
    }

    @Transactional
    public void remove(UUID petId, UUID targetUserId, UUID actorId) {
        var actorRole = memberships.findActiveRole(petId, actorId)
                .orElseThrow(() -> ApiException.notFound("PET_NOT_FOUND", "Pet was not found."));
        if (actorRole != MembershipRole.OWNER) {
            throw ApiException.forbidden("MEMBER_REMOVE_FORBIDDEN", "Only an owner can remove pet members.");
        }

        var target = memberships.findActive(petId, targetUserId)
                .orElseThrow(() -> ApiException.notFound("MEMBER_NOT_FOUND", "Pet member was not found."));
        if (target.role() == MembershipRole.OWNER) {
            throw ApiException.badRequest(
                    "OWNER_REMOVAL_NOT_ALLOWED",
                    "An owner cannot be removed without an ownership transfer.");
        }

        memberships.remove(target.id(), clock.instant());
        auditService.record(actorId, "PET_MEMBER_REMOVED", "PET_MEMBERSHIP", target.id());
    }
}
