import SwiftUI
import RealmSwift

struct RecapView: View {
    // Filter items from the last 7 days
    @ObservedResults(
        AssetItem.self,
        filter: NSPredicate(format: "createdAt >= %@", Calendar.current.date(byAdding: .day, value: -7, to: Date())! as NSDate),
        sortDescriptor: SortDescriptor(keyPath: "createdAt", ascending: false)
    ) var recentAssets
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if recentAssets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("本周暂无内容")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("在其他 App 中使用分享功能保存链接到 Stash")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Header stats
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(recentAssets.count)")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.blue)
                                    Text("本周保存")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Items list
                            ForEach(recentAssets) { item in
                                RecapCardView(item: item)
                                    .onTapGesture {
                                        openURL(item.url)
                                    }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("周回顾")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

struct RecapCardView: View {
    let item: AssetItem
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "link")
                        .foregroundColor(.orange)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Text(item.sourceAppName)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.7))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(item.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    RecapView()
}
