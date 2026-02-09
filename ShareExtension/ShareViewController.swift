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
            let saveResult = StorageManager.shared.saveResult(newItem)
            
            await MainActor.run {
                switch saveResult {
                case .success:
                    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                case .failure(let error):
                    presentSaveErrorAlert(error: error, extensionContext: extensionContext)
                }
            }
        }
    }
    
    override func configurationItems() -> [Any]! {
        []
    }
    
    private func presentSaveErrorAlert(error: StorageError, extensionContext: NSExtensionContext?) {
        let alert = UIAlertController(
            title: "保存失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "关闭", style: .cancel) { _ in
            extensionContext?.cancelRequest(withError: error.asNSError)
        })
        alert.addAction(UIAlertAction(title: "仍然退出", style: .default) { _ in
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        })
        present(alert, animated: true)
    }
}

private extension StorageError {
    var asNSError: NSError {
        NSError(
            domain: "ShareExtension.Storage",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription]
        )
    }
}
