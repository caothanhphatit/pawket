# Coding Conventions

## Shared rules

- Code, identifiers, commits, API fields, and technical documentation use English.
- Prefer clarity over cleverness and explicit domain names over abbreviations.
- A function or class MUST have one cohesive reason to change.
- Comments explain intent, constraints, or non-obvious tradeoffs; they MUST NOT narrate obvious code.
- TODO comments require an issue reference and owner context.
- Dead code, commented-out code, and unused dependencies MUST NOT be merged.
- Time, randomness, identity, and external providers MUST be injectable for deterministic tests.
- Do not catch broad exceptions unless translating at a system boundary or preventing process failure with proper telemetry.

## Naming

Use domain language consistently:

- `PetMembership`, not `UserPet` in domain code.
- `capturedAt` for when media was captured.
- `createdAt` for when a database record was created.
- `activePetId` for current mobile selection; `null` means all accessible pets.
- `Owner`, `Caretaker`, and `Follower` are roles, not separate user types.

Avoid ambiguous words such as `Manager`, `Helper`, `Data`, `Info`, `Utils`, and `Common` unless the name communicates a precise responsibility.

## Java conventions

- Follow standard Java naming and apply an automated formatter chosen by the repository.
- Packages are lowercase under `com.pawket`.
- Classes and records use `UpperCamelCase`; methods and variables use `lowerCamelCase`; constants use `UPPER_SNAKE_CASE`.
- Use constructor injection only.
- Prefer immutable records for DTOs.
- Do not return `null` collections; return empty immutable collections.
- `Optional` MAY be used for return values but MUST NOT be used for entity fields, method parameters, or JSON properties.
- Use `Instant` for timestamps, `LocalDate` for date-only values, and inject `Clock`.
- Use enums for closed domain sets; map them explicitly across API and persistence boundaries.
- Use sealed types only when they make a closed state model materially clearer.
- Public methods MUST validate assumptions at the appropriate boundary.
- Avoid boolean parameters whose meaning is unclear at call sites; use named options or value types.
- Streams SHOULD be used for clear transformations, not stateful or deeply nested control flow.
- Lombok SHOULD NOT be introduced; Java records and IDE generation are preferred.

### Java class responsibilities

- REST resources end with `Resource`.
- Application commands end with `Command`; handlers/services use domain action names.
- Query projections end with `View` or `Summary` when helpful.
- Persistence records end with `Entity` only inside adapters.
- Repository interfaces use domain names, for example `PetRepository`.
- Provider adapters use explicit names, for example `S3MediaStorage` or `FcmPushGateway`.

### Java error rules

- Domain/application failures have stable internal codes.
- Infrastructure exceptions are translated at adapter boundaries.
- Never use exception message text as a programmatic contract.
- Never expose raw exceptions to REST clients.

## Dart and Flutter conventions

- Apply `dart format` and strict static analysis.
- Files use `lower_snake_case.dart`.
- Types use `UpperCamelCase`; variables and methods use `lowerCamelCase`.
- Prefer `final`; mutable state must be localized and justified.
- Public feature interfaces SHOULD use immutable models.
- Avoid force unwrap `!`; prove non-nullability or handle the absence.
- Avoid `dynamic`; boundary decoding MUST validate types.
- Do not pass `BuildContext` into repositories, services, or domain objects.
- Do not perform side effects in widget `build` methods.
- Widgets SHOULD receive the minimum data and callbacks they need.
- Riverpod providers use descriptive suffixes such as `Provider`, `RepositoryProvider`, or `ControllerProvider` consistently.
- Async state MUST render loading, error, empty, and content states explicitly.
- UI strings come from localization resources, not inline literals in feature widgets.

### Dart model rules

- API DTOs mirror transport contracts and stay in the data layer.
- Domain models represent behavior and app meaning.
- Presentation models MAY combine fields for rendering but MUST NOT become persistence contracts.
- Generated files MUST NOT be edited manually.

## SQL conventions

- PostgreSQL identifiers use lowercase `snake_case`.
- Keywords SHOULD be uppercase in handwritten migrations.
- Every migration is focused and has a descriptive file name.
- Constraints and indexes use names that identify table and columns, for example `uq_pet_memberships_pet_user_active`.
- Use explicit column lists in inserts.
- Avoid `SELECT *` in application queries and migrations where schema evolution matters.
- Raw SQL MUST be formatted and covered by integration tests for material queries.

## API conventions

- JSON uses `camelCase`.
- Enums use stable `UPPER_SNAKE_CASE` wire values.
- Optional and nullable are not synonyms: OpenAPI MUST model both intentionally.
- Booleans use affirmative names such as `estimatedBirth`, not `notExact`.
- Request and response examples MUST avoid real personal data.

## Code review rules

Reviewers prioritize:

1. Domain correctness and authorization.
2. Data loss, privacy, and security risk.
3. API/mobile backward compatibility.
4. Transaction and concurrency behavior.
5. Failure handling and observability.
6. Test quality.
7. Maintainability and style.

Formatting preferences SHOULD be delegated to automated tooling, not debated in review.

