package com.pawket.posts;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "posts")
class PostEntity {
    @Id
    UUID id;
    @Column(name = "author_id", nullable = false)
    UUID authorId;
    String caption;
    @Column(nullable = false)
    String visibility;
    @Column(name = "captured_at", nullable = false)
    Instant capturedAt;
    @Column(nullable = false)
    String status;
    @Column(name = "created_at", nullable = false)
    Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;
    @Version
    long version;
}
