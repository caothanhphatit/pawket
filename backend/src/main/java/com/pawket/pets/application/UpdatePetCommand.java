package com.pawket.pets.application;

import com.pawket.pets.domain.model.PetSpecies;
import java.time.LocalDate;
import java.util.UUID;

public record UpdatePetCommand(
        String name,
        PetSpecies species,
        UUID avatarMediaId,
        LocalDate birthDate,
        Boolean estimatedBirth,
        String gender,
        String breed,
        LocalDate adoptionDate,
        String bio,
        Long expectedVersion) {}
