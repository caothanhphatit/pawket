# API Standards

## General contract

- Base path: `/api/v1`.
- JSON uses UTF-8 and `camelCase` field names.
- Resource URLs use plural nouns and lowercase kebab-free segments, for example `/api/v1/pets/{petId}`.
- HTTP methods follow semantics: GET reads, POST creates or executes a command, PATCH performs partial update, DELETE requests deletion.
- Public contracts MUST be represented in OpenAPI and reviewed with mobile changes.
- API DTOs MUST NOT expose persistence entities.

## Authentication and authorization

- Protected requests use `Authorization: Bearer <token>`.
- The backend validates issuer, audience, signature, expiry, and required token properties.
- Client-supplied user IDs MUST NOT determine the acting user.
- Resource authorization is checked for every request, including nested resources and signed media operations.

## Identifiers and time

- IDs are opaque strings in API contracts; clients MUST NOT infer structure.
- Timestamps use ISO 8601 UTC, for example `2026-07-18T08:30:00Z`.
- Dates without time use `YYYY-MM-DD`.
- Clients send IANA timezone names only where local calendar behavior matters.

## Success responses

Examples:

```http
POST /api/v1/pets
Idempotency-Key: 7a9e...
```

```json
{
  "data": {
    "id": "pet_opaque_id",
    "name": "Mit",
    "species": "DOG",
    "avatarUrl": null,
    "permissions": ["PET_READ", "PET_UPDATE", "MEMBER_INVITE"]
  }
}
```

- Creation returns `201 Created` and a `Location` header.
- Successful deletion request returns `204 No Content` or `202 Accepted` when asynchronous.
- Empty collections return `200` with an empty list, not `404`.

## Error responses

Use `application/problem+json` based on RFC 9457:

```json
{
  "type": "https://docs.pawket.app/problems/validation-error",
  "title": "Request validation failed",
  "status": 400,
  "code": "VALIDATION_ERROR",
  "detail": "One or more fields are invalid.",
  "instance": "/api/v1/pets",
  "correlationId": "01J...",
  "errors": [
    {
      "field": "name",
      "code": "REQUIRED",
      "message": "Name is required."
    }
  ]
}
```

- `code` is a stable machine-readable Pawket code.
- `detail` is safe for display only when explicitly designed that way.
- Internal exception names, SQL, provider messages, and stack traces MUST NOT be returned.
- Use `401` for missing or invalid authentication, `403` for authenticated but forbidden, and `404` when resource existence should be concealed.
- Use `409` for state conflict or optimistic-lock conflict.
- Use `422` only for well-defined semantic validation when `400` is insufficient and consistently applied.
- Use `429` with `Retry-After` for rate limiting.

## Pagination

Collection endpoints use cursor pagination:

```http
GET /api/v1/pets/{petId}/timeline?limit=20&cursor=opaque
```

```json
{
  "data": [],
  "page": {
    "nextCursor": "opaque-or-null",
    "hasMore": false
  }
}
```

- Default limit is 20; maximum is 100 unless a specific endpoint documents less.
- Cursors are opaque, signed or safely encoded, and bound to query ordering/filter semantics.

## Filtering and sorting

- Filters use explicit query parameters.
- Sort values use a documented allowlist; arbitrary database fields are forbidden.
- Unknown filter or sort values return validation errors instead of being ignored silently.

## Idempotency

- Create pet, create post, invitation acceptance, ownership change, and other retry-sensitive commands MUST support idempotency keys.
- Scope keys to authenticated user plus endpoint/operation.
- Same key and same payload returns the original outcome.
- Same key with a different payload returns `409`.
- The server defines and documents key retention duration.

## Concurrency

- Mutable resources SHOULD return an `ETag` or version.
- Conflict-sensitive updates SHOULD require `If-Match` or a version field.
- Stale edits return `409` or `412` consistently.

## Media API

Recommended workflow:

```text
POST /api/v1/media/upload-intents
PUT  <signed object-storage URL>
POST /api/v1/media/{mediaId}/complete
POST /api/v1/posts
```

- Upload intent validates declared MIME type, byte size, and purpose.
- Signed URL TTL SHOULD be 5 to 15 minutes.
- Completion MUST verify object existence and expected constraints.
- Server-side inspection MAY transition media from `UPLOADED` to `READY` asynchronously.
- Publishing MUST reject media not owned by the actor or not in an allowed state.

## Versioning and compatibility

- `/v1` is a compatibility boundary, not a release number.
- Additive optional fields are backward compatible.
- Removing fields, changing meaning, narrowing accepted values, or changing required behavior is breaking.
- Mobile API compatibility MUST account for users running older app versions.
- Deprecations require telemetry, notice, minimum supported app policy, and removal date.

## Rate limits

Rate limits MUST distinguish authentication, reads, writes, invitations, reactions, and media intents. Exact values are configuration, but limits and error behavior must be testable and observable.

