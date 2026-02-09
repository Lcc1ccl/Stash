import Foundation

/// 敏感信息管理
enum Secrets {
    static var openAIAPIKey: String {
        AppRuntimeConfig.openAIAPIKey ?? ""
    }
}
