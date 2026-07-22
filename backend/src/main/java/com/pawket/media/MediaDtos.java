package com.pawket.media;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public final class MediaDtos {
    private MediaDtos() {}

    public record CreateUploadIntentRequest(
            @NotBlank @Size(max = 255) String fileName,
            @NotBlank @Size(max = 120) String mimeType,
            @Positive @Max(15_728_640) long byteSize,
            @Min(1) @Max(12_000) Integer width,
            @Min(1) @Max(12_000) Integer height,
            @Size(max = 128) String checksum) {}

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
