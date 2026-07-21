package com.pawket.media;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public final class MediaDtos {
    private MediaDtos() {}

    public record CreateUploadIntentRequest(
            @NotBlank String fileName,
            @NotBlank String mimeType,
            @Positive @Max(104_857_600) long byteSize,
            @Min(1) Integer width,
            @Min(1) Integer height,
            String checksum) {}

    public record UploadIntentResponse(
            UUID mediaId,
            String storageKey,
            String uploadUrl,
            String method,
            Map<String, String> headers,
            Instant expiresAt) {}

    public record CompleteUploadRequest(@NotNull UUID mediaId) {}

    public record MediaResponse(
            UUID id,
            String type,
            String mimeType,
            long byteSize,
            Integer width,
            Integer height,
            String status,
            String url) {}
}
