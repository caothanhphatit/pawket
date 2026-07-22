package com.pawket.safety;

import com.pawket.safety.ReportService.CreateReportRequest;
import com.pawket.shared.api.DataResponse;
import com.pawket.shared.auth.CurrentActorProvider;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.UUID;

@Path("/api/v1/reports")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ReportResource {
    private final ReportService reports;
    private final CurrentActorProvider currentActor;

    public ReportResource(ReportService reports, CurrentActorProvider currentActor) {
        this.reports = reports;
        this.currentActor = currentActor;
    }

    @POST
    public Object create(@Valid CreateReportBody body) {
        return new DataResponse<>(reports.create(currentActor.userId(),
                new CreateReportRequest(body.targetType(), body.targetId(), body.reason(), body.details())));
    }

    @GET
    public Object mine() { return new DataResponse<>(reports.listMine(currentActor.userId())); }

    public record CreateReportBody(@NotBlank String targetType, @NotNull UUID targetId,
                                   @NotBlank String reason, @Size(max = 1000) String details) {}
}
