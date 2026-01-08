# Spec: AI Integration

## ADDED Requirements

### Requirement: AI Data Fields
The data model SHALL support AI-generated content.

#### Scenario: Storage
- **Given** an `AssetItem`
- **Then** it must store `summary` (String), `tags` (List), `coverEmoji`, and `coverColor`

### Requirement: AI Chat Simulation
The app SHALL simulate an interactive AI agent.

#### Scenario: Chatting
- **Given** the user is in Detail View
- **When** they type a question in "Ask Gemini"
- **Then** a simulated response appears after a short delay
- **And** the UI shows a "thinking" state
