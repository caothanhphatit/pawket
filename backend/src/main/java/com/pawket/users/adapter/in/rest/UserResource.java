package com.pawket.users.adapter.in.rest;

import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import com.pawket.users.application.UserQueryService;
import com.pawket.users.application.UserExportService;
import com.pawket.users.domain.model.User;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.UUID;

@Path("/api/v1/users/me")
@Produces(MediaType.APPLICATION_JSON)
public class UserResource {
    private final UserQueryService queries;
    private final CurrentActorProvider currentActor;
    private final UserExportService exports;

    public UserResource(UserQueryService queries, CurrentActorProvider currentActor, UserExportService exports) {
        this.queries = queries;
        this.currentActor = currentActor;
        this.exports = exports;
    }

    @GET
    public DataResponse<UserResponse> getCurrent() {
        return new DataResponse<>(UserResponse.from(queries.getCurrent(currentActor.userId())));
    }

    @GET
    @Path("/export")
    public Response exportCurrent() {
        var export = exports.export(currentActor.userId());
        return Response.ok(export)
                .header("Content-Disposition", "attachment; filename=\"pawket-user-export.json\"")
                .build();
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
