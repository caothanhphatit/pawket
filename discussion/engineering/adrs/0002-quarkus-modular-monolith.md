# ADR 0002: Quarkus modular monolith

- Status: Accepted
- Date: 2026-07-18
- Owners: Pawket engineering
- Reviewers: Product and technical lead
- Review date: When measured scaling or team boundaries challenge a single deployment
- Supersedes: N/A

## Context

Pawket needs centralized domain rules for pet membership, private media, timeline access, invitations, and future ownership transfer. The team selected Java and wants strong typing, mature database tooling, testability, and operational controls without early distributed-system overhead.

## Decision drivers

- Java 21 team capability.
- Fast startup and efficient container operation.
- Mature REST, OIDC, PostgreSQL, migration, testing, and observability integration.
- Explicit domain boundaries without microservices.
- A path to extract modules only when evidence justifies it.

## Considered options

### Quarkus modular monolith

One deployable Java application with domain modules and clean dependency rules.

### Backend as a service

Faster initial CRUD but less direct control over application authorization and long-term domain workflows.

### Microservices

Independent services but substantially greater delivery, consistency, observability, and operations cost.

## Decision

Use Java 21 and Quarkus as a modular monolith backed by PostgreSQL. Use imperative Hibernate ORM, Flyway, REST/OpenAPI, and ports/adapters around material external providers.

## Consequences

### Positive

- One transaction boundary for core membership and post invariants.
- Simple deployment and local development.
- Clear module ownership and future extraction seams.

### Negative and risks

- Module boundaries require active enforcement inside one codebase.
- A poorly governed shared package could create coupling.
- Scaling is initially at application level rather than per business module.

## Security, privacy, and data impact

The backend is the sole authority for Pawket permissions. Persistence and media metadata remain centrally auditable.

## Delivery and migration

Create the application under `backend/`, establish package-boundary tests, and deploy one immutable container artifact per release.

## Validation

Review module coupling, deployment performance, database load, team ownership, and release frequency before considering service extraction.

