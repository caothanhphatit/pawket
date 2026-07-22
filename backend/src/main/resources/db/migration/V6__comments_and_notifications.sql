CREATE TABLE comments (
    id UUID PRIMARY KEY,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body VARCHAR(500),
    status VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT ck_comments_status CHECK (status IN ('ACTIVE', 'DELETED')),
    CONSTRAINT ck_comments_body CHECK (
        (status = 'ACTIVE' AND body IS NOT NULL AND length(trim(body)) > 0)
        OR (status = 'DELETED' AND body IS NULL)
    )
);

CREATE INDEX ix_comments_post_order ON comments(post_id, created_at, id) WHERE status = 'ACTIVE';

CREATE TABLE user_notifications (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(40) NOT NULL,
    actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    pet_id UUID REFERENCES pets(id) ON DELETE SET NULL,
    comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    invitation_id UUID REFERENCES invitations(id) ON DELETE CASCADE,
    dedupe_key VARCHAR(160) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at TIMESTAMPTZ,
    CONSTRAINT ck_user_notifications_type CHECK (
        type IN ('NEW_POST', 'REACTION', 'COMMENT', 'INVITATION_ACCEPTED')
    ),
    CONSTRAINT uq_user_notifications_dedupe UNIQUE (user_id, dedupe_key)
);

CREATE INDEX ix_user_notifications_inbox ON user_notifications(user_id, created_at DESC, id DESC);
CREATE INDEX ix_user_notifications_unread ON user_notifications(user_id, created_at DESC) WHERE read_at IS NULL;
