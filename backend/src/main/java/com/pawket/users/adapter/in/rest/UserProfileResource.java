package com.pawket.users.adapter.in.rest;

import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import com.pawket.users.application.UserProfileService;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

@Path("/api/v1/users/{userId}")
@Produces(MediaType.APPLICATION_JSON)
public class UserProfileResource {
    private final UserProfileService profiles;
    private final CurrentActorProvider currentActor;

    public UserProfileResource(UserProfileService profiles, CurrentActorProvider currentActor) {
        this.profiles = profiles;
        this.currentActor = currentActor;
    }

    @GET
    public Object get(@PathParam("userId") UUID userId) {
        return new DataResponse<>(profiles.get(currentActor.userId(), userId));
    }
}
