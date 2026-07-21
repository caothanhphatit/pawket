package com.pawket.reactions;

import jakarta.validation.constraints.NotBlank;
import java.util.Map;

final class ReactionDtos {
    private ReactionDtos() {}

    record UpsertReactionRequest(@NotBlank String type) {}

    record ReactionResponse(Map<String, Long> counts, String currentUserReaction) {}
}
