package com.pawket.invitations;

import com.pawket.invitations.InvitationDtos.AcceptInvitationRequest;
import com.pawket.invitations.InvitationDtos.CreateInvitationRequest;
import com.pawket.shared.auth.CurrentActorProvider;
import com.pawket.shared.api.DataResponse;
import com.pawket.shared.idempotency.IdempotencyService;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/api/v1/invitations")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class InvitationResource {
    private final InvitationService invitationService;
    private final CurrentActorProvider currentActor;
    private final IdempotencyService idempotency;

    public InvitationResource(
            InvitationService invitationService,
            CurrentActorProvider currentActor,
            IdempotencyService idempotency) {
        this.invitationService = invitationService;
        this.currentActor = currentActor;
        this.idempotency = idempotency;
    }

    @POST
    public Response create(
            @Valid CreateInvitationRequest request,
            @HeaderParam("Idempotency-Key") String idempotencyKey) {
        var actorId = currentActor.userId();
        var result = idempotency.execute(
                actorId,
                "CREATE_INVITATION",
                idempotencyKey,
                request,
                InvitationDtos.InvitationCreatedResponse.class,
                () -> invitationService.create(actorId, request.petId(), request.role(), request.expiresInDays()));
        return Response.status(Response.Status.CREATED)
                .entity(new DataResponse<>(result))
                .build();
    }

    @GET
    @Path("/{token}")
    public Object preview(@PathParam("token") String token) {
        return new DataResponse<>(invitationService.preview(token));
    }

    @POST
    @Path("/accept")
    public Object accept(
            @Valid AcceptInvitationRequest request,
            @HeaderParam("Idempotency-Key") String idempotencyKey) {
        var actorId = currentActor.userId();
        var result = idempotency.execute(
                actorId,
                "ACCEPT_INVITATION",
                idempotencyKey,
                request,
                InvitationDtos.InvitationAcceptedResponse.class,
                () -> invitationService.accept(actorId, request.token()));
        return new DataResponse<>(result);
    }
}
