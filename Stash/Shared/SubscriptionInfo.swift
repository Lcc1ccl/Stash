import Foundation
import RealmSwift

/// 订阅方案类型
enum SubscriptionPlan: String, PersistableEnum {
    case free = "FREE"
    case plus = "PLUS"
    case pro = "PRO"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Plus"
        case .pro: return "Pro"
        }
    }
    
    var dailyCredits: Int {
        switch self {
        case .free: return 10
        case .plus: return 50
        case .pro: return 200
        }
    }
    
    var priceDescription: String {
        switch self {
        case .free: return "免费"
        case .plus: return "¥9.9/月"
        case .pro: return "¥29.9/月"
        }
    }
}

/// 订阅与积分信息模型
class SubscriptionInfo: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var plan: SubscriptionPlan = .free
    @Persisted var creditsRemaining: Int = 10
    @Persisted var lastRefreshDate: Date = Date()
    
    /// 检查并刷新每日积分
    func refreshCreditsIfNeeded() -> Bool {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastRefreshDate) {
            creditsRemaining = plan.dailyCredits
            lastRefreshDate = Date()
            return true
        }
        return false
    }
    
    /// 消耗积分，返回是否成功
    func consumeCredits(_ amount: Int) -> Bool {
        guard creditsRemaining >= amount else { return false }
        creditsRemaining -= amount
        return true
    }
}
