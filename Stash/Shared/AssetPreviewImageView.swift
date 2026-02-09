import SwiftUI
import UIKit

struct AssetPreviewImageView: View {
    let imageUrl: String?
    let fallbackEmoji: String
    let fallbackEmojiSize: CGFloat
    let aspectMode: ContentMode
    
    @State private var localImage: UIImage?
    @State private var localLoadFailed = false
    
    var body: some View {
        Group {
            if let source = imageUrl, !source.isEmpty {
                if source.hasPrefix("file://"), let fileURL = URL(string: source) {
                    localFileImage(fileURL: fileURL, source: source)
                } else if let remoteURL = URL(string: source) {
                    AsyncImage(url: remoteURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: aspectMode)
                        case .failure:
                            fallbackView
                        case .empty:
                            ProgressView()
                        @unknown default:
                            fallbackView
                        }
                    }
                } else {
                    fallbackView
                }
            } else {
                fallbackView
            }
        }
    }
    
    @ViewBuilder
    private func localFileImage(fileURL: URL, source: String) -> some View {
        if let localImage {
            Image(uiImage: localImage)
                .resizable()
                .aspectRatio(contentMode: aspectMode)
        } else if localLoadFailed {
            fallbackView
        } else {
            ProgressView()
                .task(id: source) {
                    await loadLocalImage(from: fileURL)
                }
        }
    }
    
    @ViewBuilder
    private var fallbackView: some View {
        Text(fallbackEmoji)
            .font(.system(size: fallbackEmojiSize))
    }
    
    @MainActor
    private func loadLocalImage(from fileURL: URL) async {
        guard localImage == nil else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: fileURL)
            guard let image = UIImage(data: data) else {
                localLoadFailed = true
                return
            }
            localImage = image
        } catch {
            localLoadFailed = true
        }
    }
}
