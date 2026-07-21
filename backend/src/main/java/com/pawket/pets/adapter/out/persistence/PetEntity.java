package com.pawket.pets.adapter.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "pets")
class PetEntity {
    @Id
    UUID id;

    @Column(nullable = false, length = 80)
    String name;

    @Column(nullable = false, length = 16)
    String species;

    @Column(name = "avatar_media_id")
    UUID avatarMediaId;

    @Column(name = "birth_date")
    LocalDate birthDate;

    @Column(name = "estimated_birth", nullable = false)
    boolean estimatedBirth;

    @Column(length = 24)
    String gender;

    @Column(length = 120)
    String breed;

    @Column(name = "adoption_date")
    LocalDate adoptionDate;

    @Column(length = 1000)
    String bio;

    @Column(nullable = false, length = 32)
    String status;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;

    @Version
    long version;
}
