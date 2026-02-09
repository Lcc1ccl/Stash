import Foundation
import RealmSwift

enum StorageError: LocalizedError {
    case appGroupUnavailable
    case realmUnavailable
    case writeFailed(String)
    case fetchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "无法访问共享存储空间。"
        case .realmUnavailable:
            return "数据库当前不可用。"
        case .writeFailed(let reason):
            return "保存失败：\(reason)"
        case .fetchFailed(let reason):
            return "读取失败：\(reason)"
        }
    }
}

class StorageManager {
    static let shared = StorageManager()

    // App Group Identifier
    private let appGroupId = StashRealmConfiguration.sharedAppGroupIdentifier
    
    func sharedRealmConfiguration() -> Realm.Configuration? {
        StashRealmConfiguration.sharedFileConfiguration(
            appGroupIdentifier: appGroupId,
            schemaVersion: StashRealmConfiguration.defaultSchemaVersion,
            migrationLogger: { oldSchemaVersion, targetSchemaVersion in
                print(
                    "StorageManager: Migrating from version \(oldSchemaVersion) to \(targetSchemaVersion)"
                )
            }
        )
    }
    
    /// 获取 Realm 实例（可能返回 nil）
    var realmOptional: Realm? {
        if let config = sharedRealmConfiguration() {
            do {
                return try Realm(configuration: config)
            } catch {
                print("StorageManager: Failed to open App Group Realm - \(error)")
            }
        } else {
            print("StorageManager: Shared App Group container not found, fallback to default Realm")
        }
        
        return openDefaultRealm()
    }
    
    /// 为兼容性保留的 realm 属性
    var realm: Realm? {
        realmOptional
    }
    
    private func openDefaultRealm() -> Realm? {
        do {
            return try Realm()
        } catch {
            print("StorageManager: Failed to open default Realm - \(error)")
            return nil
        }
    }

    func save(_ item: AssetItem) {
        _ = saveResult(item)
    }
    
    @discardableResult
    func saveResult(_ item: AssetItem) -> Result<Void, StorageError> {
        guard let realm = realmOptional else {
            print("StorageManager: Cannot save - Realm unavailable")
            return .failure(.realmUnavailable)
        }
        
        do {
            try realm.write {
                realm.add(item)
            }
            return .success(())
        } catch {
            print("StorageManager: Error saving item - \(error)")
            return .failure(.writeFailed(error.localizedDescription))
        }
    }
    
    func fetchAll() -> Results<AssetItem>? {
        switch fetchAllResult() {
        case .success(let results):
            return results
        case .failure:
            return nil
        }
    }
    
    func fetchAllResult() -> Result<Results<AssetItem>, StorageError> {
        guard let realm = realmOptional else {
            print("StorageManager: Cannot fetch - Realm unavailable")
            return .failure(.realmUnavailable)
        }
        let results = realm.objects(AssetItem.self).sorted(byKeyPath: "createdAt", ascending: false)
        return .success(results)
    }
}
