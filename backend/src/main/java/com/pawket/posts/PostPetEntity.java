package com.pawket.posts;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "post_pets")
class PostPetEntity {
    @EmbeddedId
    PostPetId id;

    PostPetEntity() {}

    PostPetEntity(UUID postId, UUID petId) {
        this.id = new PostPetId(postId, petId);
    }

    @Embeddable
    static class PostPetId implements Serializable {
        @Column(name = "post_id")
        UUID postId;
        @Column(name = "pet_id")
        UUID petId;

        PostPetId() {}

        PostPetId(UUID postId, UUID petId) {
            this.postId = postId;
            this.petId = petId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof PostPetId that)) return false;
            return Objects.equals(postId, that.postId) && Objects.equals(petId, that.petId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(postId, petId);
        }
    }
}
