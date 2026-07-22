CREATE TABLE pet_milestones (
    id UUID PRIMARY KEY,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    creator_user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(32) NOT NULL,
    custom_title VARCHAR(120),
    occurred_on DATE NOT NULL,
    note VARCHAR(1000),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_pet_milestones_type
        CHECK (type IN ('BIRTHDAY', 'HOME_DAY', 'FIRST_TRIP', 'CUSTOM')),
    CONSTRAINT ck_pet_milestones_custom_title
        CHECK ((type = 'CUSTOM' AND custom_title IS NOT NULL) OR type <> 'CUSTOM')
);

CREATE INDEX ix_pet_milestones_pet_date
    ON pet_milestones(pet_id, occurred_on DESC, created_at DESC);
