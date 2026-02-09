import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    private var extractedURL: URL?
    private var extractedImageData: Data?
    private let attachmentExtractor = ShareAttachmentExtractor()
    private let ingestionPipeline = ShareIngestionPipeline()

    override func isContentValid() -> Bool {
        true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Save to Stash"
        extractAttachments()
    }

    private func extractAttachments() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }
        attachmentExtractor.extract(from: extensionItem) { [weak self] result in
            self?.extractedURL = result.url
            self?.extractedImageData = result.imageData
        }
    }

    override func didSelectPost() {
        guard let url = extractedURL else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
        
        let extensionContext = self.extensionContext
        let imageData = extractedImageData
        
        Task {
            let newItem = await ingestionPipeline.buildAssetItem(url: url, attachedImageData: imageData)
            _ = StorageManager.shared.saveResult(newItem)
            
            await MainActor.run {
                extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
    }
    
    override func configurationItems() -> [Any]! {
        []
    }
}
