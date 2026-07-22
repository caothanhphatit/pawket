# Pawket MVP V1 Delivery Status

Updated: 2026-07-22

## Frozen scope

- Camera-first launch with a square preview, shutter, flash and lens switch.
- Camera to Home uses vertical motion; Feed and Profile use horizontal motion.
- One current pet at a time. Multiple pets are switched from Profile.
- First launch requires a pet profile before the camera is available; name and species are required and 0-5 starter photos are optional.
- The first starter photo becomes the pet avatar and every starter photo becomes a memory.
- A new memory is always saved to the current pet and may have no caption. Pet switching only lives in Profile.
- Audience supports `PET_MEMBERS` and `PRIVATE`.
- Feed, newest-first profile album, memory detail and reactions.
- Memory edit/delete, daily local reminder, monthly calendar, weekly recap sharing and old-photo import from Profile.
- Profile editing, milestones, member roles, pending invitation management and owner-controlled member removal.

Explicitly deferred: AI identification, marketplace, ownership transfer, public discovery,
chat, video, friends graph, remote push notifications and medical records.

## Implemented mobile slices

- Camera permission/error/retry states and app lifecycle recovery.
- Shutter timestamp preserved through upload and publication.
- Direct signed upload, completion and post creation with progress and retryable failure state.
- Pet create/edit/switch, active-pet persistence and optional starter memories.
- Real pet avatars from media, real current-account data and no fabricated offline pets/posts.
- Feed/profile refresh, cursor page aggregation, memory detail zoom and reactions.
- Members, invitations and owner member removal.
- Mandatory first-pet gate with bounded loading, connection retry and no skip path.
- Daily status, configurable on-device reminder, monthly calendar and shareable weekly recap.
- Old-photo import is available from Profile without adding a gallery action to the camera.
- Memory caption/audience editing, deletion, bounded resize/compression and resumable publish retries.
- Birthday, home day, first trip and custom milestones.
- One-level comments with create/edit/delete, post and comment reporting, reaction member lists and minimal shared-member profiles.
- Durable in-app notification inbox with unread badge/read state, plus block/unblock management.

## Implemented backend slices

- Quarkus modular monolith with PostgreSQL, Flyway and S3-compatible media storage.
- OIDC actor resolution and first-login internal user provisioning for production builds.
- Dev identity header for local-device development only.
- Pet, membership, invitation, media, post, timeline, feed and reaction APIs.
- Actor-scoped idempotency for create/retry workflows.
- Stable problem responses for validation and HTTP errors with correlation IDs.
- Optimistic pet profile version checks.
- Atomic media attachment and locked invitation acceptance.
- Memory edit/delete with author authorization, version checks and inaccessible deleted media.
- Media limits plus scheduled cleanup/purge for abandoned uploads.
- Member role changes, pending invitation listing/revocation and milestone authorization/audit.
- Durable comments and notification events for new memories, reactions, comments and accepted invitations.
- Shared-member profiles, two-way block enforcement, report history and an admin-protected moderation queue.

## External setup before public beta

These are deployment decisions, not missing local MVP code:

- Select and configure the managed OIDC provider and mobile sign-in UX.
- Configure production PostgreSQL, object storage/CDN, secrets and backups.
- Configure the `pawket.app` domain plus iOS Universal Links and Android App Links.
- Add privacy policy, account deletion decisions and App Store/Play Store metadata. Portable JSON export is implemented.
- Add CI, crash reporting, metrics/alerts and a staged distribution pipeline.

Until OIDC is configured, private-beta iPhone builds use `PAWKET_DEV_USER_ID`. The current
default API is `https://v2.poeviethoa.net/api/v1`; local development should override it with
`PAWKET_API_BASE_URL`.
