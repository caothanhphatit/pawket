package com.pawket.milestones;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

final class MilestoneDtos {
    private MilestoneDtos() {}

    record CreateMilestoneRequest(
            @NotBlank String type,
            @Size(max = 120) String customTitle,
            @NotNull LocalDate occurredOn,
            @Size(max = 1000) String note) {}

    record MilestoneResponse(
            UUID id,
            UUID petId,
            UUID creatorUserId,
            String type,
            String customTitle,
            LocalDate occurredOn,
            String note,
            Instant createdAt) {
        static MilestoneResponse from(MilestoneEntity entity) {
            return new MilestoneResponse(
                    entity.id,
                    entity.petId,
                    entity.creatorUserId,
                    entity.type,
                    entity.customTitle,
                    entity.occurredOn,
                    entity.note,
                    entity.createdAt);
        }
    }
}
