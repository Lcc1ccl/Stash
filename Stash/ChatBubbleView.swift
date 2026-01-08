import SwiftUI

struct ChatBubbleView: View {
    let msg: AssetDetailView.ChatMessage
    
    var body: some View {
        HStack {
            if msg.role == "user" { Spacer() }
            Text(msg.text)
                .font(.system(size: 14, weight: .medium))
                .padding(12)
                .background(msg.role == "user" ? Color(uiColor: .slate900) : Color.white)
                .foregroundColor(msg.role == "user" ? .white : Color(uiColor: .slate700))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            if msg.role == "ai" { Spacer() }
        }
    }
}
