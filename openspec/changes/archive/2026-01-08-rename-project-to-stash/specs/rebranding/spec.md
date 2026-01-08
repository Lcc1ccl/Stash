# Rebranding

## ADDED Requirements

### Requirement: Project Identity
The application MUST be named "Stash" and use consistent branding across the system.

#### Scenario: App Display Name
  - GIVEN the app is installed on an iOS device
  - THEN the app icon label is "Stash"

#### Scenario: Bundle Identifier
  - GIVEN the build settings
  - THEN the Bundle Identifier for the main app is `com.chaosky.Stash`
  - AND the Bundle Identifier for the Share Extension is `com.chaosky.Stash.ShareExtension`

#### Scenario: App Group Identifier
  - GIVEN the App Groups capability
  - THEN the identifier is `group.com.chaosky.Stash`
  - AND both the Main App and Share Extension use this identifier for data sharing

### Requirement: Codebase References
The codebase MUST use "Stash" instead of "Stash" for internal naming where appropriate.

#### Scenario: Class Names
  - GIVEN the main app entry point
  - THEN the struct is named `StashApp` (was `StashApp`)

#### Scenario: UI Text
  - GIVEN the user sees a prompt to save
  - THEN the text refers to "Stash" (e.g., "Save to Stash")
