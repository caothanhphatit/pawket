# Pawket Engineering Handbook

## Purpose

This handbook is the implementation contract for the Pawket engineering team. It translates the product brief into enforceable architecture, coding, security, quality, and delivery rules.

Normative language:

- `MUST` and `MUST NOT` are mandatory and require an approved ADR to bypass.
- `SHOULD` and `SHOULD NOT` are defaults; deviations require a documented reason in the pull request.
- `MAY` is optional.

## System baseline

| Area | Decision |
| --- | --- |
| Mobile | Flutter and Dart, one codebase for iOS and Android |
| Backend | Java 21 and Quarkus, modular monolith |
| API | JSON REST API described by OpenAPI |
| Database | PostgreSQL with Flyway migrations |
| Media | Private S3-compatible object storage with signed URLs |
| Identity | Managed OIDC provider; Pawket maps external subjects to internal users |
| Push | Firebase Cloud Messaging, with APNs delivery for iOS |
| Delivery | Docker for backend; standard Flutter store builds for mobile |

## Document map

1. [Architecture principles](./01-architecture-principles.md)
2. [System architecture](./02-system-architecture.md)
3. [Backend architecture](./03-backend-architecture.md)
4. [Mobile architecture](./04-mobile-architecture.md)
5. [Data architecture](./05-data-architecture.md)
6. [API standards](./06-api-standards.md)
7. [Security and privacy](./07-security-privacy.md)
8. [Coding conventions](./08-coding-conventions.md)
9. [Testing and quality](./09-testing-quality.md)
10. [Git and delivery workflow](./10-git-delivery.md)
11. [Operations and observability](./11-operations-observability.md)
12. [Governance and ADRs](./12-governance-adrs.md)
13. [Implementation roadmap](./13-implementation-roadmap.md)

Templates:

- [ADR template](./templates/adr-template.md)
- [Pull request checklist](./templates/pull-request-checklist.md)
- [Definition of Done](./templates/definition-of-done.md)

## Authority and change control

The product brief defines what Pawket should achieve. This handbook defines how the team builds and operates it. If documents conflict, apply this priority:

1. Legal, privacy, and security obligations.
2. Approved Architecture Decision Records.
3. This handbook.
4. Module-level README files.
5. Individual implementation preferences.

Architecture rules are reviewed at least once per quarter and before any major platform or data model change.

