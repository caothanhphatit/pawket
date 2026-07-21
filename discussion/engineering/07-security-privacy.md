# Security and Privacy Policy

## Security model

Pawket stores personal accounts, social relationships, pet profiles, and private media. Security and privacy are product requirements.

Core rules:

- Authenticate every non-public endpoint.
- Authorize every resource operation server-side.
- Grant minimum access for the minimum duration.
- Keep media private by default.
- Minimize collected data and retention.
- Audit sensitive administrative and membership changes.

## Authentication

- Use a managed OIDC provider for the initial platform.
- Validate signature, issuer, audience, expiry, and token type.
- Use issuer plus subject as the stable external identity.
- Email is an attribute, not an authorization identity.
- Refresh credentials MUST be stored using platform secure storage on mobile.
- Logout MUST clear user-scoped cache, tokens, drafts containing private data, and notification registration as appropriate.
- Production admin access MUST require MFA.

## Authorization

Pawket uses relationship-based authorization centered on active pet membership.

| Capability | Owner | Caretaker | Follower |
| --- | --- | --- | --- |
| View permitted pet profile | Yes | Yes | Yes |
| View permitted timeline | Yes | Yes | Yes |
| Publish to pet timeline | Yes | Yes | No by default |
| Edit core pet profile | Yes | Limited or no | No |
| Invite members | Yes | No by default | No |
| Change roles | Yes | No | No |
| Transfer ownership | Future controlled flow | No | No |
| Delete pet profile | Controlled owner flow | No | No |

- Permissions MUST be evaluated from current server data, not token claims copied from an old membership state.
- Listing endpoints MUST filter inaccessible records at query time.
- Authorization checks MUST cover every pet tagged in a post.
- The system SHOULD return `404` instead of `403` where revealing existence creates privacy risk.
- Admin bypass behavior MUST be explicit, audited, and unavailable to normal application roles.

## Privacy classification

| Class | Examples | Handling |
| --- | --- | --- |
| Public | Published app metadata | Standard integrity controls |
| Internal | Operational dashboards, non-sensitive configuration | Team access only |
| Confidential | User profile, memberships, private captions, device tokens | Encrypted, access controlled, redacted in logs |
| Restricted | Auth secrets, signing keys, provider credentials, deletion exports | Secret manager, narrow audited access |

Pet media is `Confidential` by default even if the product later supports public posts.

## Data minimization

- Collect only fields required by a shipped feature.
- Location metadata MUST be removed from media unless a separately approved feature requires it with explicit consent.
- Do not collect contacts, precise location, health data, or government identifiers in the MVP.
- Analytics events MUST use internal opaque IDs and MUST NOT include captions, names, emails, signed URLs, or media content.
- Every new third-party SDK requires security and privacy review.

## Media security

- Buckets are private and block public ACLs.
- Signed upload URLs allow only one generated key, expected method, bounded size, and short TTL.
- Signed read URLs use short TTL and are issued only after authorization.
- Validate MIME type using content inspection, not file extension alone.
- Define allowed image formats and maximum dimensions/size before implementation.
- Malware scanning and image normalization SHOULD be added before accepting broader file types or public sharing.
- Orphaned and rejected uploads MUST be removed by a scheduled retention job.

## Application security controls

- Validate all input on server boundaries.
- Use parameterized ORM/query APIs; raw SQL requires review and parameters.
- Apply request body limits and upload intent limits.
- Apply rate limiting to login-adjacent flows, invitations, media intents, reactions, and abusive reads.
- Configure CORS narrowly for any web-accessible endpoint.
- Outbound HTTP MUST use allowlisted configured destinations; user input MUST NOT control arbitrary server fetch URLs.
- Deep links and invitation tokens MUST be single-purpose, expiring, revocable, and stored hashed.

## Secrets policy

- Secrets MUST NOT be committed, placed in sample files with real values, printed in CI, or sent through chat.
- Local development uses ignored environment files or development secret tooling.
- Production secrets come from a managed secret store.
- Secrets have named owners and rotation procedures.
- A leaked secret is rotated immediately; deleting it from the latest Git commit is insufficient.

## Logging policy

Never log:

- Access or refresh tokens.
- Authorization headers.
- Passwords or provider secrets.
- Signed media URLs.
- Invitation raw tokens.
- Full email addresses unless an approved operational requirement masks or hashes them.
- Captions, pet names, or raw request bodies by default.

Security logs SHOULD include actor ID, action, resource ID, result, correlation ID, timestamp, and safe reason code.

## Dependency and supply-chain policy

- Dependencies MUST come from trusted registries and be pinned through lock/build files.
- CI MUST run vulnerability scanning and secret scanning.
- Critical exploitable vulnerabilities block release unless the security owner documents mitigation and expiry.
- Generated SBOMs SHOULD accompany production backend artifacts.
- Third-party packages with broad device permissions require explicit review.

## Privacy rights and deletion

Before public launch, Pawket MUST define and test:

- Account data export.
- Account deletion and retention period.
- Shared post ownership after one member deletes an account.
- Pet profile deletion when multiple owners exist.
- Backup expiration behavior.
- Support verification process that does not expose private data.

## Incident response

1. Detect and record incident start time.
2. Assign incident commander and severity.
3. Contain access or disable affected capability.
4. Preserve relevant audit evidence.
5. Rotate compromised credentials.
6. Assess affected users and notification obligations.
7. Restore safely and monitor.
8. Publish a blameless post-incident review with owners and deadlines.

Security exceptions require an owner, risk statement, mitigation, approval, and expiration date.

