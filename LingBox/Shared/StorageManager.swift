import Foundation
import RealmSwift

class StorageManager {
    static let shared = StorageManager()

    // App Group Identifier
    private let appGroupId = "group.com.chaosky.LingBox"

    var realm: Realm {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("Shared App Group container not found. Check Entitlements.")
        }
        let realmURL = container.appendingPathComponent("default.realm")
        let config = Realm.Configuration(fileURL: realmURL, schemaVersion: 2)
        
        do {
            return try Realm(configuration: config)
        } catch {
            fatalError("Failed to open Realm: \(error)")
        }
    }

    func save(_ item: AssetItem) {
        do {
            try realm.write {
                realm.add(item)
            }
        } catch {
            print("Error saving item: \(error)")
        }
    }
    
    func fetchAll() -> Results<AssetItem> {
        return realm.objects(AssetItem.self).sorted(byKeyPath: "createdAt", ascending: false)
    }
}
