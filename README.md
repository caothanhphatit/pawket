# Pawket

Pawket is a private, long-lived pet profile and memory app. The MVP opens on the camera, lets one user manage multiple pet profiles, publishes pet-tagged memories, and shares those memories with invited pet members.

## MVP scope

Included:

- Flutter client for web, iOS, and Android with camera-first navigation.
- Multiple editable pet profiles, optional onboarding with up to five photos, and quick switching from Profile.
- Camera or photo-library selection, pet tagging, media upload, and memory publishing.
- Per-pet feed and newest-first lifetime memory timeline.
- Reactions, pet members, role-based invitations, and basic member/private visibility.
- Quarkus REST API, PostgreSQL persistence, Flyway migrations, and private S3-compatible media storage.

Not included in this MVP:

- Automatic dog/cat or individual-pet identification.
- Marketplace, buying/selling, payments, or ownership transfer.
- Push notifications, production identity-provider setup, moderation, or production deployment automation.

Local development uses a fixed development user (or `X-User-Id`) while the OIDC integration boundary remains disabled by default.

## Repository layout

```text
pawket/
|- mobile/       Flutter client
|- backend/      Quarkus API
|- discussion/   Product, UX, architecture, and engineering handbook
`- compose.yaml  PostgreSQL and MinIO local services
```

## Requirements

- Docker Engine/Desktop with Docker Compose v2.
- JDK 21. The project has been verified with Temurin `21.0.11`.
- Maven 3.9+ when using a system Maven. The checked-in `backend/mvnw` wrapper is preferred and does not require a separate Maven install.
- Flutter `3.44.6` stable with Dart `3.12.2`.
- Chrome for the quickest local web workflow.

Native mobile runs additionally require the Android SDK or the full iOS toolchain; see [mobile/README.md](./mobile/README.md).

## Run locally

Start PostgreSQL and MinIO from the repository root:

```bash
docker compose up -d postgres minio minio-init
docker compose ps
```

The local services are:

| Service | Address | Local credentials |
| --- | --- | --- |
| PostgreSQL 16 | `localhost:5433`, database `pawket` | `pawket` / `pawket` |
| MinIO S3 API | `http://localhost:9000` | `pawket` / `pawket-local-secret` |
| MinIO console | `http://localhost:9001` | `pawket` / `pawket-local-secret` |

`minio-init` creates the private `pawket-media` bucket. It is expected to finish and exit after initialization.

In terminal 1, start the backend:

```bash
cd backend
./mvnw quarkus:dev
```

The API is available at `http://localhost:8080`; Flyway applies the schema automatically at startup.

In terminal 2, start Flutter web on the CORS-enabled local port:

```bash
cd mobile
flutter pub get
flutter run -d chrome --web-port 4173 \
  --dart-define=PAWKET_API_BASE_URL=http://localhost:8080/api/v1 \
  --dart-define=PAWKET_DEV_USER_ID=00000000-0000-0000-0000-000000000001
```

Open `http://127.0.0.1:4173/` if Flutter does not open it automatically. Keep the backend and Docker services running while using the app.

## Verify the workspace

With PostgreSQL and MinIO running:

```bash
cd backend
./mvnw test
```

Then verify the client:

```bash
cd mobile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Backend health and API discovery are available at:

- `http://localhost:8080/q/health`
- `http://localhost:8080/q/openapi`
- `http://localhost:8080/q/swagger-ui`
- `http://localhost:8080/q/dev/` while Quarkus dev mode is running

## Documentation

- [Product brief](./discussion/product-idea.md)
- [Engineering handbook](./discussion/engineering/README.md)
- [Mobile FE/UX Design V1](./discussion/design/mobile-fe-v1.md)
- [Implementation roadmap](./discussion/engineering/13-implementation-roadmap.md)
- [Backend onboarding](./backend/README.md)
- [Mobile onboarding](./mobile/README.md)
