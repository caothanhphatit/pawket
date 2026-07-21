package com.pawket.memberships.domain.model;

import java.time.Instant;
import java.util.UUID;

public record PetMembership(
        UUID id,
        UUID petId,
        UUID userId,
        String displayName,
        UUID avatarMediaId,
        MembershipRole role,
        Instant joinedAt) {}
