# Operations and Observability

## Observability standard

The backend MUST provide structured logs, metrics, distributed traces, health checks, and actionable alerts. Mobile MUST provide crash and non-fatal error telemetry with privacy-safe context.

## Correlation

- Accept a valid client correlation ID or generate one at the API edge.
- Return it in response headers and problem responses.
- Propagate it through application logs, external provider calls, and asynchronous jobs.
- Mobile SHOULD attach a generated request ID and include the returned correlation ID in captured failures.

## Logging

Use structured JSON in deployed environments.

Required fields where applicable:

- Timestamp.
- Severity.
- Service and version.
- Environment.
- Correlation and trace IDs.
- Safe actor ID.
- Module and operation.
- Outcome and stable error code.
- Duration.

- Do not log request/response bodies by default.
- Repeated expected client errors SHOULD not page operators.
- Logs MUST follow the redaction policy in the security document.

## Metrics

### Technical metrics

- Request rate, error rate, and duration by route template and status class.
- JVM CPU, memory, GC, thread/connection pools.
- Database pool usage, query latency, locks, and storage growth.
- Object-storage and push-provider success, failure, and latency.
- Background job backlog, age, retries, and dead letters when jobs exist.

### Product health metrics

- Successful pet creation.
- Successful media intent, upload completion, and post publication.
- Timeline load success.
- Invitation sent and accepted.
- Active pets recorded at least three days per week.

Product telemetry MUST avoid private content and use documented event schemas.

## Tracing

- Trace API entry through database and approved external calls.
- Sample enough successful traffic for performance analysis and retain all or elevated samples for errors within budget.
- Span attributes MUST NOT include captions, pet names, emails, signed URLs, or tokens.
- Custom spans SHOULD represent meaningful operations such as `create_pet`, `publish_post`, and `issue_upload_intent`.

## Health checks

- Liveness reports whether the process should be restarted.
- Readiness reports whether the instance can receive traffic.
- Readiness MAY check essential dependencies with bounded timeouts but MUST avoid causing dependency storms.
- Startup verifies required configuration and migration compatibility.

## Alerting

Alerts MUST be actionable and tied to user impact or imminent capacity risk.

Initial alerts:

- Sustained API 5xx rate above threshold.
- Authentication failure anomaly.
- Timeline or publish-post latency breach.
- Database connections near exhaustion.
- Database storage or object-storage failure.
- Flyway migration failure.
- Upload completion failure spike.
- Mobile crash-free sessions below target.

Every page-level alert has owner, runbook link, severity, and silence/escalation policy.

## Severity model

| Severity | Definition | Response target |
| --- | --- | --- |
| SEV-1 | Widespread outage, data exposure, or material data loss | Immediate coordinated response |
| SEV-2 | Major feature unavailable or severe degradation | Respond urgently during support coverage |
| SEV-3 | Limited impact with workaround | Prioritized normal workflow |
| SEV-4 | Minor defect or operational improvement | Backlog |

Exact support hours and response times MUST be defined before production launch.

## Backups and recovery

- PostgreSQL automated backups MUST be enabled with point-in-time recovery when available.
- Object storage SHOULD use versioning or provider recovery appropriate to cost and privacy policy.
- Backup encryption and access control are mandatory.
- Restore tests MUST run at least quarterly before public launch and after material storage changes.
- A restore is not considered tested until application-level integrity checks pass.

## Capacity and cost

- Track database size, media storage, egress, signed URL volume, and push volume.
- Media lifecycle rules SHOULD move or delete orphaned content according to retention policy.
- Capacity reviews use trend data, not only current utilization.
- Performance optimizations MUST state user benefit and cost impact.

## Runbooks required before production

- Backend unavailable.
- Database unavailable or connection exhaustion.
- Failed migration.
- Object storage upload/download failure.
- OIDC provider outage.
- Push provider degradation.
- Credential compromise.
- User data export/deletion failure.
- Restore from backup.

## Incident reviews

SEV-1 and SEV-2 incidents require a blameless review covering timeline, impact, detection, root causes, contributing conditions, recovery, and assigned preventive actions.

