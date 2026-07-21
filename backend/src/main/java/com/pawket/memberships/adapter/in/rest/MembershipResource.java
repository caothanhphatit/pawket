package com.pawket.memberships.adapter.in.rest;

import com.pawket.memberships.adapter.in.rest.MembershipDtos.MemberResponse;
import com.pawket.memberships.application.MembershipQueryService;
import com.pawket.memberships.application.MembershipCommandService;
import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/pets/{petId}/members")
@Produces(MediaType.APPLICATION_JSON)
public class MembershipResource {
    private final MembershipQueryService queries;
    private final MembershipCommandService commands;
    private final CurrentActorProvider currentActor;

    public MembershipResource(
            MembershipQueryService queries,
            MembershipCommandService commands,
            CurrentActorProvider currentActor) {
        this.queries = queries;
        this.commands = commands;
        this.currentActor = currentActor;
    }

    @GET
    public DataResponse<List<MemberResponse>> list(@PathParam("petId") UUID petId) {
        var members = queries.listActiveMembers(petId, currentActor.userId()).stream()
                .map(MemberResponse::from)
                .toList();
        return new DataResponse<>(members);
    }

    @DELETE
    @Path("/{userId}")
    public void remove(
            @PathParam("petId") UUID petId,
            @PathParam("userId") UUID userId) {
        commands.remove(petId, userId, currentActor.userId());
    }
}
