import Foundation

/// 订阅方案类型
enum SubscriptionPlan: String, CaseIterable {
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
    
    /// 每日积分（1积分 = 1000 tokens）
    var dailyCredits: Int {
        switch self {
        case .free: return 5
        case .plus: return 30
        case .pro: return 100
        }
    }
    
    var priceDescription: String {
        switch self {
        case .free: return "免费"
        case .plus: return "¥12.9/月"
        case .pro: return "¥39.9/月"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return ["每日 5 积分", "AI 摘要生成", "基础功能"]
        case .plus:
            return ["每日 30 积分", "AI 摘要 + 聊天", "优先支持"]
        case .pro:
            return ["每日 100 积分", "无限 AI 功能", "优先支持", "高级功能"]
        }
    }
}
