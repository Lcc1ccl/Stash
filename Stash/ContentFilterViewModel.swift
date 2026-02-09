import Foundation
import Combine

@MainActor
final class ContentFilterViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedTag: String?
    @Published var activeListTab = "recent"
    
    private var shuffledAssetIDs: [UUID] = []
    
    func allTags(from assets: [AssetItem]) -> [String] {
        let all = assets.flatMap { $0.tags }
        let unique = Set(all)
        return Array(unique).sorted()
    }
    
    func suggestedTags(from assets: [AssetItem]) -> [String] {
        let all = assets.flatMap { $0.tags }
        let counts = all.reduce(into: [String: Int]()) { counts, tag in
            counts[tag, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    func displayAssets(from assets: [AssetItem]) -> [AssetItem] {
        let filtered = filteredAssets(from: assets)
        
        if activeListTab == "recent" {
            return filtered
        }
        
        if shuffledAssetIDs.isEmpty {
            return filtered
        }
        
        let lookup = Dictionary(uniqueKeysWithValues: filtered.map { ($0.id, $0) })
        let shuffled = shuffledAssetIDs.compactMap { lookup[$0] }
        let remaining = filtered.filter { !shuffledAssetIDs.contains($0.id) }
        return shuffled + remaining
    }
    
    func shuffle(using assets: [AssetItem]) {
        shuffledAssetIDs = filteredAssets(from: assets).map(\.id).shuffled()
    }
    
    func resetShuffle() {
        shuffledAssetIDs = []
    }
    
    private func filteredAssets(from assets: [AssetItem]) -> [AssetItem] {
        var result = assets
        
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }
        
        if !searchText.isEmpty {
            result = applySearchFilter(to: result)
        }
        
        return result
    }
    
    private func applySearchFilter(to items: [AssetItem]) -> [AssetItem] {
        let components = searchText.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        let searchTags = components.filter { $0.hasPrefix("#") }.map { String($0.dropFirst()).lowercased() }
        let keywords = components.filter { !$0.hasPrefix("#") }.map { String($0).lowercased() }
        
        return items.filter { item in
            let matchesTags = searchTags.allSatisfy { tagQuery in
                item.tags.contains { $0.lowercased().contains(tagQuery) }
            }
            if !matchesTags {
                return false
            }
            
            if keywords.isEmpty {
                return true
            }
            
            let keywordQuery = keywords.joined(separator: " ")
            return item.title.lowercased().contains(keywordQuery) ||
                   (item.summary?.lowercased().contains(keywordQuery) ?? false)
        }
    }
}
