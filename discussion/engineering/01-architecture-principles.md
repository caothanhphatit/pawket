# Architecture Principles

## 1. Product and domain first

- The `Pet` is a long-lived domain identity, not a child object owned permanently by one user.
- Ownership and access MUST be represented through membership records.
- Timeline history MUST survive membership changes unless retention or deletion policy requires removal.
- The first release MUST optimize the daily path: authenticate, select pet, capture or choose media, tag pets, publish, view timeline.

## 2. Modular monolith before distributed systems

- The backend MUST deploy as one application and one primary PostgreSQL database until measured constraints justify extraction.
- Business modules MUST have explicit boundaries and MUST NOT read another module's tables directly through its repository.
- Cross-module interaction SHOULD use application interfaces in-process.
- Kafka, service meshes, distributed transactions, and independent microservice databases MUST NOT be introduced without an ADR and demonstrated operational need.

## 3. Clean dependencies

Dependencies point inward:

```text
Adapters -> Application -> Domain
Infrastructure implements ports owned by inner layers
```

- Domain code MUST NOT depend on Quarkus, Hibernate, HTTP, JSON, Firebase, or S3 types.
- Application use cases MUST coordinate domain behavior and ports.
- REST resources MUST only validate transport concerns, invoke a use case, and map the result.
- Repositories MUST hide persistence details from domain and application code.

## 4. Secure and private by default

- Every endpoint MUST be denied by default unless explicitly public.
- Authorization MUST be evaluated server-side for every protected resource.
- Media objects MUST be private; clients receive short-lived signed URLs.
- Secrets, access tokens, raw authorization headers, and personal data MUST NOT appear in logs.
- New data fields MUST have a purpose, owner, retention rule, and access policy.

## 5. Contract first at boundaries

- REST contracts MUST be described in OpenAPI and use stable DTOs.
- Persistence entities MUST NOT be serialized directly.
- Mobile features MUST depend on repository interfaces, not networking libraries.
- Breaking API and schema changes MUST use an explicit migration path.

## 6. Operable by design

- Every request MUST have a correlation ID.
- Important business operations MUST emit structured audit or domain events.
- Health, readiness, metrics, traces, and structured logs are part of the feature, not deployment extras.
- Asynchronous work MUST be retryable and idempotent.

## 7. Prefer simple, reversible decisions

- Use proven framework features before custom infrastructure.
- Start with synchronous REST and database transactions.
- Introduce caches, queues, search engines, and read models only after measuring a bottleneck.
- External providers MUST be wrapped behind ports where replacement risk is material.

## 8. Quality is enforced automatically

- Formatting, static analysis, tests, dependency checks, and migration validation MUST run in CI.
- A pull request MUST be small enough to review meaningfully.
- Critical authorization rules MUST have automated tests.
- No feature is complete without telemetry and failure-state behavior.

## 9. Enterprise does not mean accidental complexity

For Pawket, enterprise-grade means predictable boundaries, security, auditability, testing, deployment, and ownership. It does not mean maximizing the number of layers, services, abstractions, or tools.

