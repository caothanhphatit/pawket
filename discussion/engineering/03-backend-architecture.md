# Backend Architecture

## Technology baseline

- Java 21.
- Current supported Quarkus 3.x version pinned by the build.
- Maven Wrapper; developers and CI MUST invoke `./mvnw`.
- Quarkus REST and Jackson for HTTP and JSON.
- Hibernate ORM with PostgreSQL.
- Flyway for schema migrations.
- SmallRye OpenAPI, Health, Metrics, and OpenTelemetry.
- JUnit 5, RestAssured, and Testcontainers.

The team MUST NOT use both reactive and imperative persistence styles in the same application. Start with imperative Hibernate ORM. Revisit only through an ADR backed by load evidence.

## Module boundaries

Recommended modules inside one deployable application:

```text
com.pawket
|- identity
|- users
|- pets
|- memberships
|- posts
|- media
|- reactions
|- invitations
|- notifications
|- audit
`- shared
```

`shared` MUST contain only stable cross-cutting primitives such as IDs, time abstractions, pagination, and error types. It MUST NOT become a bucket for unrelated business logic.

Each business module follows this structure:

```text
module/
|- domain/
|  |- model/
|  |- event/
|  `- service/
|- application/
|  |- command/
|  |- query/
|  |- port/in/
|  `- port/out/
`- adapter/
   |- in/rest/
   `- out/persistence/
```

Package visibility SHOULD prevent other modules from importing adapter and persistence internals.

## Dependency injection

Quarkus Arc CDI is the only application DI container.

- Constructor injection MUST be used.
- Field injection MUST NOT be used in production code.
- Dependencies MUST be `final` where Java permits.
- Interfaces SHOULD exist at architectural boundaries or when multiple implementations are meaningful, not for every class.
- CDI scopes MUST be explicit for application services and adapters.
- Business services SHOULD be `@ApplicationScoped` and stateless.
- Request-specific mutable state MUST NOT be stored in application-scoped beans.
- Direct calls to `Arc.container()` and service locator patterns MUST NOT be used.
- Static access to repositories, clocks, identity, configuration, or providers MUST NOT be used.

Example:

```java
@ApplicationScoped
final class CreatePetService implements CreatePetUseCase {
    private final PetRepository pets;
    private final MembershipRepository memberships;
    private final Clock clock;

    CreatePetService(
            PetRepository pets,
            MembershipRepository memberships,
            Clock clock) {
        this.pets = pets;
        this.memberships = memberships;
        this.clock = clock;
    }
}
```

## Domain model rules

- Domain objects enforce invariants and expose behavior, not public mutable fields.
- Value objects SHOULD represent concepts such as `PetId`, `UserId`, `PostId`, `Visibility`, and `MembershipRole` where they prevent invalid mixing.
- Use Java records for immutable DTOs and simple value objects when appropriate.
- Domain code MUST accept a `Clock` or explicit time; it MUST NOT call `Instant.now()` directly.
- Monetary values, if introduced later, MUST use `BigDecimal` plus currency, never `double`.
- Exceptions MUST represent exceptional failures; expected validation outcomes SHOULD use typed results or mapped domain exceptions consistently.

## Application layer rules

- A command use case changes state and defines its transaction boundary.
- A query use case returns a read model and MUST NOT change domain state.
- Use cases receive the authenticated actor through an explicit application abstraction.
- Every mutation MUST perform authorization before state change.
- Bulk operations MUST define partial-failure semantics explicitly.
- External side effects MUST occur after a durable state decision or through an outbox-style mechanism when delivery matters.

## Persistence rules

- Persistence entities stay inside persistence adapters.
- REST DTOs and domain objects MUST NOT be JPA entities.
- Repositories MUST return domain models or application projections.
- Every table uses a stable primary key; UUIDv7 is preferred when support is standardized, otherwise UUID with an ADR.
- Store timestamps as UTC `timestamptz` and expose ISO 8601.
- Optimistic locking SHOULD protect concurrently edited aggregates.
- Collection queries MUST be paginated and must not create N+1 access patterns.
- Database constraints MUST enforce critical invariants in addition to application validation.

## Transactions

- Transaction boundaries belong to application command services.
- REST resources MUST NOT open transactions.
- Transactions MUST be short and MUST NOT include object-storage or push-provider network calls.
- A command that creates a pet and owner membership MUST commit both or neither.
- Retryable transaction behavior MUST be idempotent.

## Patterns to use

- Ports and adapters for external systems and persistence.
- Repository per aggregate or cohesive query boundary.
- Application command/query separation without introducing a framework-heavy CQRS platform.
- Strategy for replaceable provider behavior.
- Factory for creation with non-trivial invariants.
- Outbox for reliable asynchronous integration when required.

## Patterns to avoid

- Generic base repositories exposed across all modules.
- Active Record entities used directly by REST resources.
- Service classes containing unrelated CRUD for an entire module.
- Deep inheritance hierarchies.
- An interface plus implementation pair with no boundary or variation reason.
- Event sourcing, distributed sagas, or microservices without a concrete requirement.

## REST adapter rules

- Resource classes map HTTP to application use cases only.
- Request DTOs use Bean Validation.
- Entity IDs and authenticated actors MUST come from trusted resolved context, not request claims such as `ownerId`.
- Central exception mapping produces the standard problem response.
- Resources MUST NOT expose stack traces, database messages, bucket keys, or provider details.

## Configuration

- Configuration MUST be typed with Quarkus config mappings.
- Environment-specific values come from environment or secret management, not committed files.
- Production MUST fail fast when required configuration is absent.
- Feature flags MUST have an owner, default, expiry or review date, and safe fallback.

