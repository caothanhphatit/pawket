# Mobile Architecture

## Technology baseline

- Flutter stable channel pinned in repository tooling.
- Dart strict analysis.
- Riverpod for dependency injection and state management.
- GoRouter for declarative navigation.
- Dio for HTTP transport behind an API client abstraction.
- Freezed and JSON serialization for immutable transport models where generation adds value.
- Secure platform storage for refresh credentials or sensitive local tokens.
- A lightweight local database MAY be introduced for durable offline cache after the first vertical slice.

Package versions MUST be pinned by `pubspec.lock` for application builds.

## Feature-first structure

```text
lib/
|- app/
|  |- bootstrap/
|  |- routing/
|  |- theme/
|  `- localization/
|- core/
|  |- auth/
|  |- error/
|  |- network/
|  |- storage/
|  `- telemetry/
`- features/
   |- pets/
   |  |- domain/
   |  |- application/
   |  |- data/
   |  `- presentation/
   |- timeline/
   |- posts/
   `- memberships/
```

`core` MUST remain domain-neutral. Reusable pet or timeline logic belongs to its feature, even if several screens use it.

## Layer rules

### Presentation

- Widgets render state and emit user intent.
- Widgets MUST NOT invoke Dio, parse JSON, or contain authorization/business rules.
- Screen state is represented by explicit loading, content, empty, and failure states.
- Large widgets SHOULD be decomposed by visual responsibility, not arbitrary line count.

### Application

- Controllers or notifiers coordinate use cases and presentation state.
- Application logic depends on repository interfaces.
- Cross-feature orchestration MUST be explicit and should not be hidden in widgets.

### Domain

- Contains entities, value objects, repository contracts, and domain validation meaningful on-device.
- Domain types MUST NOT depend on Flutter widgets, Dio, or persistence packages.

### Data

- Implements repositories using remote and optional local data sources.
- Maps DTOs to domain models.
- Provider-specific errors MUST be translated into application error types.

## Dependency injection with Riverpod

- Providers are the composition mechanism; manual global singletons MUST NOT be used.
- Infrastructure providers live near app bootstrap or the owning feature data layer.
- UI watches state providers and invokes notifier methods for commands.
- Provider overrides MUST be used for tests and environment-specific implementations.
- Business state MUST NOT be stored in static variables.
- `BuildContext` MUST NOT cross into repository or domain layers.

Example boundary:

```dart
abstract interface class PetRepository {
  Future<List<Pet>> listAccessiblePets();
  Future<Pet> createPet(CreatePetInput input);
}

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return RemotePetRepository(ref.watch(apiClientProvider));
});
```

## State ownership

- Server state: pets, memberships, posts, reactions, and timelines.
- App state: current session, selected `activePetId`, locale, and feature flags.
- Ephemeral UI state: draft caption, current tab, picker state, and animation state.

The active pet selection MUST use a nullable ID: `null` means all accessible pets. It MUST persist locally per user but be validated against the latest accessible pet list after login.

## Navigation

- Route names and paths are centralized.
- Authentication and onboarding redirects use router guards.
- Feature code MUST navigate through named routes or typed route helpers.
- Deep links for invitations MUST be parsed and validated before use.
- A deep link MUST never imply authorization; the backend decides access.

## Networking

- One configured API client owns base URL, timeouts, authentication, correlation ID, and safe retry policy.
- GET and explicitly idempotent requests MAY retry transient failures with bounded exponential backoff and jitter.
- Mutations MUST NOT retry automatically unless they use an idempotency key.
- HTTP DTOs MUST remain separate from presentation models when their lifecycle differs.
- Logs MUST redact authorization, signed URLs, device tokens, and personal data.

## Media flow

- Validate file type and size before requesting an upload intent.
- Upload directly to the signed object-storage URL.
- Display local preview while upload is in progress.
- Persist enough draft state to recover from app interruption when practical.
- Confirm upload with the backend before publishing a post.
- Remove EXIF GPS data before upload unless a future feature has explicit consent and policy.

## Offline and caching

- Authentication and authorization changes require online confirmation.
- The app MAY show cached pet profiles and timelines while offline.
- Offline writes are not part of the first release unless explicitly planned.
- Cache entries MUST be scoped by user identity and cleared on logout or account switch.
- Signed media URLs MUST NOT be treated as durable identifiers.

## UI engineering rules

- Theme tokens define color, typography, spacing, radii, elevation, and motion.
- Hard-coded design values SHOULD NOT appear throughout feature widgets.
- Every screen MUST support loading, empty, failure, offline, and retry behavior where relevant.
- Touch targets, contrast, dynamic text, and screen-reader labels MUST meet platform accessibility expectations.
- User-visible strings MUST be localization-ready from the first release.

## Error handling

- Expected failures map to user-actionable states: authentication expired, access denied, validation, offline, upload failed, and conflict.
- Unexpected errors are captured with correlation context and show a safe generic message.
- The app MUST NOT expose raw server messages or stack traces.

