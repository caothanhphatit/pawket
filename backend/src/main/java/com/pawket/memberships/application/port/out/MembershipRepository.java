package com.pawket.memberships.application.port.out;

import com.pawket.memberships.domain.model.MembershipRole;
import com.pawket.memberships.domain.model.PetMembership;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MembershipRepository {
    Optional<MembershipRole> findActiveRole(UUID petId, UUID userId);

    Optional<PetMembership> findActive(UUID petId, UUID userId);

    List<PetMembership> findActiveByPetId(UUID petId);

    void createOwner(UUID membershipId, UUID petId, UUID userId, Instant joinedAt);

    void remove(UUID membershipId, Instant removedAt);
}
