import Foundation
import Testing
@testable import Stash

@MainActor
struct CreditsManagerTests {
    @Test
    func consumeCreditsDecreasesBalanceWhenSufficient() async throws {
        let manager = CreditsManager.shared
        await manager.initializeCredits(userId: UUID().uuidString)
        manager.creditsRemaining = 10
        
        let success = await manager.consumeCredits(2)
        
        #expect(success)
        #expect(manager.creditsRemaining == 8)
    }
    
    @Test
    func consumeCreditsFailsWhenInsufficient() async throws {
        let manager = CreditsManager.shared
        await manager.initializeCredits(userId: UUID().uuidString)
        manager.creditsRemaining = 1
        
        let success = await manager.consumeCredits(2)
        
        #expect(success == false)
        #expect(manager.creditsRemaining == 1)
    }
    
    @Test
    func refreshCreditsResetsForNewDay() async throws {
        let manager = CreditsManager.shared
        await manager.initializeCredits(userId: UUID().uuidString)
        manager.currentPlan = .plus
        manager.creditsRemaining = 0
        manager.lastRefreshDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        
        await manager.refreshCreditsIfNeeded()
        
        #expect(manager.creditsRemaining == Double(SubscriptionPlan.plus.dailyCredits))
        #expect(manager.lastRefreshDate != nil)
    }
    
    @Test
    func customProviderUnlockChargesOnlyOnce() async throws {
        let manager = CreditsManager.shared
        await manager.initializeCredits(userId: UUID().uuidString)
        manager.creditsRemaining = 30
        manager.customProviderUnlocked = false
        
        let first = await manager.unlockCustomProvider()
        let afterFirst = manager.creditsRemaining
        let second = await manager.unlockCustomProvider()
        
        #expect(first)
        #expect(second)
        #expect(afterFirst == 20)
        #expect(manager.creditsRemaining == 20)
    }
}
