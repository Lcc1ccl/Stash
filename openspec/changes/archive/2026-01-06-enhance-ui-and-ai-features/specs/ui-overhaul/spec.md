# Spec: UI Overhaul

## MODIFIED Requirements

### Requirement: Main List View
The main view SHALL mirror the "Stash" design.

#### Scenario: Viewing the Inbox
- **Given** the app is open
- **When** the user views the "Inbox" tab
- **Then** they see a list of `AssetCardView` items
- **And** a custom Header with "STASH" title and Search bar
- **And** a custom floating Tab Bar at the bottom

### Requirement: Asset Card
Each item in the list SHALL display rich metadata.

#### Scenario: Card Content
- **Given** an asset exists
- **Then** the card displays:
    - Cover box (Emoji + Color background)
    - Title (truncated to 2 lines)
    - Platform/Source tag
    - AI Summary snippet
    - Tags (hashtags)
    - Date

## ADDED Requirements

### Requirement: Detail View
A focused view SHALL act for reading and interacting with the asset.

#### Scenario: Opening Detail
- **Given** the user taps an `AssetCardView`
- **When** the detail view opens
- **Then** it shows the full cover, title, metadata, and the "AI Insight" section
- **And** a "Ask Gemini" chat interface at the bottom
