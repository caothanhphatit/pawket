# Git and Delivery Workflow

## Branching model

Use trunk-based development with short-lived branches.

- `main` is always releasable.
- Feature branches use `feat/<issue>-short-name`.
- Fix branches use `fix/<issue>-short-name`.
- Architecture or maintenance work may use `chore/<issue>-short-name`.
- Branches SHOULD live less than three working days; larger work is split behind safe seams or feature flags.
- Direct pushes to `main` are prohibited.

## Commit policy

Use concise Conventional Commit subjects:

```text
feat(pets): create pet and owner membership
fix(media): reject expired upload intent
docs(architecture): record identity provider decision
```

- Commits SHOULD be logically coherent and buildable.
- Generated code MAY be isolated in its own commit when that improves review.
- Do not include secrets, production data, or unrelated formatting changes.
- History rewriting on shared branches is prohibited.

## Pull requests

- Link the product or engineering issue.
- Explain behavior, risk, data/API impact, and verification.
- Include screenshots or recordings for visible mobile changes.
- Include migration and rollback/forward-fix notes for schema changes.
- Keep changes focused; unrelated refactors require separate pull requests.
- At least one qualified reviewer is required; security, architecture, or data-sensitive changes require the relevant code owner.
- Authors MUST resolve discussion with evidence or documented agreement, not silently dismiss material findings.

## Review ownership

Recommended CODEOWNERS areas:

- Backend core and migrations: backend owners.
- Mobile app architecture and design system: mobile owners.
- Authentication, authorization, secrets, and privacy: security owner.
- API and shared domain contracts: backend plus mobile reviewer.
- Architecture handbook and ADRs: technical lead or architect.

No individual may be the sole required reviewer for every area; ownership needs redundancy.

## CI pipeline

### Pull request checks

Backend:

1. Compile and format verification.
2. Static analysis.
3. Unit tests.
4. PostgreSQL integration tests.
5. Flyway validation.
6. OpenAPI generation and breaking-change check.
7. Dependency, license, and secret scan.
8. Container build smoke test.

Mobile:

1. Flutter/Dart version verification.
2. `dart format` verification.
3. `flutter analyze`.
4. Unit and widget tests.
5. Generated-code drift check.
6. Android debug build.
7. iOS build on an appropriate runner.
8. Dependency and secret scan.

### Main branch

- Build immutable backend image tagged by commit SHA.
- Generate SBOM and provenance where supported.
- Publish internal mobile artifacts.
- Deploy automatically to development.
- Run smoke tests and selected integration tests.

## Environments

```text
local -> development -> staging -> production
```

- Each environment has separate database, storage, OIDC configuration, and secrets.
- Production credentials MUST NOT work in non-production.
- Staging SHOULD mirror production topology and configuration categories without using production data.
- Environment promotion uses the same immutable artifact; do not rebuild different code for production.

## Release policy

### Backend

- Use backward-compatible API and database changes for rolling deployment.
- Deployment automatically checks readiness and migration outcome.
- Failed health or smoke checks stop promotion.
- Rollback is allowed only when database compatibility is preserved; otherwise forward-fix.

### Mobile

- Use semantic app versions and monotonically increasing platform build numbers.
- Backend MUST support the documented minimum mobile version.
- Forced upgrade requires product and engineering approval and is reserved for security or incompatible behavior.
- Roll out in stages when store tooling permits.
- Feature flags SHOULD separate deployment from release for risky capabilities.

## Database delivery

- Flyway runs as a controlled deployment step or single designated instance, not concurrently from every replica without a verified strategy.
- Long locks and full-table rewrites require rehearsal with representative volume.
- Backfills run separately when they may exceed normal deployment time.
- Every destructive migration includes evidence that old application versions no longer depend on the removed schema.

## Rollback and recovery

Every release plan answers:

- Can the previous backend run against the new schema?
- Can the current mobile app run against both backend versions during rollout?
- Which feature flag disables the new behavior?
- Is data transformation reversible or forward-fix only?
- How will the team confirm recovery?

## Hotfixes

- Branch from current production commit.
- Apply the smallest safe fix with regression test.
- Use normal review and automated gates; severity may shorten review time but does not remove controls.
- Merge the hotfix back to `main` immediately.

