import SwiftUI
import RealmSwift
import Supabase

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
                    if authManager.isOfflineMode {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("账号服务离线", systemImage: "wifi.slash")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.orange)
                            Text(authManager.offlineReason ?? "云端认证服务当前不可用。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if authManager.isLoggedIn, let user = authManager.currentUser {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(String((user.email ?? "U").prefix(1)).uppercased())
                                        .font(.title2.bold())
                                        .foregroundColor(.blue)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.email?.components(separatedBy: "@").first ?? "用户")
                                    .font(.headline)
                                Text(user.email ?? "")
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
                        .accessibilityIdentifier("settings.loginButton")
                        .disabled(authManager.isOfflineMode)
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
                            Text(String(format: "%.1f / %d 积分", creditsManager.creditsRemaining, creditsManager.currentPlan.dailyCredits))
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
                    .accessibilityIdentifier("settings.upgradePlanButton")
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
                    .accessibilityIdentifier("settings.notificationToggle")
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
    @ObservedObject private var creditsManager = CreditsManager.shared
    
    @State private var selectedProvider: AIProvider = .builtin
    @State private var apiKey: String = ""
    @State private var customEndpoint: String = ""
    @State private var initialProvider: AIProvider = .builtin
    @State private var initialAPIKey: String = ""
    @State private var initialCustomEndpoint: String = ""
    
    // Alert states
    @State private var showingUnlockConfirm = false
    @State private var showingInsufficientCredits = false
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    @State private var isSaving = false
    
    private var config: AIProviderConfig? {
        aiConfigs.first
    }
    
    /// 是否需要解锁（选择了自定义提供方且尚未解锁）
    private var needsUnlock: Bool {
        selectedProvider.requiresApiKey && !creditsManager.customProviderUnlocked
    }
    
    /// 是否有未保存的更改
    private var hasChanges: Bool {
        selectedProvider != initialProvider ||
        apiKey != initialAPIKey ||
        customEndpoint != initialCustomEndpoint
    }
    
    var body: some View {
        Form {
            Section {
                ForEach(AIProvider.allCases, id: \.self) { provider in
                    Button {
                        selectedProvider = provider
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
            } footer: {
                if needsUnlock {
                    Text("⚡ 首次启用自定义提供方需消耗 10 积分（一次性）")
                        .foregroundColor(.orange)
                }
            }
            
            if selectedProvider.requiresApiKey {
                Section {
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                    
                    TextField("自定义端点 (可选)", text: $customEndpoint)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                } header: {
                    Text("API 配置")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("使用自定义 API Key 不消耗订阅积分")
                        if creditsManager.customProviderUnlocked {
                            Label("已解锁自定义提供方", systemImage: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Save Button Section
            if hasChanges {
                Section {
                    Button {
                        handleSave()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("保存设置")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .navigationTitle("AI 提供方")
        .onAppear {
            loadConfig()
        }
        .alert("解锁自定义提供方", isPresented: $showingUnlockConfirm) {
            Button("取消", role: .cancel) { }
            Button("确认解锁") {
                Task {
                    await performUnlockAndSave()
                }
            }
        } message: {
            Text("首次使用自定义 AI 提供方需消耗 10 积分。\n\n当前积分：\(String(format: "%.1f", creditsManager.creditsRemaining))\n\n解锁后可自由切换，不再重复扣费。")
        }
        .alert("积分不足", isPresented: $showingInsufficientCredits) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text("启用自定义提供方需要 10 积分。\n当前积分：\(String(format: "%.1f", creditsManager.creditsRemaining))\n\n请升级订阅或等待每日积分刷新。")
        }
        .alert("配置无效", isPresented: $showingValidationError) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text(validationErrorMessage)
        }
    }
    
    private func loadConfig() {
        if let config = config {
            selectedProvider = config.provider
            apiKey = resolveAPIKey(from: config)
            customEndpoint = config.customEndpoint
            migrateLegacyAPIKeyIfNeeded(config)
            syncInitialState()
        } else {
            selectedProvider = .builtin
            apiKey = ""
            customEndpoint = ""
            syncInitialState()
        }
    }
    
    private func handleSave() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKey = trimmedKey
        
        if selectedProvider.requiresApiKey,
           let validationError = validateAPIKey(trimmedKey, provider: selectedProvider) {
            validationErrorMessage = validationError
            showingValidationError = true
            return
        }
        
        // 如果选择了自定义提供方且尚未解锁
        if needsUnlock {
            // 检查积分是否足够
            if creditsManager.creditsRemaining >= AICreditsCost.customProviderUnlock {
                showingUnlockConfirm = true
            } else {
                showingInsufficientCredits = true
            }
        } else {
            // 已解锁或选择默认提供方，直接保存
            saveConfig()
        }
    }
    
    private func performUnlockAndSave() async {
        isSaving = true
        let success = await creditsManager.unlockCustomProvider()
        isSaving = false
        
        if success {
            saveConfig()
        } else {
            showingInsufficientCredits = true
        }
    }
    
    private func saveConfig() {
        do {
            try realm.write {
                let targetConfig: AIProviderConfig
                if let existing = config {
                    targetConfig = existing
                } else {
                    let created = AIProviderConfig()
                    realm.add(created)
                    targetConfig = created
                }
                
                targetConfig.provider = selectedProvider
                targetConfig.customEndpoint = customEndpoint
                
                if selectedProvider.requiresApiKey {
                    try persistAPIKey(apiKey, into: targetConfig)
                } else {
                    targetConfig.customApiKey = ""
                }
            }
            syncInitialState()
        } catch {
            validationErrorMessage = "保存 API 配置失败：\(error.localizedDescription)"
            showingValidationError = true
        }
    }
    
    private func validateAPIKey(_ key: String, provider: AIProvider) -> String? {
        if key.isEmpty {
            return "请输入 API Key 后再保存。"
        }
        if key.count < 16 {
            return "API Key 长度过短，请检查是否完整。"
        }
        
        switch provider {
        case .openai where !key.hasPrefix("sk-"):
            return "OpenAI Key 通常以 `sk-` 开头，请确认后重试。"
        case .anthropic where !key.hasPrefix("sk-ant-"):
            return "Anthropic Key 通常以 `sk-ant-` 开头，请确认后重试。"
        default:
            return nil
        }
    }
    
    private func persistAPIKey(_ key: String, into config: AIProviderConfig) throws {
        let reference = keychainReference(from: config.customApiKey) ?? "ai-provider.\(config.id.uuidString)"
        try SecureKeyStore.shared.save(key, for: reference)
        config.customApiKey = "kc://\(reference)"
    }
    
    private func resolveAPIKey(from config: AIProviderConfig) -> String {
        guard let reference = keychainReference(from: config.customApiKey) else {
            return config.customApiKey
        }
        
        return (try? SecureKeyStore.shared.load(for: reference)) ?? ""
    }
    
    private func migrateLegacyAPIKeyIfNeeded(_ config: AIProviderConfig) {
        guard !config.customApiKey.isEmpty,
              keychainReference(from: config.customApiKey) == nil else {
            return
        }
        
        do {
            try realm.write {
                try persistAPIKey(config.customApiKey, into: config)
            }
            apiKey = resolveAPIKey(from: config)
        } catch {
            validationErrorMessage = "迁移旧 API Key 到安全存储失败：\(error.localizedDescription)"
            showingValidationError = true
        }
    }
    
    private func keychainReference(from storedValue: String) -> String? {
        guard storedValue.hasPrefix("kc://") else {
            return nil
        }
        return String(storedValue.dropFirst(5))
    }
    
    private func syncInitialState() {
        initialProvider = selectedProvider
        initialAPIKey = apiKey
        initialCustomEndpoint = customEndpoint
    }
}

#Preview {
    SettingsView()
}
