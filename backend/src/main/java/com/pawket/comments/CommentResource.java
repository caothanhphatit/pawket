package com.pawket.comments;

import com.pawket.comments.CommentDtos.CreateCommentRequest;
import com.pawket.comments.CommentDtos.UpdateCommentRequest;
import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import com.pawket.shared.idempotency.IdempotencyService;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.UUID;

@Path("/api/v1")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class CommentResource {
    private final CommentService comments;
    private final CurrentActorProvider currentActor;
    private final IdempotencyService idempotency;

    public CommentResource(
            CommentService comments,
            CurrentActorProvider currentActor,
            IdempotencyService idempotency) {
        this.comments = comments;
        this.currentActor = currentActor;
        this.idempotency = idempotency;
    }

    @POST
    @Path("/posts/{postId}/comments")
    public Response create(
            @PathParam("postId") UUID postId,
            @Valid CreateCommentRequest request,
            @HeaderParam("Idempotency-Key") String idempotencyKey) {
        var actorId = currentActor.userId();
        var operationRequest = new CreateIdempotencyRequest(postId, request);
        var result = idempotency.execute(
                actorId, "CREATE_COMMENT", idempotencyKey, operationRequest,
                CommentDtos.CommentResponse.class,
                () -> comments.create(actorId, postId, request.body()));
        return Response.status(Response.Status.CREATED).entity(new DataResponse<>(result)).build();
    }

    @GET
    @Path("/posts/{postId}/comments")
    public Object list(
            @PathParam("postId") UUID postId,
            @QueryParam("cursor") String cursor,
            @QueryParam("limit") @DefaultValue("30") int limit) {
        return comments.list(currentActor.userId(), postId, cursor, limit);
    }

    @PATCH
    @Path("/comments/{commentId}")
    public Object update(
            @PathParam("commentId") UUID commentId,
            @Valid UpdateCommentRequest request,
            @HeaderParam("Idempotency-Key") String idempotencyKey) {
        var actorId = currentActor.userId();
        var operationRequest = new UpdateIdempotencyRequest(commentId, request);
        var result = idempotency.execute(
                actorId, "UPDATE_COMMENT", idempotencyKey, operationRequest,
                CommentDtos.CommentResponse.class,
                () -> comments.update(actorId, commentId, request.body(), request.version()));
        return new DataResponse<>(result);
    }

    @DELETE
    @Path("/comments/{commentId}")
    public Response delete(@PathParam("commentId") UUID commentId) {
        comments.delete(currentActor.userId(), commentId);
        return Response.noContent().build();
    }

    private record CreateIdempotencyRequest(UUID postId, CreateCommentRequest request) {}

    private record UpdateIdempotencyRequest(UUID commentId, UpdateCommentRequest request) {}
}
