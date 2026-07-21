# Pawket Mobile

Flutter client for Pawket, targeting web, iOS, and Android. The app starts on the camera and uses the center bottom-bar action to move vertically between Camera and Home; Feed and Profile are horizontal destinations.

## Implemented MVP

- Camera and photo-library selection with a memory composer.
- One owner with multiple pet profiles and a persisted active-pet selection.
- Pet creation with zero to five optional first memories, live profile editing, and Profile-based pet switching.
- Feed, Home highlights, and newest-first per-pet memory grid.
- Remote pet, media, post, feed/timeline, reaction, membership, and invitation data layers.
- Pet members, invitation creation/acceptance, reactions, loading/error states, and an offline pet fallback.
- Riverpod dependency injection/state management, GoRouter navigation, and Dio networking.

AI identification, marketplace/payment flows, ownership transfer, notifications, and production authentication are outside the current MVP.

## Toolchain

- Flutter `3.44.6` stable.
- Dart `3.12.2`.
- Flutter SDK location on the current development machine: `~/.local/share/flutter`.

Verify the installation:

```bash
flutter --version
flutter doctor -v
```

## Backend dependency

The client expects the Pawket backend and its PostgreSQL/MinIO services to be running. From the repository root:

```bash
docker compose up -d postgres minio minio-init
cd backend
./mvnw quarkus:dev
```

See [backend/README.md](../backend/README.md) for backend configuration and API details.

## Run on web

From `mobile/`:

```bash
flutter pub get
flutter run -d chrome --web-port 4173 \
  --dart-define=PAWKET_API_BASE_URL=http://localhost:8080/api/v1 \
  --dart-define=PAWKET_DEV_USER_ID=00000000-0000-0000-0000-000000000001
```

The fixed port is required by the backend's local CORS allowlist. The API URL defaults to `http://localhost:8080/api/v1`, but keeping the define explicit makes the selected environment clear.

`PAWKET_DEV_USER_ID` sends the development-only `X-User-Id` header. Omit it to let the backend use its configured default development user. Production builds must use the OIDC token integration instead.

## Native prerequisites

Flutter analysis, tests, and the web app do not require native SDKs. Native execution additionally requires:

- Android: Android Studio or Android command-line SDK, platform tools, an emulator/device, and accepted SDK licenses.
- iOS: macOS, full Xcode installation, completed first-run setup, an iOS simulator/device, and CocoaPods for native plugins.

After installing full Xcode:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo gem install cocoapods
```

For an Android emulator, use `10.0.2.2` to reach the backend running on the host:

```bash
flutter run -d <android-device-id> \
  --dart-define=PAWKET_API_BASE_URL=http://10.0.2.2:8080/api/v1 \
  --dart-define=PAWKET_DEV_USER_ID=00000000-0000-0000-0000-000000000001
```

The iOS simulator can normally use `http://localhost:8080/api/v1`. A physical device must use the development machine's LAN address; run Quarkus on all interfaces for that workflow:

```bash
./mvnw -Dquarkus.http.host=0.0.0.0 quarkus:dev
```

Then pass `http://<development-machine-ip>:8080/api/v1` as `PAWKET_API_BASE_URL`. Do not expose the development backend to an untrusted network.

## Quality checks

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

To apply formatting during development, use:

```bash
dart format lib test
```

## Architecture

The client uses a feature-first layered structure:

```text
lib/
|- app/          Bootstrap, routing, theme, and shared shell
|- core/         API configuration, networking, and shared infrastructure
`- features/     Feed, home, pets, posts, media, reactions, memberships, and invitations
```

- Riverpod composes repositories and owns application state.
- GoRouter owns camera-first navigation and route transitions.
- Dio calls the Quarkus API and uses a separate uncredentialed client for signed storage uploads.
- The active pet is one concrete profile; there is no combined `All pets` context.
- Profile is the pet-switching surface and displays the pet's newest memories in a uniform grid.

Implementation rules are defined in [mobile architecture](../discussion/engineering/04-mobile-architecture.md) and [FE/UX Design V1](../discussion/design/mobile-fe-v1.md).
