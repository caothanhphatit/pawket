package com.pawket.memberships.adapter.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "pet_memberships")
public class PetMembershipEntity {
    @Id
    UUID id;

    @Column(name = "pet_id", nullable = false)
    public UUID petId;

    @Column(name = "user_id", nullable = false)
    public UUID userId;

    @Column(nullable = false, length = 24)
    String role;

    @Column(nullable = false, length = 24)
    public String status;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    @Column(name = "joined_at")
    Instant joinedAt;

    @Column(name = "removed_at")
    Instant removedAt;
}
