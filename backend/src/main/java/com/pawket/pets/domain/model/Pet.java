package com.pawket.pets.domain.model;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record Pet(
        UUID id,
        String name,
        PetSpecies species,
        UUID avatarMediaId,
        LocalDate birthDate,
        boolean estimatedBirth,
        String gender,
        String breed,
        LocalDate adoptionDate,
        String bio,
        Instant createdAt,
        Instant updatedAt,
        long version) {}
