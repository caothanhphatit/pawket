CREATE INDEX ix_posts_author_status ON posts(author_id, status);

CREATE INDEX ix_media_orphan_cleanup
    ON media(status, created_at)
    WHERE post_id IS NULL AND status IN ('PENDING_UPLOAD', 'READY');

CREATE INDEX ix_media_deleted_cleanup
    ON media(deleted_at)
    WHERE status = 'DELETED';
