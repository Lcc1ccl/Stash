import SwiftUI
import RealmSwift

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var creditsManager = CreditsManager.shared
    
    @State private var showingLogin = false
    @State private var showingSubscription = false
    @State private var showingRecap = false
    @State private var notificationsEnabled = true
    
    // AI Provider Config
    @ObservedResults(AIProviderConfig.self) var aiConfigs
    
    private var aiConfig: AIProviderConfig? {
        aiConfigs.first
    }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Account Section
                Section {
                    if authManager.isLoggedIn, let user = authManager.currentUser {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(String(user.displayName.prefix(1)).uppercased())
                                        .font(.title2.bold())
                                        .foregroundColor(.blue)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        Button("登出") {
                            authManager.logout()
                        }
                        .foregroundColor(.red)
                    } else {
                        Button {
                            showingLogin = true
                        } label: {
                            HStack {
                                Image(systemName: "person.circle")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                Text("登录 / 注册")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("账号")
                }
                
                // MARK: - Subscription Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(creditsManager.currentPlan.displayName)
                                    .font(.headline)
                                if creditsManager.currentPlan != .free {
                                    Text("PRO")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                            Text("\(creditsManager.creditsRemaining) / \(creditsManager.currentPlan.dailyCredits) 积分")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Credits Progress Ring
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: CGFloat(creditsManager.creditsRemaining) / CGFloat(creditsManager.currentPlan.dailyCredits))
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 40, height: 40)
                    }
                    .padding(.vertical, 4)
                    
                    Button {
                        showingSubscription = true
                    } label: {
                        HStack {
                            Text("升级方案")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("订阅与积分")
                }
                
                // MARK: - AI Settings Section
                Section {
                    NavigationLink {
                        AIProviderSettingsView()
                    } label: {
                        HStack {
                            Text("AI 提供方")
                            Spacer()
                            Text(aiConfig?.provider.displayName ?? "默认")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("AI 设置")
                }
                
                // MARK: - General Settings Section
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("周回顾通知", systemImage: "bell")
                    }
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            NotificationManager.shared.requestAuthorization { granted in
                                if granted {
                                    NotificationManager.shared.scheduleWeeklyRecap()
                                }
                            }
                        }
                    }
                    
                    Button {
                        showingRecap = true
                    } label: {
                        Label("查看周回顾", systemImage: "calendar")
                    }
                    
                    Button(role: .destructive) {
                        clearCache()
                    } label: {
                        Label("清除缓存", systemImage: "trash")
                    }
                } header: {
                    Text("通用")
                }
                
                // MARK: - About Section
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "mailto:feedback@stash.app")!) {
                        Label("反馈建议", systemImage: "envelope")
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingLogin) {
                LoginView()
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $showingRecap) {
                RecapView()
            }
        }
    }
    
    private func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
}

// MARK: - AI Provider Settings View

struct AIProviderSettingsView: View {
    @Environment(\.realm) var realm
    @ObservedResults(AIProviderConfig.self) var aiConfigs
    
    @State private var selectedProvider: AIProvider = .builtin
    @State private var apiKey: String = ""
    @State private var customEndpoint: String = ""
    
    private var config: AIProviderConfig? {
        aiConfigs.first
    }
    
    var body: some View {
        Form {
            Section {
                ForEach(AIProvider.allCases, id: \.self) { provider in
                    Button {
                        selectedProvider = provider
                        saveConfig()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(provider.displayName)
                                    .foregroundColor(.primary)
                                if provider == .builtin {
                                    Text("使用订阅积分")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("使用自己的 API Key")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if selectedProvider == provider {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } header: {
                Text("选择提供方")
            }
            
            if selectedProvider.requiresApiKey {
                Section {
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                        .onChange(of: apiKey) { _, _ in
                            saveConfig()
                        }
                    
                    TextField("自定义端点 (可选)", text: $customEndpoint)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .onChange(of: customEndpoint) { _, _ in
                            saveConfig()
                        }
                } header: {
                    Text("API 配置")
                } footer: {
                    Text("使用自定义 API Key 不消耗订阅积分")
                }
            }
        }
        .navigationTitle("AI 提供方")
        .onAppear {
            loadConfig()
        }
    }
    
    private func loadConfig() {
        if let config = config {
            selectedProvider = config.provider
            apiKey = config.customApiKey
            customEndpoint = config.customEndpoint
        }
    }
    
    private func saveConfig() {
        try? realm.write {
            if let config = config {
                config.provider = selectedProvider
                config.customApiKey = apiKey
                config.customEndpoint = customEndpoint
            } else {
                let newConfig = AIProviderConfig()
                newConfig.provider = selectedProvider
                newConfig.customApiKey = apiKey
                newConfig.customEndpoint = customEndpoint
                realm.add(newConfig)
            }
        }
    }
}

#Preview {
    SettingsView()
}
