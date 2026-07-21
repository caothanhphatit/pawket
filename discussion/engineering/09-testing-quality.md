# Testing and Quality Strategy

## Quality gates

A change MUST NOT merge unless:

- Formatting and static analysis pass.
- Relevant unit and integration tests pass.
- API contract and database migration checks pass where affected.
- No unresolved critical security issue is introduced.
- Changed behavior has appropriate automated coverage.
- The pull request meets the Definition of Done.

Coverage percentage is a signal, not the objective. Critical domain and authorization paths require explicit scenario coverage regardless of aggregate percentage.

## Test pyramid

```text
Few end-to-end tests
More API, database, and widget integration tests
Many fast domain, use-case, controller, and unit tests
```

## Backend tests

### Unit tests

Use for:

- Domain invariants.
- Role and permission decisions.
- State transitions.
- Application use-case orchestration with fake ports.
- Error mapping and pure utility behavior.

Unit tests MUST be deterministic and MUST NOT require Quarkus boot, network, wall-clock time, or shared database state.

### Integration tests

Use Quarkus test support and Testcontainers for:

- Repository queries and mappings.
- PostgreSQL constraints and transactions.
- Flyway migration from supported schema states.
- REST authentication and authorization.
- JSON and problem response contracts.
- Idempotency and optimistic concurrency.
- Object-storage adapter behavior through a controlled compatible service when practical.

Do not replace important PostgreSQL behavior with an unrelated in-memory database.

### Contract tests

- OpenAPI generation MUST be stable and validated in CI.
- Breaking contract diffs require explicit review.
- Error codes and required fields are part of the contract.
- Mobile client parsing tests SHOULD use representative recorded contract fixtures without sensitive data.

## Mobile tests

### Unit tests

- Domain models and validation.
- Repository mapping.
- Riverpod controllers/notifiers.
- Retry and error translation behavior.
- Pet selection and session reset logic.

### Widget tests

- Loading, empty, content, failure, offline, and access-denied states.
- Pet switcher behavior for zero, one, and multiple pets.
- Form validation and accessibility labels.
- Navigation for authentication and invitation links.

### Integration tests

Maintain a small set of high-value flows:

1. Sign in and create first pet without an image.
2. Create multiple pets and switch active pet.
3. Upload media, tag multiple pets, and publish.
4. View a pet timeline and all-pets feed.
5. Handle expired session and recover.

Run on at least one supported iOS and Android configuration before release.

### Visual regression

Golden tests MAY protect stable design-system components and critical screens. They SHOULD NOT become a high-maintenance snapshot of every widget.

## Security tests

Mandatory authorization scenarios include:

- Unauthenticated user cannot access protected endpoints.
- User cannot read or mutate an unrelated pet.
- Caretaker cannot perform owner-only actions.
- Follower cannot publish by default.
- User cannot publish media owned by another user.
- User cannot tag an inaccessible pet.
- Removed membership loses access immediately.
- Expired/revoked invitation cannot be accepted.
- Signed media access cannot be requested without current authorization.

## Performance tests

Before public launch, establish baseline tests for:

- Timeline query with realistic membership, post, media, and reaction volume.
- Create-post transaction.
- Signed media intent creation.
- Authentication token validation under expected concurrency.

Performance changes MUST be measured with representative data. Microbenchmarks do not replace database/API load tests.

## Test data

- Tests create their own data and clean up or use isolated containers.
- Tests MUST NOT depend on execution order.
- Production personal data MUST NOT be used.
- Builders and fixtures SHOULD express domain intent, for example `anActiveOwner()`.
- Avoid giant shared fixtures that hide scenario-specific state.

## Defect policy

- Every production defect receives a regression test when technically feasible.
- Critical defects and security issues require root-cause review.
- Flaky tests are defects: quarantine only with owner, issue, and short expiry.
- Disabling a quality gate requires documented temporary exception and deadline.

