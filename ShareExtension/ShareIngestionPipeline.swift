import Foundation

struct SharePageMetadata {
    let title: String
    let imageUrl: String?
}

enum ShareMetadataParser {
    static func parse(html: String, fallbackTitle: String) -> SharePageMetadata {
        var title = fallbackTitle
        
        if let range1 = html.range(of: "<title>"),
           let range2 = html.range(of: "</title>", range: range1.upperBound..<html.endIndex) {
            title = String(html[range1.upperBound..<range2.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
        }
        
        let imageUrl = extractMetaContent(from: html, property: "og:image")
            ?? extractMetaContent(from: html, property: "twitter:image")
        
        return SharePageMetadata(title: title, imageUrl: imageUrl)
    }
    
    static func extractMetaContent(from html: String, property: String) -> String? {
        let patterns = [
            "<meta[^>]*property=\"\(property)\"[^>]*content=\"([^\"]*)\"",
            "<meta[^>]*content=\"([^\"]*)\"[^>]*property=\"\(property)\"",
            "<meta[^>]*name=\"\(property)\"[^>]*content=\"([^\"]*)\"",
            "<meta[^>]*content=\"([^\"]*)\"[^>]*name=\"\(property)\""
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
        }
        return nil
    }
}

enum ShareFallbackContentGenerator {
    static func summary(title: String, url: URL) -> String {
        let titleLower = title.lowercased()
        let host = url.host?.lowercased() ?? ""
        
        if titleLower.contains("设计") || titleLower.contains("design") || host.contains("figma") || host.contains("dribbble") {
            return "深度解析设计技巧与趋势，提供了实用的设计灵感和方法论，值得设计师收藏学习。"
        } else if titleLower.contains("ai") || titleLower.contains("gpt") || titleLower.contains("机器学习") {
            return "探讨人工智能最新进展与应用场景，包含技术解读和实践建议。"
        } else if titleLower.contains("教程") || titleLower.contains("tutorial") || titleLower.contains("how to") {
            return "详细的操作指南与步骤说明，帮助读者快速掌握相关技能。"
        } else if host.contains("github") {
            return "开源项目介绍，包含技术架构、使用方法和贡献指南。"
        } else if host.contains("youtube") || host.contains("bilibili") {
            return "精彩视频内容，涵盖教程、演示或深度解析等主题。"
        } else if host.contains("xiaohongshu") || host.contains("xhslink") {
            return "生活方式分享，包含实用技巧、产品推荐或经验心得。"
        } else if titleLower.contains("product") || titleLower.contains("产品") || titleLower.contains("saas") {
            return "产品介绍与功能解读，适合产品经理和创业者参考。"
        } else {
            let summaries = [
                "深度好文，提供了独特的见解和专业的分析。",
                "实用资讯，包含可操作的建议和最佳实践。",
                "精选内容，值得收藏和反复阅读的优质资源。",
                "专业解读，帮助理解复杂概念和行业趋势。"
            ]
            return summaries.randomElement() ?? "值得一读的优质内容。"
        }
    }
    
    static func tags(title: String, url: URL) -> [String] {
        var tags: [String] = []
        let titleLower = title.lowercased()
        let host = url.host?.lowercased() ?? ""
        
        if titleLower.contains("设计") || titleLower.contains("design") || titleLower.contains("ui") || titleLower.contains("ux") {
            tags.append("Design")
        }
        if titleLower.contains("ai") || titleLower.contains("gpt") || titleLower.contains("llm") || titleLower.contains("机器学习") {
            tags.append("AI")
        }
        if titleLower.contains("教程") || titleLower.contains("tutorial") || titleLower.contains("how to") || titleLower.contains("guide") {
            tags.append("Tutorial")
        }
        if titleLower.contains("产品") || titleLower.contains("product") || titleLower.contains("saas") || titleLower.contains("startup") {
            tags.append("Product")
        }
        if titleLower.contains("开发") || titleLower.contains("dev") || titleLower.contains("code") || titleLower.contains("编程") {
            tags.append("Dev")
        }
        if titleLower.contains("midjourney") || titleLower.contains("stable diffusion") || titleLower.contains("prompt") {
            tags.append("AI Art")
        }
        if host.contains("github") {
            tags.append("OpenSource")
        }
        if host.contains("youtube") || host.contains("bilibili") {
            tags.append("Video")
        }
        if tags.isEmpty {
            tags.append("Article")
        }
        
        return Array(tags.prefix(3))
    }
}

enum ShareImagePersistence {
    static func saveToAppGroup(_ imageData: Data) -> String? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.chaosky.Stash"
        ) else {
            return nil
        }
        
        let imagesDir = containerURL.appendingPathComponent("shared_images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDir.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL.absoluteString
        } catch {
            return nil
        }
    }
}

final class ShareIngestionPipeline {
    private let aiClient: OpenAIClient
    
    init(aiClient: OpenAIClient = .shared) {
        self.aiClient = aiClient
    }
    
    func buildAssetItem(url: URL, attachedImageData: Data?) async -> AssetItem {
        var title = url.host ?? "Unknown Site"
        var imageUrl: String?
        
        if let html = await fetchHTML(from: url, timeout: 10) {
            let metadata = ShareMetadataParser.parse(html: html, fallbackTitle: title)
            title = metadata.title
            if attachedImageData == nil {
                imageUrl = metadata.imageUrl
            }
        }
        
        if let attachedImageData,
           let localPath = ShareImagePersistence.saveToAppGroup(attachedImageData) {
            imageUrl = localPath
        }
        
        let sourceApp = detectSourceApp(from: url)
        let fallbackSummary = ShareFallbackContentGenerator.summary(title: title, url: url)
        let fallbackTags = ShareFallbackContentGenerator.tags(title: title, url: url)
        
        let (summary, tags) = await analyzeWithTimeout(
            title: title,
            url: url,
            timeoutSeconds: 15,
            fallbackSummary: fallbackSummary,
            fallbackTags: fallbackTags
        )
        
        return AssetItem(
            url: url.absoluteString,
            title: title,
            imageUrl: imageUrl,
            sourceAppName: sourceApp,
            summary: summary,
            tags: tags,
            coverEmoji: generateRandomEmoji(),
            coverColor: generateRandomColor()
        )
    }
    
    private func fetchHTML(from url: URL, timeout: TimeInterval) async -> String? {
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = timeout
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...399).contains(httpResponse.statusCode) else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    private func analyzeWithTimeout(
        title: String,
        url: URL,
        timeoutSeconds: UInt64,
        fallbackSummary: String,
        fallbackTags: [String]
    ) async -> (String, [String]) {
        let fallback = (fallbackSummary, fallbackTags)
        
        return await withTaskGroup(of: (String, [String]).self) { group in
            group.addTask {
                let result = await self.aiClient.analyzeContent(title: title, url: url.absoluteString)
                return (result.summary, result.tags)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
                return fallback
            }
            
            guard let first = await group.next() else {
                return fallback
            }
            group.cancelAll()
            return first
        }
    }
    
    private func generateRandomEmoji() -> String {
        let emojis = ["📦", "🔗", "📚", "💡", "🎯", "🚀", "⭐️", "🔥", "💎", "🎨", "🛠", "📝", "🌟", "💻", "📱", "🎬", "🎵", "📰", "🧠", "✨"]
        return emojis.randomElement() ?? "📦"
    }
    
    private func generateRandomColor() -> String {
        let colors = ["bg-blue-100", "bg-orange-100", "bg-stone-200", "bg-green-100", "bg-purple-100", "bg-pink-100", "bg-yellow-100"]
        return colors.randomElement() ?? "bg-gray-100"
    }
    
    private func detectSourceApp(from url: URL) -> String {
        guard let host = url.host?.lowercased() else { return "Web" }
        
        if host.contains("xiaohongshu") || host.contains("xhslink") {
            return "Xiaohongshu"
        } else if host.contains("twitter") || host.contains("x.com") {
            return "Twitter"
        } else if host.contains("youtube") || host.contains("youtu.be") {
            return "YouTube"
        } else if host.contains("instagram") {
            return "Instagram"
        } else if host.contains("weibo") {
            return "Weibo"
        } else if host.contains("bilibili") || host.contains("b23.tv") {
            return "Bilibili"
        } else if host.contains("zhihu") {
            return "Zhihu"
        } else if host.contains("github") {
            return "GitHub"
        } else if host.contains("medium") {
            return "Medium"
        } else if host.contains("reddit") {
            return "Reddit"
        } else if host.contains("telegram") || host.contains("t.me") {
            return "Telegram"
        } else if host.contains("tiktok") {
            return "TikTok"
        } else if host.contains("douyin") {
            return "Douyin"
        } else if host.contains("facebook") || host.contains("fb.com") {
            return "Facebook"
        } else if host.contains("linkedin") {
            return "LinkedIn"
        } else if host.contains("notion") {
            return "Notion"
        } else if host.contains("figma") {
            return "Figma"
        } else {
            return "Safari"
        }
    }
}
