package com.pawket.posts;

import com.pawket.shared.auth.CurrentActorProvider;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

@Path("/api/v1/pets/{petId}/timeline")
@Produces(MediaType.APPLICATION_JSON)
public class PetTimelineResource {
    private final PostService postService;
    private final CurrentActorProvider currentActor;

    public PetTimelineResource(PostService postService, CurrentActorProvider currentActor) {
        this.postService = postService;
        this.currentActor = currentActor;
    }

    @GET
    public Object timeline(
            @PathParam("petId") UUID petId,
            @QueryParam("cursor") String cursor,
            @QueryParam("limit") @DefaultValue("30") int limit) {
        return postService.feed(currentActor.userId(), petId, cursor, limit);
    }
}
