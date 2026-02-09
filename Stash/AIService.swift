import Foundation
import Combine

class AIService: ObservableObject {
    static let shared = AIService(
        aiClient: AppServices.shared.aiClient,
        creditsService: AppServices.shared.credits
    )
    
    @Published var isProcessing = false
    @Published var lastErrorMessage: String?
    
    private let aiClient: AIClientProtocol
    private let creditsService: CreditsServiceProtocol
    
    init(
        aiClient: AIClientProtocol = AppServices.shared.aiClient,
        creditsService: CreditsServiceProtocol = AppServices.shared.credits
    ) {
        self.aiClient = aiClient
        self.creditsService = creditsService
    }
    
    /// Generate or refine summary for a saved item
    func refineSummary(for title: String, currentSummary: String?) async -> String {
        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }
        
        guard await consumeCreditsOrFail(AICreditsCost.summaryGeneration) else {
            return "积分不足，请升级订阅或等待每日额度刷新。"
        }
        
        let result = await aiClient.analyzeContent(title: title, url: "")
        return result.summary
    }
    
    /// Chat with AI about a specific bookmark
    func chat(query: String, context: String) async -> String {
        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }
        
        guard await consumeCreditsOrFail(AICreditsCost.chat) else {
            return "积分不足，请升级订阅或等待每日额度刷新。"
        }
        
        return await aiClient.chat(query: query, context: context)
    }
    
    /// Analyze content and return both summary and tags
    func analyzeContent(title: String, url: String) async -> (summary: String, tags: [String]) {
        guard await consumeCreditsOrFail(AICreditsCost.contentAnalysis) else {
            return ("积分不足，请升级订阅或等待每日额度刷新。", ["CreditLimit"])
        }
        
        let result = await aiClient.analyzeContent(title: title, url: url)
        return (result.summary, result.tags)
    }
    
    private func consumeCreditsOrFail(_ amount: Double) async -> Bool {
        await creditsService.refreshCreditsForOperation()
        let canAfford = await creditsService.hasEnoughCredits(amount)
        
        guard canAfford else {
            await MainActor.run {
                lastErrorMessage = "积分不足"
            }
            return false
        }
        
        let consumed = await creditsService.consumeCreditsForOperation(amount)
        if !consumed {
            await MainActor.run {
                lastErrorMessage = "积分扣减失败，请稍后重试。"
            }
        }
        return consumed
    }
}
