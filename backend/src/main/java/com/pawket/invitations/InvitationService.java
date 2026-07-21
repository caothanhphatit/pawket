package com.pawket.invitations;

import com.pawket.audit.AuditService;
import com.pawket.invitations.InvitationDtos.InvitationAcceptedResponse;
import com.pawket.invitations.InvitationDtos.InvitationCreatedResponse;
import com.pawket.invitations.InvitationDtos.InvitationPreviewResponse;
import com.pawket.posts.authorization.PetAuthorization;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.NotFoundException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@ApplicationScoped
public class InvitationService {
    private static final Set<String> ROLES = Set.of("CARETAKER", "FOLLOWER");

    private final EntityManager entityManager;
    private final PetAuthorization authorization;
    private final AuditService auditService;

    public InvitationService(EntityManager entityManager, PetAuthorization authorization, AuditService auditService) {
        this.entityManager = entityManager;
        this.authorization = authorization;
        this.auditService = auditService;
    }

    @Transactional
    public InvitationCreatedResponse create(UUID actorId, UUID petId, String rawRole, Integer expiresInDays) {
        authorization.requireOwner(actorId, petId);
        var role = rawRole.toUpperCase(Locale.ROOT);
        if (!ROLES.contains(role)) throw new BadRequestException("Invitations support CARETAKER or FOLLOWER roles");
        var tokenBytes = new byte[32];
        SecureRandomHolder.INSTANCE.nextBytes(tokenBytes);
        var token = Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
        var now = Instant.now();
        var invitation = new InvitationEntity();
        invitation.id = UUID.randomUUID();
        invitation.petId = petId;
        invitation.inviterUserId = actorId;
        invitation.requestedRole = role;
        invitation.tokenHash = hash(token);
        invitation.expiresAt = now.plus(expiresInDays == null ? 7 : expiresInDays, ChronoUnit.DAYS);
        invitation.status = "PENDING";
        invitation.createdAt = now;
        entityManager.persist(invitation);
        auditService.record(actorId, "INVITATION_CREATED", "INVITATION", invitation.id);
        return new InvitationCreatedResponse(invitation.id, token, role, invitation.expiresAt);
    }

    @Transactional
    public InvitationPreviewResponse preview(String token) {
        var invitation = findByToken(token);
        refreshExpiry(invitation);
        Object[] row = (Object[]) entityManager.createNativeQuery("""
                        select p.name, u.display_name from pets p, users u
                        where p.id = :petId and u.id = :inviterId
                        """)
                .setParameter("petId", invitation.petId)
                .setParameter("inviterId", invitation.inviterUserId)
                .getSingleResult();
        return new InvitationPreviewResponse(invitation.id, invitation.petId, (String) row[0], (String) row[1],
                invitation.requestedRole, invitation.status, invitation.expiresAt);
    }

    @Transactional
    public InvitationAcceptedResponse accept(UUID actorId, String token) {
        var invitation = findByToken(token, true);
        refreshExpiry(invitation);
        if (!"PENDING".equals(invitation.status)) {
            throw new BadRequestException("Invitation is no longer available");
        }
        if (invitation.inviterUserId.equals(actorId)) {
            throw new BadRequestException("You cannot accept your own invitation");
        }
        var now = Instant.now();
        entityManager.createNativeQuery("""
                        insert into pet_memberships (id, pet_id, user_id, role, status, created_at, joined_at)
                        values (:id, :petId, :userId, :role, 'ACTIVE', :now, :now)
                        on conflict (pet_id, user_id) do update
                        set role = case when pet_memberships.role = 'OWNER' then 'OWNER' else excluded.role end,
                            status = 'ACTIVE', joined_at = coalesce(pet_memberships.joined_at, excluded.joined_at),
                            removed_at = null
                        """)
                .setParameter("id", UUID.randomUUID())
                .setParameter("petId", invitation.petId)
                .setParameter("userId", actorId)
                .setParameter("role", invitation.requestedRole)
                .setParameter("now", now)
                .executeUpdate();
        invitation.status = "ACCEPTED";
        invitation.acceptedByUserId = actorId;
        invitation.acceptedAt = now;
        auditService.record(actorId, "INVITATION_ACCEPTED", "INVITATION", invitation.id);
        return new InvitationAcceptedResponse(invitation.petId, invitation.requestedRole, now);
    }

    private InvitationEntity findByToken(String token) {
        return findByToken(token, false);
    }

    private InvitationEntity findByToken(String token, boolean lockForAcceptance) {
        if (token == null || token.isBlank()) throw new NotFoundException("Invitation not found");
        var query = entityManager.createQuery(
                        "select i from InvitationEntity i where i.tokenHash = :hash", InvitationEntity.class)
                .setParameter("hash", hash(token));
        if (lockForAcceptance) query.setLockMode(LockModeType.PESSIMISTIC_WRITE);
        return query
                .getResultStream()
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Invitation not found"));
    }

    private static void refreshExpiry(InvitationEntity invitation) {
        if ("PENDING".equals(invitation.status) && !invitation.expiresAt.isAfter(Instant.now())) {
            invitation.status = "EXPIRED";
        }
    }

    private static String hash(String token) {
        try {
            var bytes = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(bytes);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException(exception);
        }
    }

    private static final class SecureRandomHolder {
        private static final java.security.SecureRandom INSTANCE = new java.security.SecureRandom();
    }
}
