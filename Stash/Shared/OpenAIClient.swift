import Foundation

/// Lightweight OpenAI API client for both main app and Share Extension
class OpenAIClient {
    static let shared = OpenAIClient()
    
    // MARK: - Configuration
    private var apiKey: String {
        Secrets.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private let model = "gpt-4o-mini"
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    // MARK: - Response Types
    struct AIAnalysisResult {
        let summary: String
        let tags: [String]
    }
    
    // MARK: - Main API Method
    
    /// Generate summary and tags for a given title and URL
    func analyzeContent(title: String, url: String) async -> AIAnalysisResult {
        let prompt = """
        分析这个网页链接，提供:
        1. 一句话中文摘要（简洁有力，不超过50字）
        2. 2-3个相关标签（英文单词，如: Design, AI, Tutorial, Product, Dev, Video, Article）
        
        标题: \(title)
        链接: \(url)
        
        严格按以下格式回复:
        SUMMARY: <摘要内容>
        TAGS: <tag1>, <tag2>, <tag3>
        """
        
        do {
            let response = try await callOpenAI(prompt: prompt)
            return parseAnalysisResponse(response)
        } catch OpenAIError.missingAPIKey {
            return AIAnalysisResult(
                summary: "AI 功能未配置，请在运行环境中设置 OPENAI_API_KEY。",
                tags: ["Article"]
            )
        } catch {
            print("OpenAI API error: \(error)")
            return AIAnalysisResult(
                summary: "内容暂时无法分析，请稍后重试。",
                tags: ["Article"]
            )
        }
    }
    
    /// Chat with AI about a specific bookmark
    func chat(query: String, context: String) async -> String {
        let prompt = """
        用户保存了一个链接，标题是: "\(context)"
        用户问: \(query)
        
        请用中文简洁回答用户的问题。如果你不了解具体内容，可以基于标题进行合理推测或建议用户打开原文查看。
        """
        
        do {
            return try await callOpenAI(prompt: prompt)
        } catch OpenAIError.missingAPIKey {
            return "AI 功能未配置，请设置 OPENAI_API_KEY。"
        } catch {
            return "抱歉，AI 暂时无法回答。请稍后重试。"
        }
    }
    
    // MARK: - Private Methods
    
    private func callOpenAI(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }
        guard let url = URL(string: endpoint) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 200,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("OpenAI API Error (\(httpResponse.statusCode)): \(errorBody)")
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.parsingError
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseAnalysisResponse(_ response: String) -> AIAnalysisResult {
        var summary = "内容分析完成。"
        var tags: [String] = ["Article"]
        
        // Parse SUMMARY
        if let summaryRange = response.range(of: "SUMMARY:"),
           let tagsStart = response.range(of: "TAGS:") {
            let summaryText = response[summaryRange.upperBound..<tagsStart.lowerBound]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !summaryText.isEmpty {
                summary = summaryText
            }
        } else if let summaryRange = response.range(of: "SUMMARY:") {
            let summaryText = response[summaryRange.upperBound...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !summaryText.isEmpty {
                summary = summaryText
            }
        }
        
        // Parse TAGS
        if let tagsRange = response.range(of: "TAGS:") {
            let tagsText = response[tagsRange.upperBound...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let parsedTags = tagsText
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            if !parsedTags.isEmpty {
                tags = Array(parsedTags.prefix(3))
            }
        }
        
        return AIAnalysisResult(summary: summary, tags: tags)
    }
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing. Set OPENAI_API_KEY in environment or Info.plist."
        case .invalidURL:
            return "OpenAI endpoint URL is invalid."
        case .invalidResponse:
            return "OpenAI response is invalid."
        case .apiError(let statusCode):
            return "OpenAI API request failed with status code \(statusCode)."
        case .parsingError:
            return "Failed to parse OpenAI response."
        }
    }
}
