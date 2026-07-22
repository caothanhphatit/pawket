package com.pawket.media;

import com.pawket.audit.AuditService;
import com.pawket.media.MediaDtos.CreateUploadIntentRequest;
import com.pawket.media.MediaDtos.MediaResponse;
import com.pawket.media.MediaDtos.UploadIntentResponse;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.NotFoundException;
import java.time.Instant;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class MediaService {
    private static final Set<String> IMAGE_TYPES = Set.of(
            "image/jpeg", "image/png", "image/webp", "image/heic", "image/heif");
    private static final long MAX_IMAGE_PIXELS = 50_000_000L;

    private final EntityManager entityManager;
    private final StoragePresigner storagePresigner;
    private final AuditService auditService;

    public MediaService(
            EntityManager entityManager,
            StoragePresigner storagePresigner,
            AuditService auditService) {
        this.entityManager = entityManager;
        this.storagePresigner = storagePresigner;
        this.auditService = auditService;
    }

    @Transactional
    public UploadIntentResponse createIntent(UUID userId, CreateUploadIntentRequest request) {
        var mediaType = resolveMediaType(request.mimeType());
        validateDimensions(request.width(), request.height());
        var id = UUID.randomUUID();
        var extension = safeExtension(request.fileName());
        var storageKey = "users/%s/%s/%s%s".formatted(
                userId, Instant.now().toString().substring(0, 10), id, extension);
        var entity = new MediaEntity();
        entity.id = id;
        entity.ownerUserId = userId;
        entity.storageKey = storageKey;
        entity.mediaType = mediaType;
        entity.mimeType = request.mimeType().toLowerCase(Locale.ROOT);
        entity.byteSize = request.byteSize();
        entity.width = request.width();
        entity.height = request.height();
        entity.checksum = request.checksum();
        entity.status = "PENDING_UPLOAD";
        entity.createdAt = Instant.now();
        entityManager.persist(entity);

        var upload = storagePresigner.create(storageKey, entity.mimeType);
        auditService.record(userId, "MEDIA_UPLOAD_REQUESTED", "MEDIA", id);
        return new UploadIntentResponse(
                id, storageKey, upload.url(), "PUT", upload.headers(), Instant.now().plus(upload.ttl()));
    }

    @Transactional
    public MediaResponse complete(UUID userId, UUID mediaId) {
        var entity = findOwned(userId, mediaId);
        if (!"IMAGE".equals(entity.mediaType) || !IMAGE_TYPES.contains(entity.mimeType.toLowerCase(Locale.ROOT))) {
            throw new BadRequestException("Only image uploads can be completed");
        }
        if (!"PENDING_UPLOAD".equals(entity.status) && !"UPLOADED".equals(entity.status)) {
            throw new BadRequestException("Media cannot be completed from status " + entity.status);
        }
        var uploaded = storagePresigner.uploadedObject(entity.storageKey);
        if (uploaded == null) {
            throw new BadRequestException("Media object has not been uploaded");
        }
        if (uploaded.size() != entity.byteSize) {
            throw new BadRequestException("Uploaded media size does not match upload intent");
        }
        if (!entity.mimeType.equalsIgnoreCase(uploaded.contentType())) {
            throw new BadRequestException("Uploaded media type does not match upload intent");
        }
        entity.status = "READY";
        entity.uploadedAt = Instant.now();
        auditService.record(userId, "MEDIA_UPLOAD_COMPLETED", "MEDIA", entity.id);
        return response(entity);
    }

    public MediaResponse response(MediaEntity entity) {
        return new MediaResponse(
                entity.id,
                entity.mediaType,
                entity.mimeType,
                entity.byteSize,
                entity.width,
                entity.height,
                entity.status,
                "/api/v1/media/" + entity.id + "/content");
    }

    MediaEntity findOwned(UUID userId, UUID id) {
        var entity = entityManager.find(MediaEntity.class, id);
        if (entity == null || !entity.ownerUserId.equals(userId) || "DELETED".equals(entity.status)) {
            throw new NotFoundException("Media not found");
        }
        return entity;
    }

    public String contentUrl(UUID userId, UUID id) {
        var entity = entityManager.find(MediaEntity.class, id);
        if (entity == null || !"READY".equals(entity.status)) throw new NotFoundException("Media not found");
        if (!entity.ownerUserId.equals(userId)) {
            if (entity.postId == null) throw new NotFoundException("Media not found");
            var access = (Number) entityManager.createNativeQuery("""
                            select count(*) from posts p
                            where p.id = :postId and p.status = 'PUBLISHED' and p.visibility <> 'PRIVATE'
                              and exists (
                                select 1 from post_pets pp
                                join pet_memberships pm on pm.pet_id = pp.pet_id
                                where pp.post_id = p.id and pm.user_id = :userId and pm.status = 'ACTIVE'
                              )
                            """, Long.class)
                    .setParameter("postId", entity.postId)
                    .setParameter("userId", userId)
                    .getSingleResult();
            if (access.longValue() == 0) throw new NotFoundException("Media not found");
        }
        return storagePresigner.downloadUrl(entity.storageKey);
    }

    public String signedDownloadUrl(String storageKey) {
        return storagePresigner.downloadUrl(storageKey);
    }

    private static String resolveMediaType(String mimeType) {
        var normalized = mimeType.toLowerCase(Locale.ROOT);
        if (IMAGE_TYPES.contains(normalized)) return "IMAGE";
        throw new BadRequestException("Only JPEG, PNG, WebP, HEIC, or HEIF images are supported");
    }

    private static void validateDimensions(Integer width, Integer height) {
        if ((width == null) != (height == null)) {
            throw new BadRequestException("Image width and height must be provided together");
        }
        if (width != null && (long) width * height > MAX_IMAGE_PIXELS) {
            throw new BadRequestException("Image dimensions are too large");
        }
    }

    private static String safeExtension(String fileName) {
        var index = fileName.lastIndexOf('.');
        if (index < 0) return "";
        var extension = fileName.substring(index).toLowerCase(Locale.ROOT);
        return extension.matches("\\.[a-z0-9]{1,8}") ? extension : "";
    }
}
