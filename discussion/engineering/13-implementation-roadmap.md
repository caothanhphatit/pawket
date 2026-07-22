# Implementation Roadmap

## Delivery strategy

Build vertical slices that cross Flutter, API, database, security, tests, and telemetry. Avoid completing all backend infrastructure before validating a user flow.

## Phase 0: Repository and engineering foundation

Deliverables:

- `mobile/` Flutter application.
- `backend/` Quarkus application.
- Maven and Flutter version pinning.
- Local PostgreSQL and S3-compatible development services.
- CI for format, analysis, tests, migration, security scan, and builds.
- Environment configuration and secret templates without real secrets.
- Initial ADRs for identity provider, ID format, and media provider.
- Basic logs, health checks, metrics, and correlation IDs.

Exit criteria:

- A new developer can run mobile and backend from documented commands.
- CI passes on an empty vertical skeleton.
- No manual database setup beyond documented automation.

## Phase 1: Identity and pet profiles

Backend:

- OIDC token validation and internal user provisioning.
- Pet creation, list, detail, and update.
- Owner membership created atomically with pet.
- Authorization policy and audit events.

Mobile:

- App bootstrap, authentication, navigation guards.
- Empty-state onboarding.
- Create pet without requiring an image.
- Pet list and active pet switcher.
- Persist active pet selection per user.

Exit criteria:

- User can authenticate, create multiple pets, switch between one pet and all pets, and reopen the app safely.
- Authorization tests prove unrelated users cannot access pets.

## Phase 2: Media and lifetime timeline

Backend:

- Media upload intent, completion, validation, and cleanup.
- Post creation with one or more pet tags.
- Single-pet cursor timelines for the currently selected pet.
- Signed media delivery.

Mobile:

- Camera permission, plus a Profile-only old-photo import flow.
- Local preview and upload progress.
- Manual multi-pet tagging.
- Publish flow and timeline states.
- Retry and interrupted upload behavior.

Exit criteria:

- User publishes one media item to one or more accessible pets and sees it in correct timelines.
- Unauthorized media and pet combinations are rejected.
- Orphan upload cleanup is operational.

## Phase 3: Members, invitations, and reactions

Backend:

- Expiring hashed invitation tokens.
- Membership acceptance and role authorization.
- Reaction create/update/remove.
- One-level comments, durable notification inbox events, blocking and report intake.

Mobile:

- Deep-link invitation acceptance.
- Member list and role-aware UI.
- Reactions with optimistic update and rollback.
- In-app notification inbox with unread state; remote push permission/device registration remains deferred.

Exit criteria:

- Owner can invite another user safely.
- New member sees only permitted data.
- Removed membership loses access immediately.

## Phase 4: Production readiness

- Privacy policy and data lifecycle behavior implemented.
- Account export and deletion decisions completed.
- Accessibility and localization review.
- Load baseline and database index review.
- Backup restore drill.
- Security review and abuse/rate-limit checks.
- Store build, staged rollout, dashboards, alerts, and runbooks.

## Explicitly deferred

- AI pet or breed recognition.
- Marketplace and payments.
- Ownership transfer workflow.
- Public discovery feed.
- Chat.
- Complex medical records.
- Microservices, Kafka, Redis, and search engine unless justified by measured needs.

## First architecture decisions to record

1. Managed OIDC provider selection.
2. PostgreSQL and object-storage hosting provider.
3. Identifier format.
4. Flutter local persistence choice and whether it is needed in Phase 1.
5. Media limits, normalization, and delivery/CDN strategy.
6. Minimum supported iOS and Android versions.
