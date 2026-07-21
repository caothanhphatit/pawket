package com.pawket.pets.application;

import com.pawket.pets.application.port.out.PetRepository;
import com.pawket.pets.domain.model.Pet;
import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class PetQueryService {
    private final PetRepository pets;

    public PetQueryService(PetRepository pets) {
        this.pets = pets;
    }

    public List<Pet> listAccessible(UUID actorId) {
        return pets.findAccessibleByUserId(actorId);
    }

    public Pet getAccessible(UUID petId, UUID actorId) {
        return pets.findAccessibleById(petId, actorId)
                .orElseThrow(() -> ApiException.notFound("PET_NOT_FOUND", "Pet was not found."));
    }
}
