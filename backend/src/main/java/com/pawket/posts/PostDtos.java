package com.pawket.posts;

import com.fasterxml.jackson.databind.JsonNode;
import com.pawket.media.MediaDtos.MediaResponse;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

final class PostDtos {
    private PostDtos() {}

    record CreatePostRequest(
            @Size(max = 2000) String caption,
            @NotNull Instant capturedAt,
            String visibility,
            @NotEmpty List<UUID> petIds,
            @NotEmpty List<UUID> mediaIds) {}

    record UpdatePostRequest(
            JsonNode caption,
            String visibility,
            @NotNull Long version) {}

    record PostResponse(
            UUID id,
            UUID authorId,
            String caption,
            String visibility,
            Instant capturedAt,
            Instant createdAt,
            Instant updatedAt,
            long version,
            List<UUID> petIds,
            List<MediaResponse> media,
            Map<String, Long> reactions,
            String myReaction) {}

    record PostPage(List<PostResponse> data, PageMeta page) {}

    record PageMeta(String nextCursor, boolean hasMore) {}
}
