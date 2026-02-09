import Foundation
import RealmSwift
import Testing
@testable import Stash

@MainActor
struct AppGroupRealmIntegrationTests {
    @Test(
        .enabled(
            if: FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.chaosky.Stash"
            ) != nil,
            "Requires App Group entitlement for group.com.chaosky.Stash."
        )
    )
    func appAndExtensionRealmConfigurationsStayConsistent() throws {
        let config = try #require(
            StorageManager.shared.sharedRealmConfiguration(),
            "App Group Realm configuration is unavailable."
        )
        
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
