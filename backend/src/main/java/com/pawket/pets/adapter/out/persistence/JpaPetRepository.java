package com.pawket.pets.adapter.out.persistence;

import com.pawket.pets.application.port.out.PetRepository;
import com.pawket.pets.domain.model.Pet;
import com.pawket.pets.domain.model.PetSpecies;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class JpaPetRepository implements PetRepository {
    private final EntityManager entityManager;

    public JpaPetRepository(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    @Override
    public List<Pet> findAccessibleByUserId(UUID userId) {
        return entityManager.createQuery("""
                        select p from PetEntity p
                        where p.status = 'ACTIVE'
                          and exists (
                            select 1 from PetMembershipEntity m
                            where m.petId = p.id and m.userId = :userId and m.status = 'ACTIVE'
                          )
                        order by p.updatedAt desc, p.id
                        """, PetEntity.class)
                .setParameter("userId", userId)
                .getResultList()
                .stream()
                .map(this::toDomain)
                .toList();
    }

    @Override
    public Optional<Pet> findAccessibleById(UUID petId, UUID userId) {
        return entityManager.createQuery("""
                        select p from PetEntity p
                        where p.id = :petId and p.status = 'ACTIVE'
                          and exists (
                            select 1 from PetMembershipEntity m
                            where m.petId = p.id and m.userId = :userId and m.status = 'ACTIVE'
                          )
                        """, PetEntity.class)
                .setParameter("petId", petId)
                .setParameter("userId", userId)
                .getResultStream()
                .findFirst()
                .map(this::toDomain);
    }

    @Override
    public Pet create(Pet pet) {
        var entity = new PetEntity();
        copy(pet, entity);
        entity.status = "ACTIVE";
        entityManager.persist(entity);
        entityManager.flush();
        return toDomain(entity);
    }

    @Override
    public Pet update(Pet pet) {
        var entity = entityManager.find(PetEntity.class, pet.id());
        copy(pet, entity);
        entityManager.flush();
        return toDomain(entity);
    }

    private void copy(Pet pet, PetEntity entity) {
        entity.id = pet.id();
        entity.name = pet.name();
        entity.species = pet.species().name();
        entity.avatarMediaId = pet.avatarMediaId();
        entity.birthDate = pet.birthDate();
        entity.estimatedBirth = pet.estimatedBirth();
        entity.gender = pet.gender();
        entity.breed = pet.breed();
        entity.adoptionDate = pet.adoptionDate();
        entity.bio = pet.bio();
        entity.createdAt = pet.createdAt();
        entity.updatedAt = pet.updatedAt();
        entity.version = pet.version();
    }

    private Pet toDomain(PetEntity entity) {
        return new Pet(
                entity.id,
                entity.name,
                PetSpecies.valueOf(entity.species),
                entity.avatarMediaId,
                entity.birthDate,
                entity.estimatedBirth,
                entity.gender,
                entity.breed,
                entity.adoptionDate,
                entity.bio,
                entity.createdAt,
                entity.updatedAt,
                entity.version);
    }
}
