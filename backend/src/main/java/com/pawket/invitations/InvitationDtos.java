package com.pawket.invitations;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

final class InvitationDtos {
    private InvitationDtos() {}

    record CreateInvitationRequest(@NotNull UUID petId, @NotBlank String role, @Min(1) @Max(30) Integer expiresInDays) {}

    record InvitationCreatedResponse(UUID id, String token, String role, Instant expiresAt) {}

    record InvitationPreviewResponse(
            UUID id,
            UUID petId,
            String petName,
            String inviterName,
            String role,
            String status,
            Instant expiresAt) {}

    record AcceptInvitationRequest(@NotBlank String token) {}

    record InvitationAcceptedResponse(UUID petId, String role, Instant acceptedAt) {}
}
