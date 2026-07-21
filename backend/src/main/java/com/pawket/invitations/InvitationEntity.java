package com.pawket.invitations;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "invitations")
class InvitationEntity {
    @Id
    UUID id;
    @Column(name = "pet_id", nullable = false)
    UUID petId;
    @Column(name = "inviter_user_id", nullable = false)
    UUID inviterUserId;
    @Column(name = "requested_role", nullable = false)
    String requestedRole;
    @Column(name = "token_hash", nullable = false, unique = true)
    String tokenHash;
    @Column(name = "expires_at", nullable = false)
    Instant expiresAt;
    @Column(name = "accepted_by_user_id")
    UUID acceptedByUserId;
    @Column(nullable = false)
    String status;
    @Column(name = "created_at", nullable = false)
    Instant createdAt;
    @Column(name = "accepted_at")
    Instant acceptedAt;
}
