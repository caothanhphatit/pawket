package com.pawket.notifications;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class NotificationDtos {
    private NotificationDtos() {}

    record NotificationActor(UUID id, String displayName) {}

    record NotificationResponse(
            UUID id,
            String type,
            String title,
            String body,
            NotificationActor actor,
            UUID postId,
            UUID petId,
            UUID commentId,
            UUID invitationId,
            Instant createdAt,
            Instant readAt) {}

    record NotificationPage(List<NotificationResponse> data, PageMeta page) {}

    record PageMeta(String nextCursor, boolean hasMore) {}

    record UnreadCountResponse(long count) {}

    record MarkAllReadResponse(int updated) {}
}
