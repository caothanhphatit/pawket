ALTER TABLE media ADD COLUMN purged_at TIMESTAMPTZ;

CREATE INDEX ix_media_pending_purge
    ON media(deleted_at)
    WHERE status = 'DELETED' AND purged_at IS NULL;
