package com.pawket.pets.adapter.in.rest;

import com.pawket.pets.domain.model.Pet;
import com.pawket.pets.domain.model.PetSpecies;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

final class PetDtos {
    private PetDtos() {}

    record CreatePetRequest(
            @NotBlank @Size(max = 80) String name,
            @NotNull PetSpecies species,
            UUID avatarMediaId,
            LocalDate birthDate,
            boolean estimatedBirth,
            @Size(max = 24) String gender,
            @Size(max = 120) String breed,
            LocalDate adoptionDate,
            @Size(max = 1000) String bio) {}

    record UpdatePetRequest(
            @Size(min = 1, max = 80) String name,
            PetSpecies species,
            UUID avatarMediaId,
            LocalDate birthDate,
            Boolean estimatedBirth,
            @Size(max = 24) String gender,
            @Size(max = 120) String breed,
            LocalDate adoptionDate,
            @Size(max = 1000) String bio,
            Long version) {}

    record PetResponse(
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
            long version) {
        static PetResponse from(Pet pet) {
            return new PetResponse(
                    pet.id(), pet.name(), pet.species(), pet.avatarMediaId(), pet.birthDate(),
                    pet.estimatedBirth(), pet.gender(), pet.breed(), pet.adoptionDate(), pet.bio(),
                    pet.createdAt(), pet.updatedAt(), pet.version());
        }
    }
}
