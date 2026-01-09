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
        let config = Realm.Configuration(fileURL: realmURL, schemaVersion: 5)
        Realm.Configuration.defaultConfiguration = config
        
        // Supabase is initialized via global client in SupabaseConfig.swift
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
