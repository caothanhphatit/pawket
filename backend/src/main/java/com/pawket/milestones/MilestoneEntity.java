package com.pawket.milestones;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "pet_milestones")
class MilestoneEntity {
    @Id
    UUID id;
    @Column(name = "pet_id", nullable = false)
    UUID petId;
    @Column(name = "creator_user_id", nullable = false)
    UUID creatorUserId;
    @Column(nullable = false, length = 32)
    String type;
    @Column(name = "custom_title", length = 120)
    String customTitle;
    @Column(name = "occurred_on", nullable = false)
    LocalDate occurredOn;
    @Column(length = 1000)
    String note;
    @Column(name = "created_at", nullable = false)
    Instant createdAt;
}
