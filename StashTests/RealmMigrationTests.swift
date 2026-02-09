import Foundation
import RealmSwift
import Testing
@testable import Stash

struct RealmMigrationTests {
    @Test
    func migrationConfigurationUpgradesSchemaAndPreservesExistingData() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("realm-migration-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let realmURL = tempDirectory.appendingPathComponent("migration.realm")
        let previousSchemaVersion = StashRealmConfiguration.defaultSchemaVersion - 1
        let assetId = UUID()

        let previousConfig = Realm.Configuration(
            fileURL: realmURL,
            schemaVersion: previousSchemaVersion,
            objectTypes: [AssetItem.self]
        )
        let previousRealm = try Realm(configuration: previousConfig)
        try previousRealm.write {
            let item = AssetItem(
                url: "https://example.com/legacy",
                title: "Legacy Item",
                sourceAppName: "Legacy"
            )
            item.id = assetId
            previousRealm.add(item, update: .modified)
        }
        previousRealm.invalidate()

        let migratedConfig = StashRealmConfiguration.fileConfiguration(
            at: realmURL,
            schemaVersion: StashRealmConfiguration.defaultSchemaVersion,
            migrationLogger: { _, _ in }
        )

        let migratedRealm = try Realm(configuration: migratedConfig)
        let migratedItem = migratedRealm.object(ofType: AssetItem.self, forPrimaryKey: assetId)

        #expect(migratedConfig.migrationBlock != nil)
        #expect(migratedConfig.schemaVersion == StashRealmConfiguration.defaultSchemaVersion)
        #expect(migratedItem != nil)
        #expect(migratedItem?.title == "Legacy Item")
        #expect(migratedItem?.url == "https://example.com/legacy")
    }
}
