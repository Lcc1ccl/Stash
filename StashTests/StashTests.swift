import Foundation
import RealmSwift
import Testing
@testable import Stash

struct StashTests {
    @Test
    func startupBootstrapperUsesFallbackPathWhenAppGroupUnavailable() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("startup-bootstrapper-tests", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        let bootstrapper = StartupBootstrapper(
            appGroupId: "group.test.stash",
            resolveAppGroupContainer: { _ in nil },
            resolveDocumentsDirectory: { tempDirectory },
            validateRealmConfiguration: { _ in }
        )
        
        let result = bootstrapper.bootstrap()
        
        #expect(result.issue == .appGroupUnavailable(appGroupId: "group.test.stash"))
        #expect(result.configuration.fileURL?.path == tempDirectory.appendingPathComponent("fallback.realm").path)
    }
    
    @Test
    func startupBootstrapperFallsBackToInMemoryWhenPrimaryRealmFails() throws {
        enum TestError: Error {
            case primaryUnavailable
        }
        
        var shouldFailPrimary = true
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("startup-bootstrapper-primary-failure", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        let bootstrapper = StartupBootstrapper(
            appGroupId: "group.test.stash",
            resolveAppGroupContainer: { _ in tempDirectory },
            resolveDocumentsDirectory: { tempDirectory },
            validateRealmConfiguration: { config in
                if config.inMemoryIdentifier == nil && shouldFailPrimary {
                    shouldFailPrimary = false
                    throw TestError.primaryUnavailable
                }
            }
        )
        
        let result = bootstrapper.bootstrap()
        
        if case .realmInitFailed = result.issue {
            #expect(result.configuration.inMemoryIdentifier != nil)
        } else {
            #expect(Bool(false), "Expected realmInitFailed issue when primary Realm validation throws")
        }
    }
    
    @Test
    func inferAuthBackendStatusMarksSupabaseConfigFailureAsOffline() {
        let status = inferAuthBackendStatus(from: SupabaseServiceError.unavailable(.missingURL))
        
        switch status {
        case .offline(let reason):
            #expect(reason.contains("missing") || reason.contains("Missing") || reason.contains("缺失"))
        case .online:
            #expect(Bool(false), "Expected offline status for Supabase service unavailability")
        }
    }
}
