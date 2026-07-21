package com.pawket.memberships.adapter.out.persistence;

import com.pawket.memberships.application.port.out.MembershipRepository;
import com.pawket.memberships.domain.model.MembershipRole;
import com.pawket.memberships.domain.model.PetMembership;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class JpaMembershipRepository implements MembershipRepository {
    private final EntityManager entityManager;

    public JpaMembershipRepository(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    @Override
    public Optional<MembershipRole> findActiveRole(UUID petId, UUID userId) {
        return entityManager.createQuery("""
                        select m.role from PetMembershipEntity m
                        where m.petId = :petId and m.userId = :userId and m.status = 'ACTIVE'
                        """, String.class)
                .setParameter("petId", petId)
                .setParameter("userId", userId)
                .getResultStream()
                .findFirst()
                .map(MembershipRole::valueOf);
    }

    @Override
    public Optional<PetMembership> findActive(UUID petId, UUID userId) {
        return entityManager.createQuery("""
                        select new com.pawket.memberships.adapter.out.persistence.MembershipRow(
                            m.id, m.petId, m.userId, u.displayName, u.avatarMediaId, m.role, m.joinedAt)
                        from PetMembershipEntity m, UserEntity u
                        where m.petId = :petId and m.userId = :userId
                          and m.status = 'ACTIVE' and u.id = m.userId
                        """, MembershipRow.class)
                .setParameter("petId", petId)
                .setParameter("userId", userId)
                .getResultStream()
                .findFirst()
                .map(row -> new PetMembership(
                        row.id(), row.petId(), row.userId(), row.displayName(), row.avatarMediaId(),
                        MembershipRole.valueOf(row.role()), row.joinedAt()));
    }

    @Override
    public List<PetMembership> findActiveByPetId(UUID petId) {
        return entityManager.createQuery("""
                        select new com.pawket.memberships.adapter.out.persistence.MembershipRow(
                            m.id, m.petId, m.userId, u.displayName, u.avatarMediaId, m.role, m.joinedAt)
                        from PetMembershipEntity m, UserEntity u
                        where m.petId = :petId and m.status = 'ACTIVE' and u.id = m.userId
                        order by case m.role when 'OWNER' then 0 when 'CARETAKER' then 1 else 2 end,
                                 m.joinedAt, m.id
                        """, MembershipRow.class)
                .setParameter("petId", petId)
                .getResultList()
                .stream()
                .map(row -> new PetMembership(
                        row.id(), row.petId(), row.userId(), row.displayName(), row.avatarMediaId(),
                        MembershipRole.valueOf(row.role()), row.joinedAt()))
                .toList();
    }

    @Override
    public void createOwner(UUID membershipId, UUID petId, UUID userId, Instant joinedAt) {
        var entity = new PetMembershipEntity();
        entity.id = membershipId;
        entity.petId = petId;
        entity.userId = userId;
        entity.role = MembershipRole.OWNER.name();
        entity.status = "ACTIVE";
        entity.createdAt = joinedAt;
        entity.joinedAt = joinedAt;
        entityManager.persist(entity);
    }

    @Override
    public void remove(UUID membershipId, Instant removedAt) {
        entityManager.createQuery("""
                        update PetMembershipEntity m
                        set m.status = 'REMOVED', m.removedAt = :removedAt
                        where m.id = :membershipId and m.status = 'ACTIVE'
                        """)
                .setParameter("membershipId", membershipId)
                .setParameter("removedAt", removedAt)
                .executeUpdate();
    }
}
