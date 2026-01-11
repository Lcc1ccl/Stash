import Foundation
import WebKit
import UIKit

/// 网页快照服务：使用 WKWebView 加载网页并截取快照
/// 用于在 og:image 不可用时，为卡片提供备选的缩略图
@MainActor
class WebSnapshotService: NSObject {
    static let shared = WebSnapshotService()
    
    private var webView: WKWebView?
    private var currentCompletion: ((String?) -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?
    private var isProcessing = false
    
    private let snapshotWidth: CGFloat = 375
    private let snapshotHeight: CGFloat = 300
    private let timeoutSeconds: TimeInterval = 10
    
    private override init() {
        super.init()
    }
    
    /// 为指定 URL 截取网页快照
    /// - Parameters:
    ///   - urlString: 网页 URL
    ///   - completion: 完成回调，返回本地图片路径（file:// URL 字符串）或 nil
    func captureSnapshot(for urlString: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        // 如果正在处理，跳过
        guard !isProcessing else {
            completion(nil)
            return
        }
        
        isProcessing = true
        currentCompletion = completion
        
        // 创建 WebView（必须在主线程）
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent() // 不持久化数据
        
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: snapshotWidth, height: snapshotHeight), configuration: config)
        webView.navigationDelegate = self
        webView.isHidden = true
        self.webView = webView
        
        // 设置超时
        let timeoutWork = DispatchWorkItem { [weak self] in
            self?.handleTimeout()
        }
        timeoutWorkItem = timeoutWork
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds, execute: timeoutWork)
        
        // 开始加载
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeoutSeconds)
        webView.load(request)
    }
    
    private func handleTimeout() {
        cleanup()
        currentCompletion?(nil)
        currentCompletion = nil
    }
    
    private func takeSnapshot() {
        guard let webView = webView else {
            cleanup()
            currentCompletion?(nil)
            currentCompletion = nil
            return
        }
        
        let config = WKSnapshotConfiguration()
        config.rect = CGRect(x: 0, y: 0, width: snapshotWidth, height: snapshotHeight)
        
        webView.takeSnapshot(with: config) { [weak self] image, error in
            guard let self = self else { return }
            
            if let image = image {
                // 保存图片到 App Group
                if let savedPath = self.saveImageToAppGroup(image) {
                    self.currentCompletion?(savedPath)
                } else {
                    self.currentCompletion?(nil)
                }
            } else {
                print("WebSnapshotService: Failed to take snapshot - \(error?.localizedDescription ?? "unknown error")")
                self.currentCompletion?(nil)
            }
            
            self.cleanup()
            self.currentCompletion = nil
        }
    }
    
    private func saveImageToAppGroup(_ image: UIImage) -> String? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.chaosky.Stash"
        ) else {
            print("WebSnapshotService: Failed to get App Group container")
            return nil
        }
        
        // 创建图片目录
        let imagesDir = containerURL.appendingPathComponent("shared_images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        
        // 压缩并保存
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        
        let filename = "snapshot_\(UUID().uuidString).jpg"
        let fileURL = imagesDir.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL.absoluteString
        } catch {
            print("WebSnapshotService: Failed to save image - \(error)")
            return nil
        }
    }
    
    private func cleanup() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView = nil
        isProcessing = false
    }
}

// MARK: - WKNavigationDelegate
extension WebSnapshotService: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 页面加载完成后，延迟一小段时间让页面渲染完成，再截图
        Task { @MainActor in
            // 取消超时计时器
            self.timeoutWorkItem?.cancel()
            
            // 等待 0.5 秒让页面完全渲染
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            self.takeSnapshot()
        }
    }
    
    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.cleanup()
            self.currentCompletion?(nil)
            self.currentCompletion = nil
        }
    }
    
    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.cleanup()
            self.currentCompletion?(nil)
            self.currentCompletion = nil
        }
    }
}
