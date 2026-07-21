package com.pawket.pets.application.port.out;

import com.pawket.pets.domain.model.Pet;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PetRepository {
    List<Pet> findAccessibleByUserId(UUID userId);

    Optional<Pet> findAccessibleById(UUID petId, UUID userId);

    Pet create(Pet pet);

    Pet update(Pet pet);
}
