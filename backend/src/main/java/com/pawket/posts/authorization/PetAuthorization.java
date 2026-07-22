package com.pawket.posts.authorization;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.ws.rs.ForbiddenException;
import java.util.UUID;

@ApplicationScoped
public class PetAuthorization {
    private final EntityManager entityManager;

    public PetAuthorization(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    public void requireActiveMember(UUID userId, UUID petId) {
        if (!hasMembership(userId, petId, false)) {
            throw new ForbiddenException("You do not have access to this pet");
        }
    }

    public void requireContributor(UUID userId, UUID petId) {
        if (!hasMembership(userId, petId, true)) {
            throw new ForbiddenException("You cannot add memories for this pet");
        }
    }

    public void requireOwner(UUID userId, UUID petId) {
        var count = (Number) entityManager.createNativeQuery("""
                        select count(*) from pet_memberships
                        where user_id = :userId and pet_id = :petId
                          and status = 'ACTIVE' and role = 'OWNER'
                        """, Long.class)
                .setParameter("userId", userId)
                .setParameter("petId", petId)
                .getSingleResult();
        if (count.longValue() == 0) {
            throw new ForbiddenException("Only an owner can perform this action");
        }
    }

    public void requirePostAccess(UUID userId, UUID postId) {
        var count = (Number) entityManager.createNativeQuery("""
                        select count(*)
                        from posts p
                        where p.id = :postId and p.status = 'PUBLISHED'
                          and (p.author_id = :userId or (p.visibility <> 'PRIVATE'
                            and not exists (
                              select 1 from user_blocks b
                              where (b.blocker_user_id = :userId and b.blocked_user_id = p.author_id)
                                 or (b.blocker_user_id = p.author_id and b.blocked_user_id = :userId)
                            ) and exists (
                            select 1 from post_pets pp
                            join pet_memberships pm on pm.pet_id = pp.pet_id
                            where pp.post_id = p.id and pm.user_id = :userId and pm.status = 'ACTIVE'
                          )))
                        """, Long.class)
                .setParameter("userId", userId)
                .setParameter("postId", postId)
                .getSingleResult();
        if (count.longValue() == 0) {
            throw new ForbiddenException("You do not have access to this post");
        }
    }

    private boolean hasMembership(UUID userId, UUID petId, boolean contributorOnly) {
        var roleClause = contributorOnly ? " and role in ('OWNER', 'CARETAKER')" : "";
        var count = (Number) entityManager.createNativeQuery("""
                        select count(*) from pet_memberships
                        where user_id = :userId and pet_id = :petId and status = 'ACTIVE'
                        """ + roleClause, Long.class)
                .setParameter("userId", userId)
                .setParameter("petId", petId)
                .getSingleResult();
        return count.longValue() > 0;
    }
}
