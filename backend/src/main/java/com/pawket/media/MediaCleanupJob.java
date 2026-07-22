package com.pawket.media;

import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class MediaCleanupJob {
    private final MediaCleanupService cleanupService;

    public MediaCleanupJob(MediaCleanupService cleanupService) {
        this.cleanupService = cleanupService;
    }

    @Scheduled(
            every = "{pawket.media.cleanup.every}",
            concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    void cleanupOrphanedMedia() {
        cleanupService.cleanup();
    }
}
