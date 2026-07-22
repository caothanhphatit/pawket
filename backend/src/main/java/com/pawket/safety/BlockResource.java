package com.pawket.safety;

import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

@Path("/api/v1/blocks")
@Produces(MediaType.APPLICATION_JSON)
public class BlockResource {
    private final BlockService blocks;
    private final CurrentActorProvider currentActor;

    public BlockResource(BlockService blocks, CurrentActorProvider currentActor) {
        this.blocks = blocks;
        this.currentActor = currentActor;
    }

    @GET
    public Object list() { return new DataResponse<>(blocks.list(currentActor.userId())); }

    @POST
    @Path("/{userId}")
    public void block(@PathParam("userId") UUID userId) { blocks.block(currentActor.userId(), userId); }

    @DELETE
    @Path("/{userId}")
    public void unblock(@PathParam("userId") UUID userId) { blocks.unblock(currentActor.userId(), userId); }
}
