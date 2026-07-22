CREATE TABLE user_blocks (
    blocker_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (blocker_user_id, blocked_user_id),
    CONSTRAINT ck_user_blocks_not_self CHECK (blocker_user_id <> blocked_user_id)
);

CREATE INDEX ix_user_blocks_blocked ON user_blocks(blocked_user_id);

CREATE TABLE content_reports (
    id UUID PRIMARY KEY,
    reporter_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(24) NOT NULL,
    target_id UUID NOT NULL,
    reason VARCHAR(40) NOT NULL,
    details VARCHAR(1000),
    status VARCHAR(24) NOT NULL DEFAULT 'PENDING',
    moderator_user_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_content_reports_target CHECK (target_type IN ('POST', 'COMMENT')),
    CONSTRAINT ck_content_reports_status CHECK (status IN ('PENDING', 'REVIEWED', 'DISMISSED', 'ACTIONED')),
    CONSTRAINT uq_content_reports_reporter_target UNIQUE (reporter_user_id, target_type, target_id)
);

CREATE INDEX ix_content_reports_status_created ON content_reports(status, created_at);
