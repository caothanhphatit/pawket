# Pawket Backend

Quarkus `3.37.3` modular-monolith API for Pawket's pet profiles, memberships, memories, media, feed, reactions, and invitations.

## Requirements

- JDK 21 (verified with Temurin `21.0.11`).
- Docker Engine/Desktop with Docker Compose v2 for PostgreSQL and MinIO.
- Use the checked-in Maven wrapper, `./mvnw`. A system Maven installation is optional; use Maven 3.9+ if needed.

Verify Java before starting:

```bash
java -version
./mvnw -version
```

If JDK 21 is installed but is not the active JDK, set `JAVA_HOME` before running Maven. On the current macOS development setup it is installed at:

```bash
export JAVA_HOME="$HOME/.local/share/jdks/jdk-21.0.11+10/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
```

## Local infrastructure

From the repository root:

```bash
docker compose up -d postgres minio minio-init
docker compose ps
```

This starts:

- PostgreSQL 16 at `localhost:5433`, database/user/password `pawket`.
- MinIO at `http://localhost:9000` and its console at `http://localhost:9001`.
- A private S3-compatible bucket named `pawket-media`.

Port `5433` is intentional so Pawket does not collide with a PostgreSQL instance on the usual host port `5432`.

## Run in development

```bash
cd backend
./mvnw quarkus:dev
```

The backend listens on `http://localhost:8080`. Flyway runs `src/main/resources/db/migration` automatically and Hibernate validates the migrated schema.

Useful development endpoints:

- Health: `http://localhost:8080/q/health`
- Readiness: `http://localhost:8080/q/health/ready` (checks PostgreSQL and the private object-storage bucket).
- OpenAPI: `http://localhost:8080/q/openapi`
- Swagger UI: `http://localhost:8080/q/swagger-ui`
- Quarkus Dev UI: `http://localhost:8080/q/dev/`

## Local authentication

OIDC is disabled by default for local development. Requests run as the seeded user:

```text
00000000-0000-0000-0000-000000000001
```

Set another development identity with the `X-User-Id` request header or the `DEV_USER_ID` environment variable. `X-Correlation-Id` is also accepted for request tracing. This mechanism is development-only; production must enable and configure OIDC.

## API capabilities

All application endpoints are under `/api/v1`:

- Current user: `GET /users/me`.
- Portable user export: authenticated `GET /users/me/export`. The JSON export contains the current user, accessible pet profiles and memberships, authored memories with pet/media metadata, and reactions created by the user. It intentionally excludes signed URLs, storage keys, invitation tokens, identity-provider claims, and credentials.
- Pets: list, create, read, update, and list members.
- Media: create a signed upload intent, upload directly to private S3-compatible storage, complete/verify the upload, and authorize content access.
- Memories: create/read posts, retrieve a cursor-paginated feed, and retrieve each pet's cursor-paginated timeline.
- Reactions: upsert or remove the current user's reaction to a post.
- Invitations: owner-created role invitations, token preview, and acceptance.

Authorization is membership-based. Owners and caretakers can edit pet data; followers are read-only. Reads and multi-pet posts are checked against active memberships, and media remains in the private bucket behind authorized signed downloads.

## Configuration

Defaults are defined in `src/main/resources/application.properties` and can be overridden with environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `DB_URL` | `jdbc:postgresql://localhost:5433/pawket` | JDBC connection URL |
| `DB_USERNAME` / `DB_PASSWORD` | `pawket` / `pawket` | Database credentials |
| `OIDC_ENABLED` | `false` | Enable the production authentication boundary |
| `DEV_USER_ID` | seeded development UUID | Default local actor |
| `S3_ENDPOINT` | `http://localhost:9000` | Internal S3-compatible endpoint |
| `S3_PUBLIC_ENDPOINT` | `http://localhost:9000` | Endpoint embedded in client-facing signed URLs |
| `S3_REGION` | `us-east-1` | Signing region |
| `S3_BUCKET` | `pawket-media` | Private media bucket |
| `S3_ACCESS_KEY` / `S3_SECRET_KEY` | local MinIO credentials | Storage credentials |
| `S3_UPLOAD_TTL` | `10M` | Signed upload lifetime |

User exports are bounded to 500 accessible pets, 10,000 authored memories, 20,000 media records, 50,000 pet tags, and 20,000 reactions per request. Larger accounts receive `EXPORT_TOO_LARGE` instead of a partial export.

The local web CORS allowlist contains `http://127.0.0.1:4173` and `http://localhost:4173`.

## Test and build

Run tests with the local infrastructure available:

```bash
./mvnw test
```

Compile without tests:

```bash
./mvnw -DskipTests compile
```

Build the runnable Quarkus application:

```bash
./mvnw package
java -jar target/quarkus-app/quarkus-run.jar
```

Native packaging is optional and requires GraalVM, or a working container runtime for Quarkus container builds:

```bash
./mvnw package -Dnative -Dquarkus.native.container-build=true
```

## MVP boundaries

This service intentionally does not yet implement AI pet identification, marketplace/payment flows, ownership transfer, push notifications, moderation tooling, or production identity-provider/deployment configuration.

Architecture, security, API, data, and coding policies are maintained in [the engineering handbook](../discussion/engineering/README.md).
