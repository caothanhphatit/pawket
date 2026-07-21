package com.pawket.memberships.application;

import com.pawket.memberships.application.port.out.MembershipRepository;
import com.pawket.memberships.domain.model.PetMembership;
import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class MembershipQueryService {
    private final MembershipRepository memberships;

    public MembershipQueryService(MembershipRepository memberships) {
        this.memberships = memberships;
    }

    public List<PetMembership> listActiveMembers(UUID petId, UUID actorId) {
        memberships.findActiveRole(petId, actorId)
                .orElseThrow(() -> ApiException.notFound("PET_NOT_FOUND", "Pet was not found."));
        return memberships.findActiveByPetId(petId);
    }
}
