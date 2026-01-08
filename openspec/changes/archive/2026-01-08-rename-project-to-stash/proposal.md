# Rename Project to Stash

## Metadata
- **Change ID**: `rename-project-to-stash`
- **Status**: Draft
- **Created**: 2026-01-08

## Context
The project is currently named "Stash". The goal is to fully rebrand and rename the project to "Stash". This change affects the user interface, codebase, project configuration, and data persistence layers.

## Goals
1.  Rename the Xcode project and targets from "Stash" to "Stash".
2.  Update all UI text references from "Stash" to "Stash".
3.  Update Bundle Identifiers to match the new name (e.g., `com.chaosky.Stash`).
4.  Update App Group Identifier to `group.com.chaosky.Stash` and ensure consistency.
5.  Rename source directories and test bundles.

## Risks
- **Data Loss**: Changing the App Group ID will result in loss of access to the existing Realm database for installed apps. Since this is likely a pre-release or personal project, this is assumed acceptable, but requires user confirmation.
- **Merge Conflicts**: Renaming folders and files will verify heavy conflicts if other branches exist.

## Out of Scope
- Changing the core functionality or UI design beyond the name change.
