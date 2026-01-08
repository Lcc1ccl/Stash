# Project Context

## Purpose
LingBox is a local-first iOS application designed to capture, organize, and review web links. It serves as a personal "read it later" or link collection tool. 

Key features:
- **Share Extension**: Allows users to quickly save URLs from Safari or other apps directly into LingBox.
- **Main App**: A SwiftUI-based interface to view, manage, and review stored links.
- **Privacy-Focused**: All data is stored locally using Realm.
- **Weekly Recap**: Features a notification system to remind users to review their saved links.

## Tech Stack
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Persistence**: Realm (RealmSwift) local database
- **Platform**: iOS (iPhone/iPad)
- **Data Sharing**: App Groups (`group.com.chaosky.LingBox`) to share the Realm database between the main app and the Share Extension.

## Project Conventions

### Code Style
- **Swift**: Follows standard Swift API Design Guidelines.
- **SwiftUI**: Uses functional views and `@State`/`@Binding`/`@ObservedResults` property wrappers.
- **Safety**: Uses `guard let` for optional unwrapping and early exits.

### Architecture Patterns
- **MVVM**: Separation of logic using ViewModel-like structures (though currently logic is light and largely embedded in Views or Managers).
- **Managers**: Singleton pattern for shared services (`StorageManager`, `NotificationManager`).
- **Data Model**: `Realm` objects (`AssetItem`) inherit from `Object`.

### Testing Strategy
- **Unit Tests**: Standard XCTest framework (`LingBoxTests`).
- **UI Tests**: XCUITest (`LingBoxUITests`).

### Git Workflow
- Standard feature branching.

## Domain Context
- **AssetItem**: The core data entity representing a saved link/bookmark.
- **App Group**: Critical for ensuring the Share Extension can write to the same database file (`default.realm`) that the main app reads.

## Important Constraints
- **Data Integrity**: The Realm schema must stay consistent between the App and Extension.
- **Sandboxing**: Both targets must have the App Group entitlement correctly configured to access the shared container.

## External Dependencies
- **RealmSwift**: Database engine.

