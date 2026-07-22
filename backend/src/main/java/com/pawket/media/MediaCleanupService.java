package com.pawket.media;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class MediaCleanupService {
    private final EntityManager entityManager;
    private final StoragePresigner storage;
    private final Duration pendingRetention;
    private final Duration readyRetention;
    private final Duration deletedRetention;

    public MediaCleanupService(
            EntityManager entityManager,
            StoragePresigner storage,
            @ConfigProperty(name = "pawket.media.cleanup.pending-retention") Duration pendingRetention,
            @ConfigProperty(name = "pawket.media.cleanup.ready-retention") Duration readyRetention,
            @ConfigProperty(name = "pawket.media.cleanup.deleted-retention") Duration deletedRetention) {
        this.entityManager = entityManager;
        this.storage = storage;
        this.pendingRetention = pendingRetention;
        this.readyRetention = readyRetention;
        this.deletedRetention = deletedRetention;
    }

    @Transactional
    @SuppressWarnings("unchecked")
    public int cleanup() {
        var now = Instant.now();
        List<Object[]> rows = entityManager.createNativeQuery("""
                        select id, storage_key
                        from media
                        where (
                            post_id is null and (
                                (status = 'PENDING_UPLOAD' and created_at < :pendingBefore)
                                or (status = 'READY' and coalesce(uploaded_at, created_at) < :readyBefore)
                            )
                        ) or (
                            status = 'DELETED' and purged_at is null and deleted_at < :deletedBefore
                        )
                        order by created_at, id
                        limit 100
                        for update skip locked
                        """)
                .setParameter("pendingBefore", now.minus(pendingRetention))
                .setParameter("readyBefore", now.minus(readyRetention))
                .setParameter("deletedBefore", now.minus(deletedRetention))
                .getResultList();
        for (var row : rows) {
            var mediaId = (UUID) row[0];
            storage.delete((String) row[1]);
            entityManager.createNativeQuery("""
                            update media
                            set status = 'DELETED', deleted_at = coalesce(deleted_at, :now), purged_at = :now
                            where id = :mediaId
                            """)
                    .setParameter("now", now)
                    .setParameter("mediaId", mediaId)
                    .executeUpdate();
        }
        return rows.size();
    }
}
