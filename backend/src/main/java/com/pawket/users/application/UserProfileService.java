package com.pawket.users.application;

import com.pawket.safety.BlockService;
import com.pawket.shared.error.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class UserProfileService {
    private final EntityManager entityManager;
    private final BlockService blocks;

    public UserProfileService(EntityManager entityManager, BlockService blocks) {
        this.entityManager = entityManager;
        this.blocks = blocks;
    }

    @SuppressWarnings("unchecked")
    public UserProfileResponse get(UUID actorId, UUID targetId) {
        if (blocks.blockedEitherDirection(actorId, targetId)) {
            throw ApiException.notFound("USER_NOT_FOUND", "User was not found.");
        }
        var userRows = entityManager.createNativeQuery("""
                        select id, display_name, avatar_media_id from users
                        where id = :targetId and status = 'ACTIVE'
                        """)
                .setParameter("targetId", targetId).getResultList();
        if (userRows.isEmpty()) throw ApiException.notFound("USER_NOT_FOUND", "User was not found.");
        Object[] user = (Object[]) userRows.getFirst();

        List<Object[]> petRows = entityManager.createNativeQuery("""
                        select p.id, p.name, p.avatar_media_id
                        from pets p
                        join pet_memberships mine on mine.pet_id = p.id and mine.user_id = :actorId and mine.status = 'ACTIVE'
                        join pet_memberships theirs on theirs.pet_id = p.id and theirs.user_id = :targetId and theirs.status = 'ACTIVE'
                        where p.status = 'ACTIVE'
                        order by p.name, p.id
                        """).setParameter("actorId", actorId).setParameter("targetId", targetId).getResultList();
        if (!actorId.equals(targetId) && petRows.isEmpty()) {
            throw ApiException.notFound("USER_NOT_FOUND", "User was not found.");
        }
        var pets = petRows.stream().map(row -> new SharedPetResponse(
                (UUID) row[0], (String) row[1], (UUID) row[2])).toList();

        List<Object[]> postRows = entityManager.createNativeQuery("""
                        select distinct p.id, p.caption, p.captured_at
                        from posts p join post_pets pp on pp.post_id = p.id
                        where p.author_id = :targetId and p.status = 'PUBLISHED'
                          and (:sameUser = true or p.visibility <> 'PRIVATE')
                          and exists (
                            select 1 from pet_memberships pm
                            where pm.pet_id = pp.pet_id and pm.user_id = :actorId and pm.status = 'ACTIVE'
                          )
                        order by p.captured_at desc
                        limit 12
                        """)
                .setParameter("targetId", targetId).setParameter("actorId", actorId)
                .setParameter("sameUser", actorId.equals(targetId)).getResultList();
        var posts = postRows.stream().map(row -> new RecentPostResponse(
                (UUID) row[0], (String) row[1], (Instant) row[2])).toList();
        return new UserProfileResponse((UUID) user[0], (String) user[1], (UUID) user[2], pets, posts);
    }

    public record UserProfileResponse(UUID id, String displayName, UUID avatarMediaId,
                                      List<SharedPetResponse> sharedPets, List<RecentPostResponse> recentPosts) {}
    public record SharedPetResponse(UUID id, String name, UUID avatarMediaId) {}
    public record RecentPostResponse(UUID id, String caption, Instant capturedAt) {}
}
