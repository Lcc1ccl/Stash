## ADDED Requirements

### Requirement: Graceful Startup Degradation

The application SHALL NOT crash during startup even if critical services fail to initialize. Instead, it SHALL display a user-friendly error message.

#### Scenario: App Group container unavailable
- **WHEN** the App Group shared container cannot be accessed
- **THEN** the app SHALL display an error screen explaining the issue
- **AND** the app SHALL NOT call `fatalError` or crash

#### Scenario: Realm database initialization fails
- **WHEN** the Realm database cannot be opened (e.g., migration failure, disk full)
- **THEN** the app SHALL display an appropriate error message
- **AND** the app SHALL allow the user to retry or report the issue

### Requirement: Realm Schema Migration Support

The application SHALL support Realm schema migrations between different app versions.

#### Scenario: User updates from older app version
- **WHEN** a user with an older Realm schema version opens the updated app
- **THEN** the migration block SHALL handle the schema update gracefully
- **AND** existing data SHALL be preserved when possible

### Requirement: Safe Supabase Initialization

The Supabase client SHALL be initialized lazily and SHALL handle initialization failures gracefully.

#### Scenario: Supabase client initialization fails
- **WHEN** the Supabase client cannot be initialized (e.g., invalid configuration)
- **THEN** the app SHALL continue to function in offline/local mode
- **AND** authentication-dependent features SHALL show appropriate "offline" state
