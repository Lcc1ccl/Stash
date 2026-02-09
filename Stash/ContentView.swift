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
    @StateObject private var filterModel = ContentFilterViewModel()
    
    // UI States
    @State private var activeTab = "inbox"
    @State private var showingSettings = false
    @State private var isSearching = false // Search Bar Animation State
    @State private var operationErrorMessage: String?
    @FocusState private var isSearchFieldFocused: Bool
    
    // Grid Columns for Themes tab
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private var allAssets: [AssetItem] {
        Array(assets)
    }
    
    private var allTags: [String] {
        filterModel.allTags(from: allAssets)
    }
    
    private var suggestedTags: [String] {
        filterModel.suggestedTags(from: allAssets)
    }
    
    private var displayAssets: [AssetItem] {
        filterModel.displayAssets(from: allAssets)
    }
    
    private var storageWarningMessage: String? {
        guard StorageManager.shared.sharedRealmConfiguration() == nil else {
            return nil
        }
        return "共享存储不可用，当前已切换为离线本地存储模式。"
    }


    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(uiColor: .gray100).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Custom Header
                    VStack(alignment: .leading, spacing: 0) {
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
                            
                            // Search Button
                            Button(action: {
                                if isSearching {
                                    dismissSearch()
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isSearching = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isSearchFieldFocused = true
                                    }
                                }
                            }) {
                                Circle()
                                    .fill(isSearching ? Color.indigo.opacity(0.1) : Color(uiColor: .gray100))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "magnifyingglass")
                                            .font(.title3)
                                            .foregroundColor(isSearching ? .indigo : Color(uiColor: .slate500))
                                    )
                            }
                            
                            // Settings Button
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
                            .accessibilityIdentifier("content.settingsButton")
                        }
                        
                        // Expandable Search Panel
                        if isSearching {
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    
                                    TextField("Search... (type # for tags)", text: $filterModel.searchText)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                        .autocapitalization(.none)
                                        .focused($isSearchFieldFocused)
                                    
                                    if !filterModel.searchText.isEmpty {
                                        Button(action: { filterModel.searchText = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Button("Cancel") {
                                        filterModel.searchText = ""
                                        isSearchFieldFocused = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.spring()) {
                                                isSearching = false
                                            }
                                        }
                                    }
                                    .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color(uiColor: .gray50))
                                .cornerRadius(16)
                                
                                // Recommended Tags Panel
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recommended Tags")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.gray)
                                        .padding(.top, 16)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(suggestedTags, id: \.self) { tag in
                                                Button(action: { filterModel.searchText = "#\(tag) " }) {
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
                                .padding(.bottom, 12)
                            }
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                            .padding(.top, 8)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)),
                                removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing))
                            ))
                            .onTapGesture {
                                // Prevent tap from propagating to parent
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, isSearching ? 16 : 24)
                    .background(Color.white)
                    .zIndex(10)
                    .onTapGesture {
                        // Tap on header area dismisses search
                        if isSearching {
                            dismissSearch()
                        }
                    }
                    
                    if let storageWarningMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(storageWarningMessage)
                                .font(.caption.weight(.medium))
                                .foregroundColor(Color(uiColor: .slate500))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
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
            .alert("操作失败", isPresented: Binding(
                get: { operationErrorMessage != nil },
                set: { newValue in
                    if !newValue {
                        operationErrorMessage = nil
                    }
                }
            )) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(operationErrorMessage ?? "请稍后再试。")
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
                        filterModel.searchText = "" // Clear text on dismiss (Cancel behavior)
                    }
                }
            }
        }

    // MARK: - Shuffle Action (for All Loots tab) - One-time action
    private func shuffleAssets() {
        filterModel.shuffle(using: allAssets)
    }
    
    // MARK: - Mark as Read Action
    private func markAsRead(_ item: AssetItem) {
        do {
            try realm.write {
                item.isReviewed = true
            }
        } catch {
            operationErrorMessage = "标记已读失败：\(error.localizedDescription)"
        }
    }
    
    // MARK: - Delete Item Action
    private func deleteItem(_ item: AssetItem) {
        do {
            try realm.write {
                realm.delete(item)
            }
        } catch {
            operationErrorMessage = "删除失败：\(error.localizedDescription)"
        }
    }
    
    // MARK: - Inbox Content
    private var inboxContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Stats Row - Full Width 50/50
                HStack(spacing: 12) {
                    Button(action: { /* Streak stats - future feature */ }) {
                        StatPill(icon: "🔥", label: "STREAK", value: "12 Days", color: .black, textColor: .white)
                            .frame(maxWidth: .infinity)
                    }
                    Button(action: { /* Show all assets */ }) {
                        StatPill(icon: "🧠", label: "ASSETS", value: "\(assets.count) Items", color: Color(uiColor: .gray50), textColor: Color(uiColor: .slate500))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Tag Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "All" Tag
                        Button(action: { filterModel.selectedTag = nil }) {
                            Text("全部")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(filterModel.selectedTag == nil ? .white : .gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(filterModel.selectedTag == nil ? Color(uiColor: .slate900) : Color(uiColor: .gray100))
                                .cornerRadius(20)
                        }
                        
                        // Dynamic Tags
                        ForEach(allTags, id: \.self) { tag in
                            Button(action: {
                                if filterModel.selectedTag == tag {
                                    filterModel.selectedTag = nil
                                } else {
                                    filterModel.selectedTag = tag
                                }
                            }) {
                                Text(tag)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(filterModel.selectedTag == tag ? .white : .gray)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(filterModel.selectedTag == tag ? Color(uiColor: .slate900) : Color(uiColor: .gray100))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 4)
                
                // Section Header with Tab Switch
                HStack {
                    // Tab: Recent Loot
                    Button(action: {
                        filterModel.activeListTab = "recent"
                        filterModel.resetShuffle()
                    }) {
                        Text("Recent Loot")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(filterModel.activeListTab == "recent" ? Color(uiColor: .slate900) : Color(uiColor: .gray300))
                    }
                    
                    Text("/")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Color(uiColor: .gray200))
                        .padding(.horizontal, 4)
                    
                    // Tab: All Loots
                    Button(action: {
                        filterModel.activeListTab = "all"
                        filterModel.resetShuffle()
                    }) {
                        Text("All Loots")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(filterModel.activeListTab == "all" ? Color(uiColor: .slate900) : Color(uiColor: .gray300))
                    }
                    
                    if !filterModel.searchText.isEmpty {
                        Text("(\(displayAssets.count) results)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Right side buttons based on active tab
                    if filterModel.activeListTab == "all" {
                        HStack(spacing: 8) {
                            // Shuffle Button - One-time action, no highlight state
                            Button(action: shuffleAssets) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.indigo)
                                    .padding(8)
                                    .background(Color.indigo.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            // View Menu Button
                            Menu {
                                Section("视图") {
                                    Button(action: {}) {
                                        Label("卡片", systemImage: "rectangle.grid.1x2")
                                    }
                                    Button(action: {}) {
                                        Label("列表", systemImage: "list.bullet")
                                    }
                                    Button(action: {}) {
                                        Label("平铺", systemImage: "rectangle.grid.2x2")
                                    }
                                }
                                Section("排序") {
                                    Button(action: {}) {
                                        Label("最新添加", systemImage: "arrow.down")
                                    }
                                    Button(action: {}) {
                                        Label("最早添加", systemImage: "arrow.up")
                                    }
                                }
                                Section("分类依据") {
                                    Button(action: {}) {
                                        Label("来源平台", systemImage: "globe")
                                    }
                                    Button(action: {}) {
                                        Label("添加日期", systemImage: "calendar")
                                    }
                                    Button(action: {}) {
                                        Label("已读状态", systemImage: "checkmark.circle")
                                    }
                                }
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.indigo)
                                    .padding(8)
                                    .background(Color.indigo.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Asset List with Swipe Actions
                if displayAssets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: filterModel.searchText.isEmpty ? "tray" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(filterModel.searchText.isEmpty ? "No items yet" : "No results found")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Text(filterModel.searchText.isEmpty ? "Use the Share button in Safari or other apps to save links here." : "Try a different search term or tag.")
                            .font(.callout)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(displayAssets, id: \.id) { item in
                            SwipeableAssetCard(item: item, onMarkRead: markAsRead, onDelete: deleteItem)
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
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
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


// MARK: - Swipeable Asset Card with Actions
struct SwipeableAssetCard: View {
    @ObservedRealmObject var item: AssetItem
    var onMarkRead: (AssetItem) -> Void
    var onDelete: (AssetItem) -> Void
    
    @State private var offset: CGFloat = 0
    @State private var showingActions = false
    @State private var isDragging = false
    @State private var navigateToDetail = false
    
    private let actionWidth: CGFloat = 160
    private let swipeThreshold: CGFloat = 20 // 水平滑动阈值
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Action Buttons (behind the card)
            HStack(spacing: 0) {
                Spacer()
                
                // Mark as Read Button
                Button(action: {
                    withAnimation(.spring()) {
                        offset = 0
                        showingActions = false
                    }
                    onMarkRead(item)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: item.isReviewed ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 20))
                        Text("已读")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 100)
                    .background(Color.green)
                }
                
                // Delete Button
                Button(action: {
                    withAnimation(.spring()) {
                        offset = 0
                        showingActions = false
                    }
                    onDelete(item)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                        Text("删除")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 100)
                    .background(Color.red)
                }
            }
            .cornerRadius(24)
            .padding(.horizontal, 16)
            
            // Main Card with manual navigation control
            AssetCardView(item: item)
                .offset(x: offset)
                .contentShape(Rectangle()) // 确保整个区域可点击
                .onTapGesture {
                    // 只有在非拖动状态且菜单未展开时才触发导航
                    if !isDragging && !showingActions && offset == 0 {
                        navigateToDetail = true
                    } else if showingActions {
                        // 点击已展开菜单的卡片，关闭菜单
                        withAnimation(.spring()) {
                            offset = 0
                            showingActions = false
                        }
                    }
                }
                .navigationDestination(isPresented: $navigateToDetail) {
                    AssetDetailView(item: item).navigationBarHidden(true)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            let horizontalMovement = abs(value.translation.width)
                            let verticalMovement = abs(value.translation.height)
                            
                            // 只有在明确是水平滑动意图时才处理
                            // 条件：水平位移 > 垂直位移的2倍，且水平位移超过阈值
                            // 一旦开始拖动，就持续跟踪直到手势结束
                            if !isDragging {
                                // 还没开始拖动，判断是否应该开始
                                let shouldStartDragging = horizontalMovement > verticalMovement * 2 
                                    && horizontalMovement > swipeThreshold
                                    && value.translation.width < 0 // 只响应左滑
                                
                                if shouldStartDragging {
                                    isDragging = true
                                }
                            }
                            
                            // 只有在拖动状态下才更新 offset
                            if isDragging {
                                if value.translation.width < 0 {
                                    // 左滑
                                    offset = max(value.translation.width, -actionWidth)
                                } else if showingActions {
                                    // 从已展开状态向右滑动关闭
                                    offset = min(0, -actionWidth + value.translation.width)
                                }
                            }
                        }
                        .onEnded { value in
                            if isDragging {
                                withAnimation(.spring()) {
                                    if value.translation.width < -50 {
                                        offset = -actionWidth
                                        showingActions = true
                                    } else {
                                        offset = 0
                                        showingActions = false
                                    }
                                }
                            }
                            // 延迟重置拖动状态，防止 onTapGesture 误触发
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isDragging = false
                            }
                        }
                )
        }
    }
}

#Preview {
    ContentView()
}
