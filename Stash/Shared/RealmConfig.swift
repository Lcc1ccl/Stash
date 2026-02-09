import Foundation
import RealmSwift

enum StashRealmConfiguration {
    static let sharedAppGroupIdentifier = "group.com.chaosky.Stash"
    static let defaultSchemaVersion: UInt64 = 6

    static func sharedContainerURL(
        appGroupIdentifier: String = sharedAppGroupIdentifier,
        fileManager: FileManager = .default
    ) -> URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    static func sharedFileConfiguration(
        appGroupIdentifier: String = sharedAppGroupIdentifier,
        fileName: String = "default.realm",
        fileManager: FileManager = .default,
        schemaVersion: UInt64 = defaultSchemaVersion,
        migrationLogger: @escaping (UInt64, UInt64) -> Void = defaultMigrationLogger
    ) -> Realm.Configuration? {
        guard let containerURL = sharedContainerURL(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        ) else {
            return nil
        }
        let fileURL = containerURL.appendingPathComponent(fileName)
        return fileConfiguration(
            at: fileURL,
            schemaVersion: schemaVersion,
            migrationLogger: migrationLogger
        )
    }

    static func fileConfiguration(
        at fileURL: URL,
        schemaVersion: UInt64 = defaultSchemaVersion,
        migrationLogger: @escaping (UInt64, UInt64) -> Void = defaultMigrationLogger
    ) -> Realm.Configuration {
        Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: schemaVersion,
            migrationBlock: migrationBlock(
                targetSchemaVersion: schemaVersion,
                logger: migrationLogger
            )
        )
    }

    static func inMemoryConfiguration(
        identifier: String,
        schemaVersion: UInt64 = defaultSchemaVersion,
        migrationLogger: @escaping (UInt64, UInt64) -> Void = defaultMigrationLogger
    ) -> Realm.Configuration {
        Realm.Configuration(
            inMemoryIdentifier: identifier,
            schemaVersion: schemaVersion,
            migrationBlock: migrationBlock(
                targetSchemaVersion: schemaVersion,
                logger: migrationLogger
            )
        )
    }

    static func migrationBlock(
        targetSchemaVersion: UInt64 = defaultSchemaVersion,
        logger: @escaping (UInt64, UInt64) -> Void = defaultMigrationLogger
    ) -> MigrationBlock {
        { _, oldSchemaVersion in
            logger(oldSchemaVersion, targetSchemaVersion)
        }
    }

    private static func defaultMigrationLogger(
        oldSchemaVersion: UInt64,
        targetSchemaVersion: UInt64
    ) {
        print(
            "RealmConfig: Migrating Realm from schema version \(oldSchemaVersion) to \(targetSchemaVersion)"
        )
    }
}
