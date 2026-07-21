package com.pawket.users.domain.model;

import java.time.Instant;
import java.util.UUID;

public record User(
        UUID id,
        String displayName,
        UUID avatarMediaId,
        Instant createdAt,
        Instant updatedAt,
        long version) {}
