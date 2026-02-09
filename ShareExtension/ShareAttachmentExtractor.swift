import Foundation
import UniformTypeIdentifiers
import UIKit

struct ShareAttachmentExtractionResult {
    let url: URL?
    let imageData: Data?
}

final class ShareAttachmentExtractor {
    func extract(from item: NSExtensionItem, completion: @escaping (ShareAttachmentExtractionResult) -> Void) {
        let providers = item.attachments ?? []
        guard !providers.isEmpty else {
            completion(ShareAttachmentExtractionResult(url: nil, imageData: nil))
            return
        }
        
        let group = DispatchGroup()
        var extractedURL: URL?
        var extractedImageData: Data?
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    if let url = item as? URL {
                        extractedURL = url
                    }
                    group.leave()
                }
            }
            
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                    if let imageURL = item as? URL {
                        self.loadData(from: imageURL) { data in
                            extractedImageData = data
                            group.leave()
                        }
                        return
                    }
                    if let image = item as? UIImage {
                        extractedImageData = image.jpegData(compressionQuality: 0.7)
                    } else if let data = item as? Data {
                        extractedImageData = data
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(ShareAttachmentExtractionResult(url: extractedURL, imageData: extractedImageData))
        }
    }
    
    private func loadData(from url: URL, completion: @escaping (Data?) -> Void) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        URLSession.shared.dataTask(with: request) { data, _, _ in
            completion(data)
        }.resume()
    }
}
