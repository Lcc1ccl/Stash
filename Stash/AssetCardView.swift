import SwiftUI
import RealmSwift

struct AssetCardView: View {
    @ObservedRealmObject var item: AssetItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Cover + Content
            HStack(alignment: .top, spacing: 16) {
                // Cover: Image or Emoji
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(coverColor)
                    
                    if let imageUrl = item.imageUrl, !imageUrl.isEmpty {
                        // Check if it's a local file URL
                        if imageUrl.hasPrefix("file://"), let fileURL = URL(string: imageUrl),
                           let data = try? Data(contentsOf: fileURL),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if let url = URL(string: imageUrl) {
                            // Remote URL - use AsyncImage
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure(_):
                                    Text(item.coverEmoji)
                                        .font(.system(size: 40))
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    Text(item.coverEmoji)
                                        .font(.system(size: 40))
                                }
                            }
                        } else {
                            Text(item.coverEmoji)
                                .font(.system(size: 40))
                        }
                    } else {
                        Text(item.coverEmoji)
                            .font(.system(size: 40))
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Title + Source Icon
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(uiColor: .slate900))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer(minLength: 4)
                        
                        // Source App Icon (instead of text)
                        sourceAppIcon
                            .frame(width: 20, height: 20)
                    }
                    
                    // AI Summary (always show - mock or real)
                    HStack(alignment: .top, spacing: 4) {
                        Text("✨")
                            .font(.system(size: 12))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            (Text("AI Summary: ")
                                .foregroundColor(.indigo)
                             + Text(item.summary ?? "正在生成摘要中...")
                                .foregroundColor(Color(uiColor: .slate400)))
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 28) // Avoid overlap with source icon
                    }
                }
            }
            
            // Bottom Row: Tags + Timestamp
            HStack(alignment: .center) {
                // Tags
                if item.tags.isEmpty {
                    Text("#Article")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(uiColor: .slate500))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(uiColor: .gray50))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(uiColor: .gray100), lineWidth: 1)
                        )
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(item.tags), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(uiColor: .slate500))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(uiColor: .gray50))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(uiColor: .gray100), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Relative Time
                Text(relativeTime)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(uiColor: .gray300))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(uiColor: .gray100), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
    
    // MARK: - Source App Icon
    @ViewBuilder
    private var sourceAppIcon: some View {
        let appName = item.sourceAppName.lowercased()
        
        if appName.contains("safari") {
            Image(systemName: "safari")
                .foregroundColor(.blue)
        } else if appName.contains("xiaohongshu") || appName.contains("红书") {
            Image(systemName: "heart.text.square.fill")
                .foregroundColor(.red)
        } else if appName.contains("twitter") {
            Image(systemName: "bird")
                .foregroundColor(Color(red: 0.11, green: 0.63, blue: 0.95))
        } else if appName.contains("wechat") || appName.contains("微信") {
            Image(systemName: "message.fill")
                .foregroundColor(.green)
        } else if appName.contains("youtube") {
            Image(systemName: "play.rectangle.fill")
                .foregroundColor(.red)
        } else if appName.contains("instagram") {
            Image(systemName: "camera.fill")
                .foregroundColor(.purple)
        } else if appName.contains("telegram") {
            Image(systemName: "paperplane.fill")
                .foregroundColor(.blue)
        } else if appName.contains("weibo") || appName.contains("微博") {
            Image(systemName: "at")
                .foregroundColor(.orange)
        } else if appName.contains("bilibili") {
            Image(systemName: "play.tv")
                .foregroundColor(Color(red: 0.98, green: 0.45, blue: 0.55))
        } else if appName.contains("zhihu") {
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.blue)
        } else if appName.contains("github") {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .foregroundColor(.black)
        } else if appName.contains("medium") {
            Image(systemName: "doc.text")
                .foregroundColor(.black)
        } else if appName.contains("reddit") {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .foregroundColor(.orange)
        } else if appName.contains("tiktok") || appName.contains("douyin") {
            Image(systemName: "music.note")
                .foregroundColor(.black)
        } else if appName.contains("facebook") {
            Image(systemName: "person.2.fill")
                .foregroundColor(.blue)
        } else if appName.contains("linkedin") {
            Image(systemName: "briefcase.fill")
                .foregroundColor(Color(red: 0.0, green: 0.47, blue: 0.71))
        } else if appName.contains("notion") {
            Image(systemName: "doc.richtext")
                .foregroundColor(.black)
        } else if appName.contains("figma") {
            Image(systemName: "paintbrush.pointed.fill")
                .foregroundColor(.purple)
        } else {
            Image(systemName: "globe")
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Cover Color
    private var coverColor: Color {
        switch item.coverColor {
        case "bg-blue-100": return Color.blue.opacity(0.15)
        case "bg-orange-100": return Color.orange.opacity(0.15)
        case "bg-stone-200": return Color.gray.opacity(0.2)
        case "bg-green-100": return Color.green.opacity(0.15)
        case "bg-purple-100": return Color.purple.opacity(0.15)
        case "bg-pink-100": return Color.pink.opacity(0.15)
        case "bg-yellow-100": return Color.yellow.opacity(0.15)
        default: return Color.purple.opacity(0.1)
        }
    }
    
    // MARK: - Relative Time
    private var relativeTime: String {
        let now = Date()
        let interval = now.timeIntervalSince(item.createdAt)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: item.createdAt)
        }
    }
}
