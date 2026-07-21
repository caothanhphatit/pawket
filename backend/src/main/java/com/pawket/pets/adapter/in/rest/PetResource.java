package com.pawket.pets.adapter.in.rest;

import com.pawket.pets.adapter.in.rest.PetDtos.CreatePetRequest;
import com.pawket.pets.adapter.in.rest.PetDtos.PetResponse;
import com.pawket.pets.adapter.in.rest.PetDtos.UpdatePetRequest;
import com.pawket.pets.application.CreatePetCommand;
import com.pawket.pets.application.PetCommandService;
import com.pawket.pets.application.PetQueryService;
import com.pawket.pets.application.UpdatePetCommand;
import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import com.pawket.shared.idempotency.IdempotencyService;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/pets")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class PetResource {
    private final PetQueryService queries;
    private final PetCommandService commands;
    private final CurrentActorProvider currentActor;
    private final IdempotencyService idempotency;

    public PetResource(
            PetQueryService queries,
            PetCommandService commands,
            CurrentActorProvider currentActor,
            IdempotencyService idempotency) {
        this.queries = queries;
        this.commands = commands;
        this.currentActor = currentActor;
        this.idempotency = idempotency;
    }

    @GET
    public DataResponse<List<PetResponse>> list() {
        var pets = queries.listAccessible(currentActor.userId()).stream()
                .map(PetResponse::from)
                .toList();
        return new DataResponse<>(pets);
    }

    @GET
    @Path("/{petId}")
    public Response get(@PathParam("petId") UUID petId) {
        var pet = queries.getAccessible(petId, currentActor.userId());
        return Response.ok(new DataResponse<>(PetResponse.from(pet)))
                .tag(Long.toString(pet.version()))
                .build();
    }

    @POST
    public Response create(
            @Valid CreatePetRequest request,
            @HeaderParam("Idempotency-Key") String idempotencyKey,
            @Context UriInfo uriInfo) {
        var actorId = currentActor.userId();
        var pet = idempotency.execute(actorId, "CREATE_PET", idempotencyKey, request, PetResponse.class, () -> {
            var created = commands.create(actorId, new CreatePetCommand(
                    request.name(), request.species(), request.avatarMediaId(), request.birthDate(),
                    request.estimatedBirth(), request.gender(), request.breed(), request.adoptionDate(), request.bio()));
            return PetResponse.from(created);
        });
        var location = uriInfo.getAbsolutePathBuilder().path(pet.id().toString()).build();
        return Response.created(location)
                .tag(Long.toString(pet.version()))
                .entity(new DataResponse<>(pet))
                .build();
    }

    @PATCH
    @Path("/{petId}")
    public Response update(@PathParam("petId") UUID petId, @Valid UpdatePetRequest request) {
        var pet = commands.update(petId, currentActor.userId(), new UpdatePetCommand(
                request.name(), request.species(), request.avatarMediaId(), request.birthDate(),
                request.estimatedBirth(), request.gender(), request.breed(), request.adoptionDate(), request.bio(),
                request.version()));
        return Response.ok(new DataResponse<>(PetResponse.from(pet)))
                .tag(Long.toString(pet.version()))
                .build();
    }
}
