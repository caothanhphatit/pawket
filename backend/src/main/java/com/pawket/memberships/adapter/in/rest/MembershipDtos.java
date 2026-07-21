package com.pawket.memberships.adapter.in.rest;

import com.pawket.memberships.domain.model.MembershipRole;
import com.pawket.memberships.domain.model.PetMembership;
import java.time.Instant;
import java.util.UUID;

final class MembershipDtos {
    private MembershipDtos() {}

    record MemberResponse(
            UUID userId,
            String displayName,
            UUID avatarMediaId,
            MembershipRole role,
            Instant joinedAt) {
        static MemberResponse from(PetMembership membership) {
            return new MemberResponse(
                    membership.userId(), membership.displayName(), membership.avatarMediaId(),
                    membership.role(), membership.joinedAt());
        }
    }
}
