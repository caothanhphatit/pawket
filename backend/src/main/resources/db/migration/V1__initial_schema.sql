CREATE TABLE users (
    id UUID PRIMARY KEY,
    display_name VARCHAR(120) NOT NULL,
    avatar_media_id UUID,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT ck_users_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'DELETION_PENDING', 'DELETED'))
);

CREATE TABLE user_identities (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    issuer VARCHAR(255) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    email VARCHAR(320),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_identities_issuer_subject UNIQUE (issuer, subject)
);

CREATE TABLE pets (
    id UUID PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    species VARCHAR(16) NOT NULL,
    avatar_media_id UUID,
    birth_date DATE,
    estimated_birth BOOLEAN NOT NULL DEFAULT false,
    gender VARCHAR(24),
    breed VARCHAR(120),
    adoption_date DATE,
    bio VARCHAR(1000),
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT ck_pets_species CHECK (species IN ('DOG', 'CAT')),
    CONSTRAINT ck_pets_status CHECK (status IN ('ACTIVE', 'ARCHIVED', 'DELETION_PENDING', 'DELETED'))
);

CREATE TABLE pet_memberships (
    id UUID PRIMARY KEY,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(24) NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    joined_at TIMESTAMPTZ,
    removed_at TIMESTAMPTZ,
    CONSTRAINT uq_pet_memberships_pet_user UNIQUE (pet_id, user_id),
    CONSTRAINT ck_pet_memberships_role CHECK (role IN ('OWNER', 'CARETAKER', 'FOLLOWER')),
    CONSTRAINT ck_pet_memberships_status CHECK (status IN ('PENDING', 'ACTIVE', 'REMOVED'))
);

CREATE INDEX ix_pet_memberships_user_status ON pet_memberships(user_id, status);
CREATE INDEX ix_pet_memberships_pet_status ON pet_memberships(pet_id, status);

CREATE TABLE posts (
    id UUID PRIMARY KEY,
    author_id UUID NOT NULL REFERENCES users(id),
    caption VARCHAR(2000),
    visibility VARCHAR(24) NOT NULL DEFAULT 'PET_MEMBERS',
    captured_at TIMESTAMPTZ NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'PUBLISHED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT ck_posts_visibility CHECK (visibility IN ('PRIVATE', 'PET_MEMBERS', 'FRIENDS')),
    CONSTRAINT ck_posts_status CHECK (status IN ('PUBLISHED', 'ARCHIVED', 'DELETED'))
);

CREATE INDEX ix_posts_captured_id ON posts(captured_at DESC, id DESC);

CREATE TABLE post_pets (
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, pet_id)
);

CREATE INDEX ix_post_pets_pet_post ON post_pets(pet_id, post_id);

CREATE TABLE media (
    id UUID PRIMARY KEY,
    owner_user_id UUID NOT NULL REFERENCES users(id),
    post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    storage_key VARCHAR(500) NOT NULL UNIQUE,
    media_type VARCHAR(16) NOT NULL,
    mime_type VARCHAR(120) NOT NULL,
    byte_size BIGINT NOT NULL,
    width INTEGER,
    height INTEGER,
    checksum VARCHAR(128),
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING_UPLOAD',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    uploaded_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT ck_media_type CHECK (media_type IN ('IMAGE', 'VIDEO')),
    CONSTRAINT ck_media_status CHECK (status IN ('PENDING_UPLOAD', 'UPLOADED', 'READY', 'REJECTED', 'DELETED')),
    CONSTRAINT ck_media_byte_size CHECK (byte_size > 0)
);

CREATE INDEX ix_media_post ON media(post_id);

CREATE TABLE reactions (
    id UUID PRIMARY KEY,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_reactions_post_user UNIQUE (post_id, user_id)
);

CREATE TABLE invitations (
    id UUID PRIMARY KEY,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    inviter_user_id UUID NOT NULL REFERENCES users(id),
    requested_role VARCHAR(24) NOT NULL,
    token_hash VARCHAR(128) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    accepted_by_user_id UUID REFERENCES users(id),
    status VARCHAR(24) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    accepted_at TIMESTAMPTZ,
    CONSTRAINT ck_invitations_role CHECK (requested_role IN ('CARETAKER', 'FOLLOWER')),
    CONSTRAINT ck_invitations_status CHECK (status IN ('PENDING', 'ACCEPTED', 'REVOKED', 'EXPIRED'))
);

CREATE TABLE audit_events (
    id UUID PRIMARY KEY,
    actor_user_id UUID REFERENCES users(id),
    action VARCHAR(120) NOT NULL,
    resource_type VARCHAR(80) NOT NULL,
    resource_id UUID,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    correlation_id VARCHAR(120),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO users (id, display_name)
VALUES ('00000000-0000-0000-0000-000000000001', 'Local Developer');

