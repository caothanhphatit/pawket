package com.pawket.reactions;

import com.pawket.reactions.ReactionDtos.UpsertReactionRequest;
import com.pawket.shared.auth.CurrentActorProvider;
import com.pawket.shared.api.DataResponse;
import com.pawket.shared.idempotency.IdempotencyService;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

@Path("/api/v1/posts/{postId}/reaction")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ReactionResource {
    private final ReactionService reactionService;
    private final CurrentActorProvider currentActor;
    private final IdempotencyService idempotency;

    public ReactionResource(
            ReactionService reactionService,
            CurrentActorProvider currentActor,
            IdempotencyService idempotency) {
        this.reactionService = reactionService;
        this.currentActor = currentActor;
        this.idempotency = idempotency;
    }

    @PUT
    public Object upsert(
            @PathParam("postId") UUID postId,
            @Valid UpsertReactionRequest request,
            @HeaderParam("Idempotency-Key") String idempotencyKey) {
        var actorId = currentActor.userId();
        var idempotencyRequest = new ReactionIdempotencyRequest(postId, request.type());
        var result = idempotency.execute(
                actorId,
                "UPSERT_REACTION",
                idempotencyKey,
                idempotencyRequest,
                ReactionDtos.ReactionResponse.class,
                () -> reactionService.upsert(actorId, postId, request.type()));
        return new DataResponse<>(result);
    }

    @DELETE
    public Object delete(@PathParam("postId") UUID postId) {
        return new DataResponse<>(reactionService.delete(currentActor.userId(), postId));
    }

    @GET
    @Path("/people")
    public Object people(@PathParam("postId") UUID postId) {
        return new DataResponse<>(reactionService.people(currentActor.userId(), postId));
    }

    private record ReactionIdempotencyRequest(UUID postId, String type) {}
}
