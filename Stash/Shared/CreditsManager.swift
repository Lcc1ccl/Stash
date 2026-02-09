import Foundation
import Combine
import Supabase

/// 订阅信息数据库模型
struct SubscriptionRecord: Codable {
    let id: UUID?
    let userId: UUID
    let plan: String
    let creditsRemaining: Double
    let lastRefreshDate: Date
    let customProviderUnlocked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case plan
        case creditsRemaining = "credits_remaining"
        case lastRefreshDate = "last_refresh_date"
        case customProviderUnlocked = "custom_provider_unlocked"
    }
}

/// 积分管理器 - Supabase 版本
@MainActor
class CreditsManager: ObservableObject {
    static let shared = CreditsManager()
    
    @Published var currentPlan: SubscriptionPlan = .free
    @Published var creditsRemaining: Double = 0
    @Published var lastRefreshDate: Date?
    @Published var isLoading: Bool = false
    @Published var customProviderUnlocked: Bool = false
    @Published var syncErrorMessage: String?
    
    private var userId: String?
    private let clientResolver: () throws -> SupabaseClient
    
    init(clientResolver: @escaping () throws -> SupabaseClient = { try requireSupabaseClient() }) {
        self.clientResolver = clientResolver
    }
    
    // MARK: - Load User Credits
    
    func loadUserCredits(userId: String) async {
        self.userId = userId
        isLoading = true
        syncErrorMessage = nil
        
        do {
            let client = try clientResolver()
            let records: [SubscriptionRecord] = try await client
                .from("subscriptions")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let record = records.first {
                currentPlan = SubscriptionPlan(rawValue: record.plan) ?? .free
                creditsRemaining = record.creditsRemaining
                lastRefreshDate = record.lastRefreshDate
                customProviderUnlocked = record.customProviderUnlocked
                
                // 检查是否需要刷新每日积分
                await refreshCreditsIfNeeded()
            } else {
                // 新用户，初始化积分
                await initializeCredits(userId: userId)
            }
        } catch {
            print("Error loading credits: \(error)")
            syncErrorMessage = error.localizedDescription
            // 本地默认值
            currentPlan = .free
            creditsRemaining = Double(SubscriptionPlan.free.dailyCredits)
            lastRefreshDate = Date()
            customProviderUnlocked = false
        }
        
        isLoading = false
    }
    
    // MARK: - Initialize Credits
    
    func initializeCredits(userId: String) async {
        self.userId = userId
        currentPlan = .free
        creditsRemaining = Double(SubscriptionPlan.free.dailyCredits)
        lastRefreshDate = Date()
        customProviderUnlocked = false
        
        await saveCreditsToSupabase()
    }
    
    func resetForSignedOutState() {
        userId = nil
        currentPlan = .free
        creditsRemaining = Double(SubscriptionPlan.free.dailyCredits)
        lastRefreshDate = nil
        customProviderUnlocked = false
        syncErrorMessage = nil
    }
    
    // MARK: - Daily Refresh
    
    func refreshCreditsIfNeeded() async {
        guard let lastRefresh = lastRefreshDate else {
            lastRefreshDate = Date()
            creditsRemaining = Double(currentPlan.dailyCredits)
            await saveCreditsToSupabase()
            return
        }
        
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastRefresh) {
            creditsRemaining = Double(currentPlan.dailyCredits)
            lastRefreshDate = Date()
            await saveCreditsToSupabase()
        }
    }
    
    // MARK: - Consume Credits
    
    func consumeCredits(_ amount: Double) async -> Bool {
        guard creditsRemaining >= amount else {
            return false
        }
        
        creditsRemaining -= amount
        await saveCreditsToSupabase()
        return true
    }
    
    func canAfford(_ amount: Double) -> Bool {
        return creditsRemaining >= amount
    }
    
    // MARK: - Upgrade Plan
    
    func upgradePlan(to plan: SubscriptionPlan) async {
        currentPlan = plan
        creditsRemaining = Double(plan.dailyCredits)
        lastRefreshDate = Date()
        await saveCreditsToSupabase()
    }
    
    // MARK: - Supabase Sync
    
    private func saveCreditsToSupabase() async {
        guard let userId = userId, let userUUID = UUID(uuidString: userId) else { return }
        
        let record = SubscriptionRecord(
            id: nil,
            userId: userUUID,
            plan: currentPlan.rawValue,
            creditsRemaining: creditsRemaining,
            lastRefreshDate: lastRefreshDate ?? Date(),
            customProviderUnlocked: customProviderUnlocked
        )
        
        do {
            let client = try clientResolver()
            try await client
                .from("subscriptions")
                .upsert(record, onConflict: "user_id")
                .execute()
        } catch {
            print("Error saving credits: \(error)")
            syncErrorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Custom Provider Unlock
    
    /// 解锁自定义提供方（消耗 10 积分）
    func unlockCustomProvider() async -> Bool {
        let unlockCost = AICreditsCost.customProviderUnlock
        
        // 已解锁时不重复扣费（一次性语义）
        if customProviderUnlocked {
            return true
        }
        
        guard userId != nil else {
            syncErrorMessage = "请先登录后再解锁自定义提供方。"
            return false
        }
        
        guard creditsRemaining >= unlockCost else {
            return false
        }
        
        creditsRemaining -= unlockCost
        customProviderUnlocked = true
        await saveCreditsToSupabase()
        return true
    }
    
    /// 检查是否可以使用自定义提供方
    func canUseCustomProvider() -> Bool {
        customProviderUnlocked
    }
}

// MARK: - AI Credits Cost

enum AICreditsCost {
    static let summaryGeneration: Double = 0.5
    static let chat: Double = 0.5
    static let contentAnalysis: Double = 1.0
    static let customProviderUnlock: Double = 10.0
}
