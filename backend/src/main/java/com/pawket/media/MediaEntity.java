package com.pawket.media;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "media")
class MediaEntity {
    @Id
    UUID id;
    @Column(name = "owner_user_id", nullable = false)
    UUID ownerUserId;
    @Column(name = "post_id")
    UUID postId;
    @Column(name = "storage_key", nullable = false, unique = true)
    String storageKey;
    @Column(name = "media_type", nullable = false)
    String mediaType;
    @Column(name = "mime_type", nullable = false)
    String mimeType;
    @Column(name = "byte_size", nullable = false)
    long byteSize;
    Integer width;
    Integer height;
    String checksum;
    @Column(nullable = false)
    String status;
    @Column(name = "created_at", nullable = false)
    Instant createdAt;
    @Column(name = "uploaded_at")
    Instant uploadedAt;
    @Column(name = "deleted_at")
    Instant deletedAt;
}
