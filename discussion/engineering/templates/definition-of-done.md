# Definition of Done

A product increment is done only when all applicable items are true.

## Product

- [ ] Acceptance criteria are met.
- [ ] Loading, empty, failure, offline, permission-denied, and retry behavior are defined.
- [ ] Analytics or product metrics are documented without private payloads.

## Engineering

- [ ] Code follows module boundaries, conventions, and DI rules.
- [ ] API and data contracts are reviewed for compatibility.
- [ ] Required migrations are safe and tested.
- [ ] Automated tests cover success, validation, authorization, and material failure paths.
- [ ] No critical static-analysis, dependency, secret, or security finding remains.

## Security and privacy

- [ ] Data collection and retention are minimal and documented.
- [ ] Authorization is enforced on the backend.
- [ ] Logs and telemetry contain no secrets or unnecessary personal data.
- [ ] New permissions, providers, SDKs, and deep links were reviewed.

## Operations

- [ ] Logs, metrics, traces, and correlation are sufficient to diagnose failure.
- [ ] Alerts/runbooks are updated for a new operational failure mode.
- [ ] Rollout and rollback or forward-fix behavior is documented.
- [ ] Feature flags have owner and removal/review criteria.

## Delivery

- [ ] CI is green.
- [ ] Required reviewers approved.
- [ ] User-facing and architecture documentation is current.
- [ ] The change is deployable independently or safely hidden until complete.

