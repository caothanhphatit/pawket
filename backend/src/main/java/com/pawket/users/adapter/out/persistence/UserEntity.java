package com.pawket.users.adapter.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "users")
public class UserEntity {
    @Id
    public UUID id;

    @Column(name = "display_name", nullable = false, length = 120)
    public String displayName;

    @Column(name = "avatar_media_id")
    public UUID avatarMediaId;

    @Column(nullable = false, length = 32)
    public String status;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    public Instant updatedAt;

    @Version
    public long version;
}
