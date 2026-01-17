import Foundation

/// 敏感信息管理
/// 本地开发：直接设置 apiKey
/// CI/CD：从环境变量 OPENAI_API_KEY 读取
enum Secrets {
    static var openAIAPIKey: String {
        // 优先从环境变量读取（用于 Xcode Cloud）
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // 本地开发使用的备用值（可以为空字符串，表示功能不可用）
        return ""
    }
}
