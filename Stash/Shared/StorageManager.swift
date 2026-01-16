import Foundation
import RealmSwift

class StorageManager {
    static let shared = StorageManager()

    // App Group Identifier
    private let appGroupId = "group.com.chaosky.Stash"
    
    /// 获取 Realm 实例（可能返回 nil）
    var realmOptional: Realm? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("StorageManager: ERROR - Shared App Group container not found")
            return nil
        }
        let realmURL = container.appendingPathComponent("default.realm")
        let config = Realm.Configuration(
            fileURL: realmURL,
            schemaVersion: 5,
            migrationBlock: { migration, oldSchemaVersion in
                print("StorageManager: Migrating from version \(oldSchemaVersion)")
            }
        )
        
        do {
            return try Realm(configuration: config)
        } catch {
            print("StorageManager: Failed to open Realm - \(error)")
            return nil
        }
    }
    
    /// 为兼容性保留的 realm 属性，使用默认配置
    var realm: Realm {
        do {
            return try Realm()
        } catch {
            print("StorageManager: Failed to open default Realm - \(error)")
            // 返回一个内存中的 Realm 作为最后的 fallback
            let config = Realm.Configuration(inMemoryIdentifier: "fallback")
            return try! Realm(configuration: config)
        }
    }

    func save(_ item: AssetItem) {
        guard let realm = realmOptional else {
            print("StorageManager: Cannot save - Realm unavailable")
            return
        }
        
        do {
            try realm.write {
                realm.add(item)
            }
        } catch {
            print("StorageManager: Error saving item - \(error)")
        }
    }
    
    func fetchAll() -> Results<AssetItem>? {
        guard let realm = realmOptional else {
            print("StorageManager: Cannot fetch - Realm unavailable")
            return nil
        }
        return realm.objects(AssetItem.self).sorted(byKeyPath: "createdAt", ascending: false)
    }
}
