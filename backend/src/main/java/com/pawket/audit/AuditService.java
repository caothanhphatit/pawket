package com.pawket.audit;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.UUID;

@ApplicationScoped
public class AuditService {
    private final EntityManager entityManager;

    public AuditService(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    public void record(UUID actorId, String action, String resourceType, UUID resourceId) {
        entityManager.createNativeQuery("""
                        insert into audit_events (id, actor_user_id, action, resource_type, resource_id)
                        values (:id, :actorId, :action, :resourceType, :resourceId)
                        """)
                .setParameter("id", UUID.randomUUID())
                .setParameter("actorId", actorId)
                .setParameter("action", action)
                .setParameter("resourceType", resourceType)
                .setParameter("resourceId", resourceId)
                .executeUpdate();
    }
}
