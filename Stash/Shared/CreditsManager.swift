import Foundation
import Combine
import RealmSwift

/// 积分管理器
class CreditsManager: ObservableObject {
    static let shared = CreditsManager()
    
    @Published var subscriptionInfo: SubscriptionInfo?
    
    private var realm: Realm {
        try! Realm()
    }
    
    private init() {
        loadSubscriptionInfo()
        refreshCreditsIfNeeded()
    }
    
    // MARK: - Initialization
    
    private func loadSubscriptionInfo() {
        if let info = realm.objects(SubscriptionInfo.self).first {
            subscriptionInfo = info
        } else {
            // 创建默认 FREE 订阅
            initializeForNewUser()
        }
    }
    
    func initializeForNewUser() {
        let info = SubscriptionInfo()
        try? realm.write {
            // 清除旧的订阅信息
            realm.delete(realm.objects(SubscriptionInfo.self))
            realm.add(info)
        }
        subscriptionInfo = info
    }
    
    // MARK: - Credits Management
    
    /// 刷新每日积分（如果需要）
    func refreshCreditsIfNeeded() {
        guard let info = subscriptionInfo else { return }
        try? realm.write {
            if info.refreshCreditsIfNeeded() {
                objectWillChange.send()
            }
        }
    }
    
    /// 消耗积分
    func consumeCredits(_ amount: Int) -> Bool {
        guard let info = subscriptionInfo else { return false }
        
        var success = false
        try? realm.write {
            success = info.consumeCredits(amount)
        }
        
        if success {
            objectWillChange.send()
        }
        return success
    }
    
    /// 当前积分余额
    var creditsRemaining: Int {
        subscriptionInfo?.creditsRemaining ?? 0
    }
    
    /// 当前订阅方案
    var currentPlan: SubscriptionPlan {
        subscriptionInfo?.plan ?? .free
    }
    
    // MARK: - Subscription Management
    
    /// 升级订阅方案（模拟）
    func upgradePlan(to plan: SubscriptionPlan) {
        guard let info = subscriptionInfo else { return }
        try? realm.write {
            info.plan = plan
            info.creditsRemaining = plan.dailyCredits
            info.lastRefreshDate = Date()
        }
        objectWillChange.send()
    }
}

// MARK: - AI Credits Cost

enum AICreditsCost {
    static let summaryGeneration = 1
    static let chat = 2
    static let tagGeneration = 1
}
