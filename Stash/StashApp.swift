//
//  StashApp.swift
//  Stash
//
//  Created by 超爹 on 2026/1/5.
//

import SwiftUI
import RealmSwift

@main
struct StashApp: SwiftUI.App {
    
    init() {
        // Configure Realm to use the shared App Group container
        let appGroupId = "group.com.chaosky.Stash"
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("Shared App Group container not found. Check Entitlements.")
        }
        let realmURL = container.appendingPathComponent("default.realm")
        let config = Realm.Configuration(fileURL: realmURL, schemaVersion: 3) // Bump schema version for new models
        Realm.Configuration.defaultConfiguration = config
        
        // Initialize managers and refresh daily credits
        _ = AuthManager.shared
        CreditsManager.shared.refreshCreditsIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
