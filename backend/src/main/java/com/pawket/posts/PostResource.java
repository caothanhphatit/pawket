package com.pawket.posts;

import com.pawket.posts.PostDtos.CreatePostRequest;
import com.pawket.shared.auth.CurrentActorProvider;
import com.pawket.shared.api.DataResponse;
import com.pawket.shared.idempotency.IdempotencyService;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
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
public class PostResource {
    private final PostService postService;
    private final CurrentActorProvider currentActor;
    private final IdempotencyService idempotency;

    public PostResource(
            PostService postService,
            CurrentActorProvider currentActor,
            IdempotencyService idempotency) {
        this.postService = postService;
        this.currentActor = currentActor;
        this.idempotency = idempotency;
    }

    @POST
    @Path("/posts")
    public Response create(
            @Valid CreatePostRequest request,
            @HeaderParam("Idempotency-Key") String idempotencyKey) {
        var actorId = currentActor.userId();
        var result = idempotency.execute(
                actorId,
                "CREATE_POST",
                idempotencyKey,
                request,
                PostDtos.PostResponse.class,
                () -> postService.create(actorId, request));
        return Response.status(Response.Status.CREATED)
                .entity(new DataResponse<>(result))
                .build();
    }

    @GET
    @Path("/posts/{postId}")
    public Object get(@PathParam("postId") UUID postId) {
        return new DataResponse<>(postService.get(currentActor.userId(), postId));
    }

    @GET
    @Path("/feed")
    public Object feed(
            @QueryParam("petId") UUID petId,
            @QueryParam("cursor") String cursor,
            @QueryParam("limit") @DefaultValue("20") int limit) {
        return postService.feed(currentActor.userId(), petId, cursor, limit);
    }

}
