package com.pawket.comments;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class CommentDtos {
    private CommentDtos() {}

    record CreateCommentRequest(@NotBlank @Size(max = 500) String body) {}

    record UpdateCommentRequest(
            @NotBlank @Size(max = 500) String body,
            @NotNull Long version) {}

    record CommentAuthor(UUID id, String displayName, UUID avatarMediaId) {}

    record CommentResponse(
            UUID id,
            UUID postId,
            CommentAuthor author,
            String body,
            Instant createdAt,
            Instant updatedAt,
            long version) {}

    record CommentPage(List<CommentResponse> data, PageMeta page) {}

    record PageMeta(String nextCursor, boolean hasMore) {}
}
