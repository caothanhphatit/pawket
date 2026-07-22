package com.pawket.reactions;

import jakarta.validation.constraints.NotBlank;
import java.util.Map;
import java.util.UUID;

final class ReactionDtos {
    private ReactionDtos() {}

    record UpsertReactionRequest(@NotBlank String type) {}

    record ReactionResponse(Map<String, Long> counts, String currentUserReaction) {}

    record ReactionPersonResponse(UUID userId, String displayName, UUID avatarMediaId, String type) {}
}
