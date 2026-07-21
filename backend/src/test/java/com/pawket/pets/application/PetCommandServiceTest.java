package com.pawket.pets.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.pawket.memberships.application.port.out.MembershipRepository;
import com.pawket.memberships.domain.model.MembershipRole;
import com.pawket.memberships.domain.model.PetMembership;
import com.pawket.pets.application.port.out.PetRepository;
import com.pawket.pets.domain.model.Pet;
import com.pawket.pets.domain.model.PetSpecies;
import com.pawket.shared.error.ApiException;
import com.pawket.users.application.port.out.UserRepository;
import com.pawket.users.domain.model.User;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class PetCommandServiceTest {
    private static final UUID ACTOR_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");
    private static final Instant NOW = Instant.parse("2026-07-18T10:00:00Z");

    @Test
    void createsPetAndOwnerMembershipTogether() {
        var petRepository = new InMemoryPetRepository();
        var membershipRepository = new InMemoryMembershipRepository();
        var service = service(petRepository, membershipRepository);

        var pet = service.create(ACTOR_ID, new CreatePetCommand(
                "  Mit  ", PetSpecies.DOG, null, null, false, null, null, null, null));

        assertEquals("Mit", pet.name());
        assertEquals(MembershipRole.OWNER, membershipRepository.role);
        assertEquals(pet.id(), membershipRepository.petId);
        assertEquals(ACTOR_ID, membershipRepository.userId);
    }

    @Test
    void followerCannotUpdatePet() {
        var petRepository = new InMemoryPetRepository();
        var membershipRepository = new InMemoryMembershipRepository();
        var service = service(petRepository, membershipRepository);
        var pet = service.create(ACTOR_ID, new CreatePetCommand(
                "Mit", PetSpecies.DOG, null, null, false, null, null, null, null));
        membershipRepository.role = MembershipRole.FOLLOWER;

        var failure = assertThrows(ApiException.class, () -> service.update(
                pet.id(), ACTOR_ID, new UpdatePetCommand(
                        "Milo", null, null, null, null, null, null, null, null, pet.version())));

        assertEquals("PET_UPDATE_FORBIDDEN", failure.code());
        assertEquals("Mit", petRepository.pet.name());
    }

    @Test
    void rejectsAStaleProfileVersion() {
        var petRepository = new InMemoryPetRepository();
        var membershipRepository = new InMemoryMembershipRepository();
        var service = service(petRepository, membershipRepository);
        var pet = service.create(ACTOR_ID, new CreatePetCommand(
                "Mit", PetSpecies.DOG, null, null, false, null, null, null, null));

        var failure = assertThrows(ApiException.class, () -> service.update(
                pet.id(), ACTOR_ID, new UpdatePetCommand(
                        "Milo", null, null, null, null, null, null, null, null, pet.version() + 1)));

        assertEquals("PET_VERSION_CONFLICT", failure.code());
        assertEquals("Mit", petRepository.pet.name());
    }

    private PetCommandService service(
            InMemoryPetRepository petRepository,
            InMemoryMembershipRepository membershipRepository) {
        UserRepository users = userId -> Optional.of(new User(userId, "Local Developer", null, NOW, NOW, 0));
        return new PetCommandService(
                petRepository,
                membershipRepository,
                users,
                Clock.fixed(NOW, ZoneOffset.UTC));
    }

    private static final class InMemoryPetRepository implements PetRepository {
        private Pet pet;

        @Override
        public List<Pet> findAccessibleByUserId(UUID userId) {
            return pet == null ? List.of() : List.of(pet);
        }

        @Override
        public Optional<Pet> findAccessibleById(UUID petId, UUID userId) {
            return pet != null && pet.id().equals(petId) ? Optional.of(pet) : Optional.empty();
        }

        @Override
        public Pet create(Pet pet) {
            this.pet = pet;
            return pet;
        }

        @Override
        public Pet update(Pet pet) {
            this.pet = pet;
            return pet;
        }
    }

    private static final class InMemoryMembershipRepository implements MembershipRepository {
        private UUID petId;
        private UUID userId;
        private MembershipRole role;

        @Override
        public Optional<MembershipRole> findActiveRole(UUID petId, UUID userId) {
            return this.petId != null && this.petId.equals(petId) && this.userId.equals(userId)
                    ? Optional.of(role)
                    : Optional.empty();
        }

        @Override
        public Optional<PetMembership> findActive(UUID petId, UUID userId) {
            return Optional.empty();
        }

        @Override
        public List<PetMembership> findActiveByPetId(UUID petId) {
            return new ArrayList<>();
        }

        @Override
        public void createOwner(UUID membershipId, UUID petId, UUID userId, Instant joinedAt) {
            this.petId = petId;
            this.userId = userId;
            this.role = MembershipRole.OWNER;
        }

        @Override
        public void remove(UUID membershipId, Instant removedAt) {}
    }
}
