import Foundation
import RealmSwift
import Testing
@testable import Stash

@MainActor
struct AppGroupRealmIntegrationTests {
    @Test
    func appAndExtensionRealmConfigurationsStayConsistent() throws {
        guard let config = StorageManager.shared.sharedRealmConfiguration() else {
            #expect(Bool(false), "App Group Realm configuration is unavailable.")
            return
        }
        
        #expect(config.schemaVersion == 6)
        
        let realmA = try Realm(configuration: config)
        let realmB = try Realm(configuration: config)
        
        let item = AssetItem(
            url: "https://example.com/app-group-test",
            title: "App Group Consistency Test"
        )
        let itemId = item.id
        
        try realmA.write {
            realmA.add(item, update: .modified)
        }
        
        let mirroredItem = realmB.object(ofType: AssetItem.self, forPrimaryKey: itemId)
        #expect(mirroredItem != nil)
        
        try realmA.write {
            if let mirroredItem {
                realmA.delete(mirroredItem)
            }
        }
    }
}
