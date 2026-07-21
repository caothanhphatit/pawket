# ADR 0001: Flutter for the mobile client

- Status: Accepted
- Date: 2026-07-18
- Owners: Pawket engineering
- Reviewers: Product and technical lead
- Review date: After the first production release
- Supersedes: N/A

## Context

Pawket requires iOS and Android applications with camera/library access, media upload, timelines, pet switching, push notifications, and an intentional visual experience. The initial team should avoid maintaining two separate mobile implementations.

## Decision drivers

- One shared mobile codebase.
- Strong control over custom UI and motion.
- Adequate camera, media, secure storage, deep-link, and notification support.
- Testable feature architecture.
- Reasonable delivery speed for a small team.

## Considered options

### Flutter

One Dart codebase with consistent rendering and a mature cross-platform ecosystem.

### React Native

Strong ecosystem and good fit for teams centered on TypeScript and React.

### Native Swift and Kotlin

Maximum platform control at the cost of two implementations and higher coordination overhead.

## Decision

Use Flutter for the Pawket iOS and Android client. Use a feature-first layered architecture, Riverpod for dependency injection/state management, and GoRouter for navigation.

## Consequences

### Positive

- Shared implementation and design system.
- Fast iteration across both platforms.
- Native escape hatches remain available for exceptional platform requirements.

### Negative and risks

- Team must maintain Dart/Flutter expertise.
- Some platform capabilities may require native integration.
- Package selection requires supply-chain and maintenance review.

## Security, privacy, and data impact

Tokens use platform secure storage. Media permissions are requested just in time. GPS EXIF data is removed before upload unless a future approved feature requires it.

## Delivery and migration

Create the app under `mobile/`, pin the Flutter toolchain, and establish Android/iOS CI builds before feature development.

## Validation

Validate camera, library picker, upload, deep links, push notifications, accessibility, and crash-free sessions on supported iOS and Android versions.

