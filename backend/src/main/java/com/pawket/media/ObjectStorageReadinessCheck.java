package com.pawket.media;

import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Readiness;
import org.jboss.logging.Logger;

@Readiness
@ApplicationScoped
public class ObjectStorageReadinessCheck implements HealthCheck {
    private static final Logger LOG = Logger.getLogger(ObjectStorageReadinessCheck.class);

    private final StoragePresigner storage;

    public ObjectStorageReadinessCheck(StoragePresigner storage) {
        this.storage = storage;
    }

    @Override
    public HealthCheckResponse call() {
        try {
            storage.checkBucket();
            return HealthCheckResponse.named("object-storage").up().build();
        } catch (RuntimeException exception) {
            LOG.warn("Object storage readiness check failed", exception);
            return HealthCheckResponse.named("object-storage")
                    .down()
                    .withData("reason", "Object storage is unavailable")
                    .build();
        }
    }
}
