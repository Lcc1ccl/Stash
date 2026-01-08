import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    private var extractedURL: URL?
    private var extractedImageData: Data?

    override func isContentValid() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Save to Stash"
        extractAttachments()
    }

    private func extractAttachments() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }
        
        let group = DispatchGroup()
        
        for provider in extensionItem.attachments ?? [] {
            // Extract URL
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                    if let url = item as? URL {
                        self?.extractedURL = url
                    }
                    group.leave()
                }
            }
            
            // Extract Image (thumbnail from Share Sheet)
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
                    if let imageURL = item as? URL, let data = try? Data(contentsOf: imageURL) {
                        self?.extractedImageData = data
                    } else if let image = item as? UIImage {
                        self?.extractedImageData = image.jpegData(compressionQuality: 0.7)
                    } else if let data = item as? Data {
                        self?.extractedImageData = data
                    }
                    group.leave()
                }
            }
        }
        
        // Wait for all extractions to complete
        group.notify(queue: .main) {
            // Attachments ready
        }
    }

    override func didSelectPost() {
        guard let url = extractedURL else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
        
        // Capture values before going to background
        let extensionContext = self.extensionContext
        let imageData = self.extractedImageData
        
        // Background work to fetch metadata and save
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var title = url.host ?? "Unknown Site"
            var imageUrl: String? = nil
            
            // Fetch HTML and parse metadata
            if let data = try? Data(contentsOf: url),
               let html = String(data: data, encoding: .utf8) {
                // Extract title
                if let range1 = html.range(of: "<title>"),
                   let range2 = html.range(of: "</title>", range: range1.upperBound..<html.endIndex) {
                    title = String(html[range1.upperBound..<range2.lowerBound])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "\n", with: " ")
                }
                
                // Extract OG image (fallback if no attachment image)
                if imageData == nil {
                    if let ogImage = self?.extractMetaContent(from: html, property: "og:image") {
                        imageUrl = ogImage
                    } else if let twitterImage = self?.extractMetaContent(from: html, property: "twitter:image") {
                        imageUrl = twitterImage
                    }
                }
            }
            
            // Save attached image to App Group container
            if let imgData = imageData {
                if let savedPath = self?.saveImageToAppGroup(imgData) {
                    imageUrl = savedPath
                }
            }
            
            // Generate cover properties  
            let randomEmoji = self?.generateRandomEmoji() ?? "📦"
            let randomColor = self?.generateRandomColor() ?? "bg-gray-100"
            
            // Detect source app
            let sourceApp = self?.detectSourceApp(from: url) ?? "Safari"
            
            // Call OpenAI for real summary and tags (with timeout fallback)
            var aiSummary = "内容分析中..."
            var aiTags = ["Article"]
            
            // Use async/await with Task for OpenAI call
            let semaphore = DispatchSemaphore(value: 0)
            
            Task {
                let result = await OpenAIClient.shared.analyzeContent(title: title, url: url.absoluteString)
                aiSummary = result.summary
                aiTags = result.tags
                semaphore.signal()
            }
            
            // Wait up to 15 seconds for AI response, then proceed with fallback
            let timeout = semaphore.wait(timeout: .now() + 15)
            if timeout == .timedOut {
                // Use mock fallback if API times out
                aiSummary = self?.generateMockSummary(title: title, url: url) ?? "值得收藏的内容。"
                aiTags = self?.generateMockTags(title: title, url: url) ?? ["Article"]
            }
            
            // Create and save item
            let newItem = AssetItem(
                url: url.absoluteString,
                title: title,
                imageUrl: imageUrl,
                sourceAppName: sourceApp,
                summary: aiSummary,
                tags: aiTags,
                coverEmoji: randomEmoji,
                coverColor: randomColor
            )
            
            StorageManager.shared.save(newItem)
            
            // Complete request on main thread
            DispatchQueue.main.async {
                extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
    }
    
    // MARK: - Metadata Extraction Helpers
    
    private func extractMetaContent(from html: String, property: String) -> String? {
        // Look for <meta property="og:image" content="..."> or <meta name="twitter:image" content="...">
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
    
    private func saveImageToAppGroup(_ imageData: Data) -> String? {
        // Get App Group container directory
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.superdaddy.Stash"
        ) else {
            return nil
        }
        
        // Create images directory if needed
        let imagesDir = containerURL.appendingPathComponent("shared_images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        
        // Generate unique filename
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDir.appendingPathComponent(filename)
        
        // Save image
        do {
            try imageData.write(to: fileURL)
            return fileURL.absoluteString // Return file:// URL
        } catch {
            print("Failed to save image: \(error)")
            return nil
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
        
        // Common app/site detection based on domain
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
            // Default to Safari for generic web links
            return "Safari"
        }
    }
    
    // MARK: - Mock AI Generation
    
    private func generateMockSummary(title: String, url: URL) -> String {
        // Mock AI summary based on title keywords
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
    
    private func generateMockTags(title: String, url: URL) -> [String] {
        var tags: [String] = []
        let titleLower = title.lowercased()
        let host = url.host?.lowercased() ?? ""
        
        // Category tags based on content
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
        
        // Source-based tags
        if host.contains("github") {
            tags.append("OpenSource")
        }
        if host.contains("youtube") || host.contains("bilibili") {
            tags.append("Video")
        }
        
        // Ensure at least one tag
        if tags.isEmpty {
            tags.append("Article")
        }
        
        // Limit to 3 tags
        return Array(tags.prefix(3))
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
}
