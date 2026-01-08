//
//  ContentView.swift
//  Stash
//
//  Created by 超爹 on 2026/1/5.
//

import SwiftUI
import RealmSwift

struct ContentView: View {
    @ObservedResults(AssetItem.self, sortDescriptor: SortDescriptor(keyPath: "createdAt", ascending: false)) var assets
    @Environment(\.realm) var realm
    
    // UI States
    @State private var searchText = ""
    @State private var activeTab = "inbox"
    @State private var showingSettings = false
    @State private var selectedTag: String? = nil
    @State private var isSearching = false // Search Bar Animation State
    @FocusState private var isSearchFieldFocused: Bool
    
    // Grid Columns for Themes tab
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // Computed property for all unique tags
    private var allTags: [String] {
        let all = assets.flatMap { $0.tags }
        let unique = Set(all)
        return Array(unique).sorted()
    }
    
    // Suggested tags (top 5 most frequent)
    private var suggestedTags: [String] {
        let all = assets.flatMap { $0.tags }
        let counts = all.reduce(into: [:]) { counts, tag in
            counts[tag, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    // MARK: - Filtered Assets (Search Implementation)
    private var filteredAssets: [AssetItem] {
        let unreviewedAssets = assets.filter { !$0.isReviewed }
        
        // 1. Tag Filter (from Tab Bar)
        var result = unreviewedAssets
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }
        
        guard !searchText.isEmpty else {
            return Array(result)
        }
        
        // 2. Search Text Parsing (Tags + Keywords)
        let components = searchText.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        let searchTags = components.filter { $0.hasPrefix("#") }.map { String($0.dropFirst()).lowercased() }
        let keywords = components.filter { !$0.hasPrefix("#") }.map { String($0).lowercased() }
        
        return Array(result).filter { item in
            // Match ALL parsed tags
            let matchesTags = searchTags.allSatisfy { tagQuery in
                item.tags.contains { $0.lowercased().contains(tagQuery) }
            }
            if !matchesTags { return false }
            
            // Match Keywords (if any)
            if keywords.isEmpty { return true }
            
            let keywordQuery = keywords.joined(separator: " ")
            return item.title.lowercased().contains(keywordQuery) ||
                   (item.summary?.lowercased().contains(keywordQuery) ?? false)
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color(uiColor: .gray100).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Custom Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("STASH")
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundColor(Color(uiColor: .slate900))
                                Text("DIGITAL LOOT BOX")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(uiColor: .slate400))
                                    .tracking(2)
                            }
                            Spacer()
                            Button(action: { showingSettings = true }) {
                                Circle()
                                    .fill(Color(uiColor: .gray100))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "gearshape.fill")
                                            .font(.title3)
                                            .foregroundColor(Color(uiColor: .slate500))
                                    )
                            }
                        }
                        
                        // Search Bar (Refactored)
                        SearchBarView(
                            text: $searchText,
                            isSearching: $isSearching,
                            isFocused: $isSearchFieldFocused,
                            suggestedTags: suggestedTags,
                            onTagSelected: { tag in
                                searchText = "#\(tag) " // Append tag with space and keep focus
                            },
                            onCancel: {
                                searchText = ""
                                isSearching = false
                                isSearchFieldFocused = false
                            }
                        )
                        .zIndex(10) // Ensure it floats above content when expanded
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .background(Color.white)
                    .onTapGesture {
                        dismissSearch()
                    }
                    
                    // Main Content - Switch based on activeTab
                    ZStack {
                        if activeTab == "inbox" {
                            inboxContent
                        } else {
                            themesContent
                        }
                        
                        // Tap Outside Handler
                        if isSearching {
                            Color.black.opacity(0.001) // Invisible but interactive layer
                                .edgesIgnoringSafeArea(.all)
                                .onTapGesture {
                                    dismissSearch()
                                }
                        }
                    }
                }
                
                // Floating Tab Bar with proper + button placement
                VStack(spacing: 0) {
                    // Floating + Button (above tab bar)
                    Button(action: {
                        // TODO: Add new item action (manual URL entry)
                    }) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                            .overlay(Image(systemName: "plus").font(.title2).fontWeight(.bold).foregroundColor(.white))
                    }
                    .offset(y: 28)
                    .zIndex(1)
                    
                    // Tab Bar
                    HStack(spacing: 0) {
                        Spacer()
                        TabButton(icon: "house", label: "Inbox", isActive: activeTab == "inbox") { activeTab = "inbox" }
                        Spacer()
                        Spacer()
                        Spacer()
                        TabButton(icon: "folder.fill", label: "Themes", isActive: activeTab == "themes") { activeTab = "themes" }
                        Spacer()
                    }
                    .frame(height: 70)
                    .padding(.top, 10)
                    .background(
                        Color.white
                            .cornerRadius(32, corners: [.topLeft, .topRight])
                            .shadow(color: .black.opacity(0.08), radius: 20, y: -5)
                    )
                }
            }
            .navigationBarHidden(true)
            .edgesIgnoringSafeArea(.bottom)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                NotificationManager.shared.requestAuthorization { granted in
                    if granted {
                        NotificationManager.shared.scheduleWeeklyRecap()
                    }
                }
            }
        }
    }
    
    // MARK: - Search Actions
    private func dismissSearch() {
        if isSearching {
            isSearchFieldFocused = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring()) {
                    isSearching = false
                    searchText = "" // Clear text on dismiss (Cancel behavior)
                }
            }
        }
    }

    // MARK: - Clean Up Action
    private func cleanUpItems() {
        do {
            try realm.write {
                for item in filteredAssets {
                    item.isReviewed = true
                }
            }
        } catch {
            print("Error cleaning up items: \(error)")
        }
    }
    
    // MARK: - Inbox Content
    private var inboxContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Stats Row - Now tappable
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: { showingSettings = true }) {
                            StatPill(icon: "🔥", label: "STREAK", value: "12 Days", color: .black, textColor: .white)
                        }
                        Button(action: { /* Show all assets */ }) {
                            StatPill(icon: "🧠", label: "ASSETS", value: "\(assets.count) Items", color: Color(uiColor: .gray50), textColor: Color(uiColor: .slate500))
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 8)
                
                // Tag Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "All" Tag
                        Button(action: { selectedTag = nil }) {
                            Text("全部")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(selectedTag == nil ? .white : .gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedTag == nil ? Color(uiColor: .slate900) : Color(uiColor: .gray100))
                                .cornerRadius(20)
                        }
                        
                        // Dynamic Tags
                        ForEach(allTags, id: \.self) { tag in
                            Button(action: {
                                if selectedTag == tag {
                                    selectedTag = nil
                                } else {
                                    selectedTag = tag
                                }
                            }) {
                                Text(tag)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(selectedTag == tag ? .white : .gray)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedTag == tag ? Color(uiColor: .slate900) : Color(uiColor: .gray100))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 4)
                
                // Section Header with Clean Up action
                HStack {
                    Text("Recent Loot")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Color(uiColor: .slate900))
                    
                    if !searchText.isEmpty {
                        Text("(\(filteredAssets.count) results)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if !filteredAssets.isEmpty {
                        Button(action: cleanUpItems) {
                            Text("Clean Up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.indigo)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.indigo.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Asset List
                if filteredAssets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "No items yet" : "No results found")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "Use the Share button in Safari or other apps to save links here." : "Try a different search term or tag.")
                            .font(.callout)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredAssets, id: \.id) { item in
                            NavigationLink(destination: AssetDetailView(item: item).navigationBarHidden(true)) {
                                AssetCardView(item: item)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.bottom, 120) // Space for TabBar + button
        }
    }
    
    // MARK: - Themes Content (Favorites/Collections)
    private var themesContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Section Header
                HStack {
                    Text("Smart Themes")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Color(uiColor: .slate900))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Theme Grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ThemeCard(icon: "paintpalette", title: "Design", count: assets.filter { $0.tags.contains("Design") }.count, color: .orange)
                    ThemeCard(icon: "bolt.fill", title: "AI / Tech", count: assets.filter { $0.tags.contains("LLM") || $0.tags.contains("AI") }.count, color: .blue)
                    ThemeCard(icon: "dollarsign.circle", title: "SaaS", count: assets.filter { $0.tags.contains("SaaS") || $0.tags.contains("Startup") }.count, color: .green)
                    
                    // Add New Theme Button
                    Button(action: {
                        // TODO: Add new theme
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(Color(uiColor: .gray50))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(uiColor: .gray200), style: StrokeStyle(lineWidth: 2, dash: [8]))
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 120)
        }
    }
}

// Theme Card Component
struct ThemeCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .padding(.bottom, 16)
            
            Spacer()
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(uiColor: .slate900))
            Text("\(count) items")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fit)
        .background(color.opacity(0.1))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// Helper Views
struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let textColor: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Text(icon).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .opacity(0.6)
                Text(value)
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(color)
        .foregroundColor(textColor)
        .cornerRadius(16)
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isActive ? "\(icon).fill" : icon)
                    .font(.system(size: 24))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(isActive ? .black : .gray)
            .frame(width: 60)
        }
    }
}

// Rounded Corner Helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}


struct SearchBarView: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    var isFocused: FocusState<Bool>.Binding
    var suggestedTags: [String]
    var onTagSelected: (String) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search... (type # for tags)", text: $text)
                    .font(.system(size: 14, weight: .bold)) // Low contrast dealt with by gray color
                    .foregroundColor(.primary)
                    .autocapitalization(.none)
                    .focused(isFocused)
                    .onChange(of: isFocused.wrappedValue) { _, focused in
                        if focused {
                            withAnimation(.spring()) {
                                isSearching = true
                            }
                        }
                    }
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                if isSearching {
                    Button("Cancel") {
                        // Clear text and focus first
                        text = ""
                        isFocused.wrappedValue = false
                        
                        // Delay state change slightly to allow keyboard dismissal to start cleanly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring()) {
                                isSearching = false
                                onCancel()
                            }
                        }
                    }
                    .foregroundColor(.blue)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding()
            .background(Color(uiColor: .gray50))
            .cornerRadius(16)
            .shadow(color: isSearching ? .black.opacity(0.1) : .clear, radius: 10, x: 0, y: 5)
            
            // Recommended Tags Panel
            if isSearching {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommended Tags")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.top, 16)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedTags, id: \.self) { tag in
                                Button(action: { onTagSelected(tag) }) {
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
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .padding(.bottom, 12)
            }
        }
        .padding(isSearching ? 8 : 0) // Expand padding slightly when active
        .background(isSearching ? Color.white : Color.clear)
        .cornerRadius(isSearching ? 24 : 0)
        .shadow(color: isSearching ? .black.opacity(0.15) : .clear, radius: 20, x: 0, y: 10)
        .onTapGesture {
            // Swallow taps on the search bar itself prevents triggering the parent's dismiss handler
        }
    }
}

#Preview {
    ContentView()
}
