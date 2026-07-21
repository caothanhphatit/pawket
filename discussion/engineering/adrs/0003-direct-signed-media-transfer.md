# ADR 0003: Direct signed media transfer

- Status: Accepted
- Date: 2026-07-18
- Owners: Pawket engineering
- Reviewers: Mobile, backend, and security owners
- Review date: Before enabling video or public media
- Supersedes: N/A

## Context

Pawket is media-heavy. Proxying image bytes through the Quarkus API would increase application bandwidth, memory pressure, latency, and scaling cost. Direct public buckets would violate the private-by-default model.

## Decision drivers

- Private media access.
- Efficient large-file transfer.
- Server-controlled authorization and object keys.
- Recoverable upload workflow.
- Future compatibility with media inspection and CDN delivery.

## Considered options

### Direct transfer with signed URLs

Backend authorizes and issues short-lived signed operations; mobile transfers bytes directly with private object storage.

### Proxy transfer through backend

Simpler client path but higher server cost and failure surface.

### Public object URLs

Simple delivery but incompatible with private-by-default access.

## Decision

Use private S3-compatible storage. Quarkus issues short-lived, narrowly scoped signed upload/download operations. PostgreSQL stores media identity, state, ownership, and storage key.

## Consequences

### Positive

- Backend avoids handling media byte streams.
- Storage can scale independently.
- Access remains temporary and authorized.

### Negative and risks

- Upload completion is a workflow rather than one database transaction.
- Orphan cleanup and content verification are required.
- Signed URL leakage grants access until expiry, so TTL and log redaction matter.

## Security, privacy, and data impact

Buckets block public access. Object keys contain no user-provided filename or personal data. The client removes GPS EXIF metadata. Signed URLs and raw storage keys are treated as confidential.

## Delivery and migration

Implement upload intent, direct upload, completion, and post publication as separate idempotent steps. Add cleanup for expired pending media.

## Validation

Test size/type enforcement, expiry, unauthorized media reuse, interruption recovery, orphan cleanup, and read authorization.

