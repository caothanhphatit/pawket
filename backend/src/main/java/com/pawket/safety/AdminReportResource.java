package com.pawket.safety;

import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/api/v1/admin/reports")
@Produces(MediaType.APPLICATION_JSON)
public class AdminReportResource {
    private final ReportService reports;
    private final CurrentActorProvider currentActor;

    public AdminReportResource(ReportService reports, CurrentActorProvider currentActor) {
        this.reports = reports;
        this.currentActor = currentActor;
    }

    @GET
    public Object queue() { return new DataResponse<>(reports.moderationQueue(currentActor.userId())); }
}
