# Governance and Architecture Decisions

## Decision ownership

- Product owns user outcomes, scope, and acceptance criteria.
- Engineering owns implementation quality, estimates, operability, and technical risk.
- The architect or technical lead owns system-wide coherence and records major decisions.
- Security/privacy owners approve material identity, authorization, data collection, and third-party SDK changes.
- Module owners maintain boundaries and review relevant changes.

Ownership is accountability, not unilateral authority. Material decisions are reviewed by affected disciplines.

## When an ADR is required

Create an Architecture Decision Record for:

- New runtime, framework, database, queue, cache, search engine, or external platform.
- Change to module boundaries or dependency direction.
- Authentication or authorization model changes.
- New class of personal/sensitive data.
- Breaking API or data model strategy.
- Migration from monolith toward services.
- Cross-cutting design pattern or convention exception.
- Material build, deployment, or observability change.

An ADR is not required for routine implementation that follows existing standards.

## ADR lifecycle

Statuses:

- `Proposed`
- `Accepted`
- `Rejected`
- `Superseded`
- `Deprecated`

Rules:

- ADRs are immutable historical records after acceptance, except status and links.
- A new ADR supersedes an old decision; do not rewrite history.
- Decisions include context, options, consequences, risks, and migration plan.
- Time-sensitive decisions include a review date.
- ADR files use `NNNN-short-title.md` under `discussion/engineering/adrs/`.

## Architecture fitness checks

The team SHOULD automate rules that can drift:

- Backend package/module dependency tests.
- No REST-to-persistence direct dependency.
- No field injection.
- No JPA entities in public API DTOs.
- Mobile feature domain has no Flutter/Dio dependency.
- OpenAPI breaking-change detection.
- Flyway immutability and validation.
- Dependency and secret scanning.

Java module rules may be enforced with architecture tests such as ArchUnit if adopted. Dart import boundaries may be enforced by lints and repository scripts.

## Exceptions

An exception to a `MUST` rule requires:

- Rule being bypassed.
- Business or technical reason.
- Risk and affected scope.
- Compensating control.
- Owner.
- Expiration or review date.
- Approval from the accountable owner.

Permanent exceptions SHOULD become ADRs or handbook updates.

## Technical debt policy

- Technical debt is recorded with impact, trigger, and proposed resolution.
- Security, data-loss, and operational debt receives higher priority than aesthetic refactoring.
- Temporary compatibility code and feature flags require removal criteria.
- Refactoring is included in feature work when necessary to preserve a boundary; unrelated broad cleanup is separate.

## Documentation policy

- Code explains local mechanics; documentation explains system intent, contracts, and operations.
- A change that invalidates documentation MUST update it in the same pull request.
- Diagrams MUST be source-controlled as text where practical.
- Runbooks are verified during drills and incidents.
- Documentation has an owner and last-review expectation through repository history and scheduled review.

