package com.pawket.milestones;

import com.pawket.milestones.MilestoneDtos.CreateMilestoneRequest;
import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.UUID;

@Path("/api/v1/pets/{petId}/milestones")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class MilestoneResource {
    private final MilestoneService milestones;
    private final CurrentActorProvider currentActor;

    public MilestoneResource(MilestoneService milestones, CurrentActorProvider currentActor) {
        this.milestones = milestones;
        this.currentActor = currentActor;
    }

    @GET
    public Object list(@PathParam("petId") UUID petId) {
        return new DataResponse<>(milestones.list(currentActor.userId(), petId));
    }

    @POST
    public Response create(
            @PathParam("petId") UUID petId,
            @Valid CreateMilestoneRequest request) {
        return Response.status(Response.Status.CREATED)
                .entity(new DataResponse<>(milestones.create(currentActor.userId(), petId, request)))
                .build();
    }

    @DELETE
    @Path("/{milestoneId}")
    public void delete(
            @PathParam("petId") UUID petId,
            @PathParam("milestoneId") UUID milestoneId) {
        milestones.delete(currentActor.userId(), petId, milestoneId);
    }
}
