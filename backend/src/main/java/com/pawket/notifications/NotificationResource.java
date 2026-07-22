package com.pawket.notifications;

import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

@Path("/api/v1/notifications")
@Produces(MediaType.APPLICATION_JSON)
public class NotificationResource {
    private final NotificationService notifications;
    private final CurrentActorProvider currentActor;

    public NotificationResource(NotificationService notifications, CurrentActorProvider currentActor) {
        this.notifications = notifications;
        this.currentActor = currentActor;
    }

    @GET
    public Object list(
            @QueryParam("unreadOnly") @DefaultValue("false") boolean unreadOnly,
            @QueryParam("cursor") String cursor,
            @QueryParam("limit") @DefaultValue("30") int limit) {
        return notifications.list(currentActor.userId(), unreadOnly, cursor, limit);
    }

    @GET
    @Path("/unread-count")
    public Object unreadCount() {
        return new DataResponse<>(notifications.unreadCount(currentActor.userId()));
    }

    @POST
    @Path("/{notificationId}/read")
    public Object markRead(@PathParam("notificationId") UUID notificationId) {
        return new DataResponse<>(notifications.markRead(currentActor.userId(), notificationId));
    }

    @POST
    @Path("/read-all")
    public Object markAllRead() {
        return new DataResponse<>(notifications.markAllRead(currentActor.userId()));
    }
}
