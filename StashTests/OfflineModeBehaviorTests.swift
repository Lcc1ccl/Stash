import Foundation
import Testing
@testable import Stash

@MainActor
struct OfflineModeBehaviorTests {
    @Test
    func authManagerEntersOfflineModeWhenSupabaseUnavailable() async {
        let manager = AuthManager(
            clientResolver: { throw SupabaseServiceError.unavailable(.missingURL) },
            serviceAvailability: { false },
            configurationErrorProvider: { .missingURL },
            shouldStartAuthStateListener: false
        )

        #expect(manager.isOfflineMode)
        #expect(manager.offlineReason != nil)

        let loginResult = await manager.login(
            email: "offline@example.com",
            password: "password123"
        )

        switch loginResult {
        case .success:
            #expect(Bool(false), "Expected login to fail when Supabase client is unavailable")
        case .failure:
            #expect(manager.isOfflineMode)
            #expect(manager.offlineReason != nil)
        }
    }

    @Test
    func creditsManagerFallsBackToLocalModeWhenSupabaseUnavailable() async {
        let manager = CreditsManager(
            clientResolver: { throw SupabaseServiceError.unavailable(.missingURL) }
        )

        await manager.loadUserCredits(userId: UUID().uuidString)

        #expect(manager.currentPlan == .free)
        #expect(manager.creditsRemaining == Double(SubscriptionPlan.free.dailyCredits))
        #expect(manager.syncErrorMessage != nil)

        let consumed = await manager.consumeCredits(1)
        #expect(consumed)
        #expect(manager.creditsRemaining == Double(SubscriptionPlan.free.dailyCredits - 1))
    }
}
