CREATE TABLE idempotency_records (
    id UUID PRIMARY KEY,
    actor_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    operation VARCHAR(120) NOT NULL,
    idempotency_key VARCHAR(200) NOT NULL,
    request_hash VARCHAR(64) NOT NULL,
    response_json JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_idempotency_actor_operation_key
        UNIQUE (actor_user_id, operation, idempotency_key)
);

CREATE INDEX ix_idempotency_records_created_at ON idempotency_records(created_at);
