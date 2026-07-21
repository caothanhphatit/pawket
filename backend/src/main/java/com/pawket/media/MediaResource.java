package com.pawket.media;

import com.pawket.media.MediaDtos.CompleteUploadRequest;
import com.pawket.media.MediaDtos.CreateUploadIntentRequest;
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
import java.net.URI;
import java.util.UUID;

@Path("/api/v1/media")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class MediaResource {
    private final MediaService mediaService;
    private final CurrentActorProvider currentActor;
    private final IdempotencyService idempotency;

    public MediaResource(
            MediaService mediaService,
            CurrentActorProvider currentActor,
            IdempotencyService idempotency) {
        this.mediaService = mediaService;
        this.currentActor = currentActor;
        this.idempotency = idempotency;
    }

    @POST
    @Path("/upload-intents")
    public Response createIntent(
            @Valid CreateUploadIntentRequest request,
            @HeaderParam("Idempotency-Key") String idempotencyKey) {
        var actorId = currentActor.userId();
        var result = idempotency.execute(
                actorId,
                "CREATE_MEDIA_UPLOAD_INTENT",
                idempotencyKey,
                request,
                MediaDtos.UploadIntentResponse.class,
                () -> mediaService.createIntent(actorId, request));
        return Response.status(Response.Status.CREATED)
                .entity(new DataResponse<>(result))
                .build();
    }

    @POST
    @Path("/complete")
    public Object complete(@Valid CompleteUploadRequest request) {
        return new DataResponse<>(mediaService.complete(currentActor.userId(), request.mediaId()));
    }

    @GET
    @Path("/{mediaId}/content")
    public Response content(@PathParam("mediaId") UUID mediaId) {
        return Response.temporaryRedirect(URI.create(mediaService.contentUrl(currentActor.userId(), mediaId))).build();
    }
}
