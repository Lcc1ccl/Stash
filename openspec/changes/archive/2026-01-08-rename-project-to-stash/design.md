# Design: Rename Strategy

## Folder Structure
The current folder structure:
- `Stash/` (App source)
- `ShareExtension/` (Extension source, generic name, might stay or update references)
- `StashUITests/`
- `StashTests/`

Proposed structure:
- `Stash/`
- `ShareExtension/` (Keep as is unless "StashShare" is desired, but "ShareExtension" is standard)
- `StashUITests/`
- `StashTests/`

## Bundle Identifiers
Current:
- App: (Likely `com.chaosky.Stash`)
- Extension: (Likely `com.chaosky.Stash.ShareExtension`)
- App Group: `group.com.chaosky.Stash` (and inconsistent `group.com.superdaddy.Stash` found in code)

Proposed:
- App: `com.chaosky.Stash`
- Extension: `com.chaosky.Stash.ShareExtension`
- App Group: `group.com.chaosky.Stash`

## Code Inconsistencies
Found `group.com.superdaddy.Stash` in `ShareViewController.swift` vs `group.com.chaosky.Stash` elsewhere. This rename will resolve this inconsistency by unifying everything to `com.chaosky.Stash`.
