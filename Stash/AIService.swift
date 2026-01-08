import Foundation
import Combine

class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isProcessing = false
    
    private let openAI = OpenAIClient.shared
    
    /// Generate or refine summary for a saved item
    func refineSummary(for title: String, currentSummary: String?) async -> String {
        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }
        
        let result = await openAI.analyzeContent(title: title, url: "")
        return result.summary
    }
    
    /// Chat with AI about a specific bookmark
    func chat(query: String, context: String) async -> String {
        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }
        
        return await openAI.chat(query: query, context: context)
    }
    
    /// Analyze content and return both summary and tags
    func analyzeContent(title: String, url: String) async -> (summary: String, tags: [String]) {
        let result = await openAI.analyzeContent(title: title, url: url)
        return (result.summary, result.tags)
    }
}
