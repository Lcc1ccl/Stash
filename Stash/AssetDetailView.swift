import SwiftUI
import RealmSwift

struct AssetDetailView: View {
    @ObservedRealmObject var item: AssetItem
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var aiService = AIService()
    @State private var chatInput = ""
    @State private var chatHistory: [ChatMessage] = []
    @State private var isThinking = false
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: String // "user" or "ai"
        let text: String
    }
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Nav Bar
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Circle()
                            .fill(Color(uiColor: .gray100))
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "xmark").foregroundColor(Color(uiColor: .slate900)))
                    }
                    Spacer()
                    Button(action: {}) {
                        Circle()
                             .fill(Color(uiColor: .gray50)) // Placeholder for bookmark interaction
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "bookmark").foregroundColor(Color(uiColor: .slate900)))
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Cover: Image or Emoji
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
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
                                    // Remote URL
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        case .failure(_):
                                            Text(item.coverEmoji)
                                                .font(.system(size: 80))
                                        case .empty:
                                            ProgressView()
                                        @unknown default:
                                            Text(item.coverEmoji)
                                                .font(.system(size: 80))
                                        }
                                    }
                                } else {
                                    Text(item.coverEmoji)
                                        .font(.system(size: 80))
                                }
                            } else {
                                Text(item.coverEmoji)
                                    .font(.system(size: 80))
                            }
                        }
                        .aspectRatio(16/9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 0)
                        
                        // Title & Meta
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(Color(uiColor: .slate900))
                            
                            HStack {
                                Text(item.sourceAppName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.black)
                                    .cornerRadius(100)
                                
                                Text(item.createdAt, style: .date)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(uiColor: .gray300))
                            }
                        }
                        
                        // AI Insight
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.indigo)
                                    .opacity(0.5)
                                Text("AI INSIGHT")
                                    .font(.system(size: 10, weight: .heavy))
                                    .tracking(1)
                                    .foregroundColor(.indigo)
                                Spacer()
                            }
                            
                            Text(item.summary ?? "No summary available. Tap to generate.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(uiColor: .slate500))
                                .lineSpacing(4)
                        }
                        .padding(24)
                        .background(Color.indigo.opacity(0.05))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.indigo.opacity(0.1), lineWidth: 1)
                        )
                        
                        // Tags
                        FlowLayout(spacing: 8) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(uiColor: .slate500))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(uiColor: .gray100))
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Action Buttons Row
                        HStack(spacing: 12) {
                            // Open in Safari Button
                            Button(action: openInSafari) {
                                HStack {
                                    Image(systemName: "safari")
                                        .font(.system(size: 20))
                                    Text("Open in Safari")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(16)
                            }
                            
                            // Mark as Read Button
                            Button(action: markAsRead) {
                                VStack(spacing: 4) {
                                    Image(systemName: item.isReviewed ? "checkmark.circle.fill" : "checkmark.circle")
                                        .font(.system(size: 24))
                                    Text(item.isReviewed ? "已读" : "标记已读")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(item.isReviewed ? .white : .green)
                                .frame(width: 70)
                                .padding(.vertical, 12)
                                .background(item.isReviewed ? Color.green : Color.green.opacity(0.1))
                                .cornerRadius(16)
                            }
                        }
                        
                        Divider().padding(.vertical, 8)
                        
                        // Chat Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "message.fill") // Placeholder for Bot icon replacement
                                    .foregroundColor(Color(uiColor: .slate900))
                                Text("Ask Gemini")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(Color(uiColor: .slate900))
                            }
                            
                            VStack(spacing: 12) {
                                if chatHistory.isEmpty {
                                    Text("Ask me anything about this bookmark!")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .padding()
                                }
                                
                                ForEach(chatHistory, id: \.id) { msg in
                                ChatBubbleView(msg: msg)
                                }
                                
                                if isThinking {
                                    HStack {
                                        Text("...")
                                            .font(.system(size: 20, weight: .black))
                                            .foregroundColor(.gray)
                                            .padding(.leading, 12)
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .background(Color(uiColor: .gray50))
                            .cornerRadius(24)
                            .frame(minHeight: 200, alignment: .top)
                            
                            // Input
                            HStack {
                                TextField("Ask about this bookmark...", text: $chatInput)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(uiColor: .gray200), lineWidth: 1)
                                    )
                                
                                Button(action: sendMessage) {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.indigo)
                                        .cornerRadius(12)
                                }
                                .disabled(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isThinking)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
             if chatHistory.isEmpty {
                 chatHistory.append(ChatMessage(role: "ai", text: "I've analyzed \"\(item.title)\". Ask me anything!"))
             }
        }
    }
    
    private var coverColor: Color {
        switch item.coverColor {
        case "bg-blue-100": return Color.blue.opacity(0.1)
        case "bg-orange-100": return Color.orange.opacity(0.1)
        case "bg-stone-200": return Color.gray.opacity(0.2)
        default: return Color.gray.opacity(0.1)
        }
    }
    
    private func openInSafari() {
        guard let url = URL(string: item.url) else { return }
        UIApplication.shared.open(url)
    }
    
    private func markAsRead() {
        guard let realm = item.realm else { return }
        do {
            try realm.write {
                item.isReviewed = true
            }
        } catch {
            print("Error marking item as read: \(error)")
        }
    }
    
    private func sendMessage() {
        let userMsg = chatInput
        guard !userMsg.isEmpty else { return }
        
        chatInput = ""
        chatHistory.append(ChatMessage(role: "user", text: userMsg))
        isThinking = true
        
        Task {
            let response = await aiService.chat(query: userMsg, context: item.title)
            await MainActor.run {
                isThinking = false
                chatHistory.append(ChatMessage(role: "ai", text: response))
            }
        }
    }
}

// Simple FlowLayout helper since it's not standard in older SwiftUI, relying on wrapping HStacks
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        return rows.last?.maxY ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        for row in rows {
            for element in row.elements {
                element.subview.place(at: CGPoint(x: bounds.minX + element.x, y: bounds.minY + element.y), proposal: proposal)
            }
        }
    }
    
    struct Row {
        var elements: [Element] = []
        var y: CGFloat = 0
        var height: CGFloat = 0
        
        var maxY: CGSize {
            CGSize(width: 0, height: y + height)
        }
    }
    
    struct Element {
        var subview: LayoutSubview
        var x: CGFloat
        var y: CGFloat
    }
    
    func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && !currentRow.elements.isEmpty {
                rows.append(currentRow)
                y += currentRow.height + spacing
                x = 0
                currentRow = Row(y: y, height: 0)
            }
            
            currentRow.elements.append(Element(subview: subview, x: x, y: y))
            currentRow.height = max(currentRow.height, size.height)
            x += size.width + spacing
        }
        
        if !currentRow.elements.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}
