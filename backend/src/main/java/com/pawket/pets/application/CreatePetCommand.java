package com.pawket.pets.application;

import com.pawket.pets.domain.model.PetSpecies;
import java.time.LocalDate;
import java.util.UUID;

public record CreatePetCommand(
        String name,
        PetSpecies species,
        UUID avatarMediaId,
        LocalDate birthDate,
        boolean estimatedBirth,
        String gender,
        String breed,
        LocalDate adoptionDate,
        String bio) {}
