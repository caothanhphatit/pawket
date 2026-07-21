# Pull Request Checklist

## Context

- Linked issue:
- User or system behavior changed:
- Risk level: low / medium / high

## Author checklist

- [ ] Scope is focused and unrelated changes are excluded.
- [ ] Architecture boundaries and DI rules are respected.
- [ ] Authentication and authorization paths were reviewed.
- [ ] API compatibility and mobile minimum-version impact were reviewed.
- [ ] Database migration follows expand-migrate-contract where required.
- [ ] Personal data, logs, analytics, and third-party SDK impact were reviewed.
- [ ] Unit/integration/widget tests cover changed behavior and failure paths.
- [ ] Formatting, analysis, tests, and generated-code checks pass locally.
- [ ] Telemetry and operational failure behavior are included.
- [ ] Documentation and ADRs are updated where required.
- [ ] Screenshots or recordings are attached for visible UI changes.
- [ ] Rollout, feature flag, rollback, or forward-fix plan is documented where relevant.

## Reviewer checklist

- [ ] Domain behavior and acceptance criteria are correct.
- [ ] Access cannot be gained through alternate IDs, nested routes, or stale membership.
- [ ] Transactions and concurrent updates preserve invariants.
- [ ] Errors are safe, stable, and actionable.
- [ ] Tests verify behavior rather than implementation details only.
- [ ] Change remains understandable and operable by the owning team.

