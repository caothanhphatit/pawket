package com.pawket.users.adapter.out.persistence;

import com.pawket.users.application.port.out.UserRepository;
import com.pawket.users.domain.model.User;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class JpaUserRepository implements UserRepository {
    private final EntityManager entityManager;

    public JpaUserRepository(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    @Override
    public Optional<User> findActiveById(UUID userId) {
        return entityManager.createQuery("""
                        select u from UserEntity u where u.id = :userId and u.status = 'ACTIVE'
                        """, UserEntity.class)
                .setParameter("userId", userId)
                .getResultStream()
                .findFirst()
                .map(entity -> new User(
                        entity.id,
                        entity.displayName,
                        entity.avatarMediaId,
                        entity.createdAt,
                        entity.updatedAt,
                        entity.version));
    }
}
