import Foundation
import RealmSwift

/// AI 提供方类型
enum AIProvider: String, PersistableEnum, CaseIterable {
    case builtin = "builtin"   // 默认内置，消耗积分
    case openai = "openai"     // 自定义 OpenAI
    case anthropic = "anthropic" // 自定义 Anthropic
    
    var displayName: String {
        switch self {
        case .builtin: return "默认 (使用积分)"
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        }
    }
    
    var requiresApiKey: Bool {
        return self != .builtin
    }
    
    var defaultEndpoint: String {
        switch self {
        case .builtin, .openai: return "https://api.openai.com/v1/chat/completions"
        case .anthropic: return "https://api.anthropic.com/v1/messages"
        }
    }
}

/// AI 提供方配置模型
class AIProviderConfig: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var provider: AIProvider = .builtin
    @Persisted var customApiKey: String = ""
    @Persisted var customEndpoint: String = ""
    
    var effectiveEndpoint: String {
        customEndpoint.isEmpty ? provider.defaultEndpoint : customEndpoint
    }
    
    var isUsingBuiltin: Bool {
        provider == .builtin
    }
}
