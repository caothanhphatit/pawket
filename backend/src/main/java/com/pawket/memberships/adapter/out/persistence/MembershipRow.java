package com.pawket.memberships.adapter.out.persistence;

import java.time.Instant;
import java.util.UUID;

public record MembershipRow(
        UUID id,
        UUID petId,
        UUID userId,
        String displayName,
        UUID avatarMediaId,
        String role,
        Instant joinedAt) {}
