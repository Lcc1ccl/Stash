# Design: Enhance UI and AI Features

## Architecture
- **MVVM**: Continue using MVVM. `AssetItem` will be the Model.
- **SwiftUI**: Use `View` composition to recreate the React components (`ItemCard`, `DetailView`, `TabBar`).

## Data Model Changes
Modify `AssetItem` (Realm Object):
- `summary`: String? (AI generated summary)
- `tags`: List<String> (AI tags)
- `coverEmoji`: String (Default to random or inferred)
- `coverColor`: String (Hex code or preset name, e.g., "bg-blue-100")

## UI Components Mapping
- `ItemCard` (React) -> `AssetCardView` (SwiftUI)
- `DetailView` (React) -> `AssetDetailView` (SwiftUI)
- `TabBar` (React) -> Custom `TabBarView` or styled `TabView`

## AI Simulation
- Since we don't have a live backend yet, we will simulate the "AI Analysis" delay and result generation in the `ViewModel` or a dedicated `AIService` (mock).
