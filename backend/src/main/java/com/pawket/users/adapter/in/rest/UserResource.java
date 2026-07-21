package com.pawket.users.adapter.in.rest;

import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import com.pawket.users.application.UserQueryService;
import com.pawket.users.domain.model.User;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.time.Instant;
import java.util.UUID;

@Path("/api/v1/users/me")
@Produces(MediaType.APPLICATION_JSON)
public class UserResource {
    private final UserQueryService queries;
    private final CurrentActorProvider currentActor;

    public UserResource(UserQueryService queries, CurrentActorProvider currentActor) {
        this.queries = queries;
        this.currentActor = currentActor;
    }

    @GET
    public DataResponse<UserResponse> getCurrent() {
        return new DataResponse<>(UserResponse.from(queries.getCurrent(currentActor.userId())));
    }

    public record UserResponse(
            UUID id,
            String displayName,
            UUID avatarMediaId,
            Instant createdAt,
            Instant updatedAt,
            long version) {
        static UserResponse from(User user) {
            return new UserResponse(
                    user.id(), user.displayName(), user.avatarMediaId(),
                    user.createdAt(), user.updatedAt(), user.version());
        }
    }
}
