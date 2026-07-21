package com.pawket.pets.application;

import com.pawket.memberships.application.port.out.MembershipRepository;
import com.pawket.pets.application.port.out.PetRepository;
import com.pawket.pets.domain.model.Pet;
import com.pawket.shared.error.ApiException;
import com.pawket.users.application.port.out.UserRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.time.LocalDate;
import java.util.UUID;

@ApplicationScoped
public class PetCommandService {
    private final PetRepository pets;
    private final MembershipRepository memberships;
    private final UserRepository users;
    private final Clock clock;

    public PetCommandService(
            PetRepository pets,
            MembershipRepository memberships,
            UserRepository users,
            Clock clock) {
        this.pets = pets;
        this.memberships = memberships;
        this.users = users;
        this.clock = clock;
    }

    @Transactional
    public Pet create(UUID actorId, CreatePetCommand command) {
        users.findActiveById(actorId)
                .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "Current user was not found."));
        validateDates(command.birthDate(), command.adoptionDate());
        var now = clock.instant();
        var pet = new Pet(
                UUID.randomUUID(),
                normalizeRequired(command.name(), "Pet name"),
                command.species(),
                command.avatarMediaId(),
                command.birthDate(),
                command.estimatedBirth(),
                normalizeOptional(command.gender()),
                normalizeOptional(command.breed()),
                command.adoptionDate(),
                normalizeOptional(command.bio()),
                now,
                now,
                0);
        var created = pets.create(pet);
        memberships.createOwner(UUID.randomUUID(), created.id(), actorId, now);
        return created;
    }

    @Transactional
    public Pet update(UUID petId, UUID actorId, UpdatePetCommand command) {
        var current = pets.findAccessibleById(petId, actorId)
                .orElseThrow(() -> ApiException.notFound("PET_NOT_FOUND", "Pet was not found."));
        var role = memberships.findActiveRole(petId, actorId)
                .orElseThrow(() -> ApiException.notFound("PET_NOT_FOUND", "Pet was not found."));
        if (!role.canEditPet()) {
            throw ApiException.forbidden("PET_UPDATE_FORBIDDEN", "You cannot edit this pet profile.");
        }
        if (command.expectedVersion() != null && command.expectedVersion() != current.version()) {
            throw ApiException.conflict(
                    "PET_VERSION_CONFLICT",
                    "This pet profile changed on another device. Reload it before saving again.");
        }

        var birthDate = command.birthDate() != null ? command.birthDate() : current.birthDate();
        var adoptionDate = command.adoptionDate() != null ? command.adoptionDate() : current.adoptionDate();
        validateDates(birthDate, adoptionDate);
        var updated = new Pet(
                current.id(),
                command.name() != null ? normalizeRequired(command.name(), "Pet name") : current.name(),
                command.species() != null ? command.species() : current.species(),
                command.avatarMediaId() != null ? command.avatarMediaId() : current.avatarMediaId(),
                birthDate,
                command.estimatedBirth() != null ? command.estimatedBirth() : current.estimatedBirth(),
                command.gender() != null ? normalizeOptional(command.gender()) : current.gender(),
                command.breed() != null ? normalizeOptional(command.breed()) : current.breed(),
                adoptionDate,
                command.bio() != null ? normalizeOptional(command.bio()) : current.bio(),
                current.createdAt(),
                clock.instant(),
                current.version());
        return pets.update(updated);
    }

    private void validateDates(LocalDate birthDate, LocalDate adoptionDate) {
        if (birthDate != null && birthDate.isAfter(LocalDate.now(clock))) {
            throw ApiException.badRequest("INVALID_BIRTH_DATE", "Birth date cannot be in the future.");
        }
        if (birthDate != null && adoptionDate != null && adoptionDate.isBefore(birthDate)) {
            throw ApiException.badRequest("INVALID_ADOPTION_DATE", "Home date cannot be before birth date.");
        }
    }

    private String normalizeRequired(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw ApiException.badRequest("VALIDATION_ERROR", fieldName + " is required.");
        }
        return value.trim();
    }

    private String normalizeOptional(String value) {
        if (value == null) {
            return null;
        }
        var normalized = value.trim();
        return normalized.isEmpty() ? null : normalized;
    }
}
