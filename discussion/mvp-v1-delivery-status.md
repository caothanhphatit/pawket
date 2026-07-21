# Pawket MVP V1 Delivery Status

Updated: 2026-07-21

## Frozen scope

- Camera-first launch with a square preview, shutter, flash and lens switch.
- Camera to Home uses vertical motion; Feed and Profile use horizontal motion.
- One current pet at a time. Multiple pets are switched from Profile.
- Pet creation requires name and species; 0-5 starter photos are optional.
- The first starter photo becomes the pet avatar and every starter photo becomes a memory.
- A memory can tag one or more accessible pets and may have no caption.
- Audience supports `PET_MEMBERS` and `PRIVATE`.
- Feed, newest-first profile album, memory detail and reactions.
- Profile editing, member list, invitation links and owner-controlled member removal.

Explicitly deferred: AI identification, marketplace, ownership transfer, public discovery,
chat, video, friends graph, push notifications and medical records.

## Implemented mobile slices

- Camera permission/error/retry states and app lifecycle recovery.
- Shutter timestamp preserved through upload and publication.
- Direct signed upload, completion and post creation with progress and retryable failure state.
- Pet create/edit/switch, active-pet persistence and optional starter memories.
- Real pet avatars from media, real current-account data and no fabricated offline pets/posts.
- Feed/profile refresh, cursor page aggregation, memory detail zoom and reactions.
- Members, invitations and owner member removal.

## Implemented backend slices

- Quarkus modular monolith with PostgreSQL, Flyway and S3-compatible media storage.
- OIDC actor resolution and first-login internal user provisioning for production builds.
- Dev identity header for local-device development only.
- Pet, membership, invitation, media, post, timeline, feed and reaction APIs.
- Actor-scoped idempotency for create/retry workflows.
- Stable problem responses for validation and HTTP errors with correlation IDs.
- Optimistic pet profile version checks.
- Atomic media attachment and locked invitation acceptance.

## External setup before public beta

These are deployment decisions, not missing local MVP code:

- Select and configure the managed OIDC provider and mobile sign-in UX.
- Configure production PostgreSQL, object storage/CDN, secrets and backups.
- Configure the `pawket.app` domain plus iOS Universal Links and Android App Links.
- Add privacy policy, account deletion/export and App Store/Play Store metadata.
- Add CI, crash reporting, metrics/alerts and a staged distribution pipeline.

Until OIDC is configured, local iPhone builds use `PAWKET_DEV_USER_ID` and must point to the
LAN backend URL supplied through `PAWKET_API_BASE_URL`.
