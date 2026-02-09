//
//  StashApp.swift
//  Stash
//
//  Created by 超爹 on 2026/1/5.
//

import SwiftUI
import RealmSwift
import Combine

enum StartupIssue: LocalizedError, Equatable {
    case appGroupUnavailable(appGroupId: String)
    case realmInitFailed(reason: String)
    case fallbackUnavailable(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable(let appGroupId):
            return "无法访问共享存储空间（\(appGroupId)）。"
        case .realmInitFailed(let reason):
            return "数据库初始化失败：\(reason)"
        case .fallbackUnavailable(let reason):
            return "离线数据库初始化失败：\(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .appGroupUnavailable:
            return "请先尝试重新打开 App；若仍失败，可先进入离线模式继续使用。"
        case .realmInitFailed:
            return "你可以重试初始化，或进入离线模式后稍后再试。"
        case .fallbackUnavailable:
            return "请重试；若持续失败，请通过“报告问题”发送诊断信息。"
        }
    }
    
    var diagnostics: String {
        switch self {
        case .appGroupUnavailable(let appGroupId):
            return "app_group_unavailable:\(appGroupId)"
        case .realmInitFailed(let reason):
            return "realm_init_failed:\(reason)"
        case .fallbackUnavailable(let reason):
            return "fallback_realm_failed:\(reason)"
        }
    }
    
    var canContinueOffline: Bool {
        switch self {
        case .appGroupUnavailable, .realmInitFailed:
            return true
        case .fallbackUnavailable:
            return false
        }
    }
}

struct StartupBootstrapResult {
    let configuration: Realm.Configuration
    let issue: StartupIssue?
}

struct StartupBootstrapper {
    let appGroupId: String
    let schemaVersion: UInt64
    let resolveAppGroupContainer: (String) -> URL?
    let resolveDocumentsDirectory: () -> URL?
    let validateRealmConfiguration: (Realm.Configuration) throws -> Void
    
    init(
        appGroupId: String = StashRealmConfiguration.sharedAppGroupIdentifier,
        schemaVersion: UInt64 = StashRealmConfiguration.defaultSchemaVersion,
        resolveAppGroupContainer: @escaping (String) -> URL? = { appGroupId in
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        },
        resolveDocumentsDirectory: @escaping () -> URL? = {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        },
        validateRealmConfiguration: @escaping (Realm.Configuration) throws -> Void = { config in
            _ = try Realm(configuration: config)
        }
    ) {
        self.appGroupId = appGroupId
        self.schemaVersion = schemaVersion
        self.resolveAppGroupContainer = resolveAppGroupContainer
        self.resolveDocumentsDirectory = resolveDocumentsDirectory
        self.validateRealmConfiguration = validateRealmConfiguration
    }
    
    func bootstrap() -> StartupBootstrapResult {
        let databaseURL: URL
        var startupIssue: StartupIssue?
        
        if let container = resolveAppGroupContainer(appGroupId) {
            databaseURL = container.appendingPathComponent("default.realm")
        } else {
            startupIssue = .appGroupUnavailable(appGroupId: appGroupId)
            let fallbackDirectory = resolveDocumentsDirectory() ?? FileManager.default.temporaryDirectory
            databaseURL = fallbackDirectory.appendingPathComponent("fallback.realm")
            print("StashApp: Shared App Group container unavailable, using fallback Realm path")
        }
        
        let primaryConfiguration = StashRealmConfiguration.fileConfiguration(
            at: databaseURL,
            schemaVersion: schemaVersion,
            migrationLogger: { oldSchemaVersion, targetSchemaVersion in
                print("StashApp: Migrating Realm from schema version \(oldSchemaVersion) to \(targetSchemaVersion)")
            }
        )
        
        do {
            try validateRealmConfiguration(primaryConfiguration)
            print("StashApp: Realm configured at \(databaseURL.path)")
            return StartupBootstrapResult(configuration: primaryConfiguration, issue: startupIssue)
        } catch {
            print("StashApp: Failed to open primary Realm - \(error)")
            let fallbackConfiguration = StashRealmConfiguration.inMemoryConfiguration(
                identifier: "startup-fallback",
                schemaVersion: schemaVersion,
                migrationLogger: { oldSchemaVersion, targetSchemaVersion in
                    print("StashApp: Migrating Realm from schema version \(oldSchemaVersion) to \(targetSchemaVersion)")
                }
            )
            
            do {
                try validateRealmConfiguration(fallbackConfiguration)
                return StartupBootstrapResult(
                    configuration: fallbackConfiguration,
                    issue: .realmInitFailed(reason: error.localizedDescription)
                )
            } catch {
                print("StashApp: Failed to open fallback Realm - \(error)")
                return StartupBootstrapResult(
                    configuration: fallbackConfiguration,
                    issue: .fallbackUnavailable(reason: error.localizedDescription)
                )
            }
        }
    }
}

@MainActor
final class StartupState: ObservableObject {
    @Published private(set) var issue: StartupIssue?
    
    private let bootstrapper: StartupBootstrapper
    
    init(bootstrapper: StartupBootstrapper? = nil) {
        self.bootstrapper = bootstrapper ?? StartupBootstrapper()
        reconfigure()
    }
    
    func reconfigure() {
        let result = bootstrapper.bootstrap()
        Realm.Configuration.defaultConfiguration = result.configuration
        issue = result.issue
    }
    
    func continueOffline() {
        guard issue?.canContinueOffline == true else {
            return
        }
        issue = nil
    }
}

private struct StartupIssueView: View {
    @Environment(\.openURL) private var openURL
    
    let issue: StartupIssue
    let onRetry: () -> Void
    let onContinueOffline: () -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(.orange)
            
            Text("启动遇到问题")
                .font(.title3.weight(.bold))
            
            Text(issue.errorDescription ?? "未知启动错误")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            
            if let suggestion = issue.recoverySuggestion {
                Text(suggestion)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            
            Button("重试初始化") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            
            if issue.canContinueOffline {
                Button("继续离线模式") {
                    onContinueOffline()
                }
                .buttonStyle(.bordered)
            }
            
            Button("报告问题") {
                if let url = reportURL {
                    openURL(url)
                }
            }
            .font(.footnote)
        }
        .padding(28)
    }
    
    private var reportURL: URL? {
        let formatter = ISO8601DateFormatter()
        let body = """
        请描述你遇到的问题：
        
        诊断信息：\(issue.diagnostics)
        时间：\(formatter.string(from: Date()))
        """
        var components = URLComponents(string: "mailto:feedback@stash.app")
        components?.queryItems = [
            URLQueryItem(name: "subject", value: "[Stash] Startup issue"),
            URLQueryItem(name: "body", value: body)
        ]
        return components?.url
    }
}

@main
struct StashApp: SwiftUI.App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var startupState = StartupState()
    
    init() {
        // 预热关键单例（确保在主线程初始化）
        _ = AuthManager.shared
        _ = CreditsManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let issue = startupState.issue {
                    StartupIssueView(
                        issue: issue,
                        onRetry: { startupState.reconfigure() },
                        onContinueOffline: { startupState.continueOffline() }
                    )
                } else {
                    ContentView()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active, startupState.issue == nil else {
                    return
                }
                
                // App 进入前台时，触发后台快照抓取
                Task {
                    await processPendingSnapshots()
                }
            }
        }
    }
    
    /// 处理待抓取快照的 AssetItem
    @MainActor
    private func processPendingSnapshots() async {
        // 延迟 2 秒，避免影响 App 启动性能
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 使用 do-catch 包装整个操作，防止任何未捕获的异常导致崩溃
        do {
            // 使用 async Realm 初始化
            let realm = try await Realm()
            
            // 查询所有待抓取且未超过最大重试次数的 item
            let itemsNeedingSnapshots = realm.objects(AssetItem.self)
                .filter(
                    "snapshotStatusRaw == %@ AND (imageUrl == nil OR imageUrl == '') AND snapshotAttemptCount < %d",
                    SnapshotStatus.pending.rawValue,
                    SnapshotRetryPolicy.maxAttempts
                )
            
            guard !itemsNeedingSnapshots.isEmpty else {
                return
            }
            
            print("StashApp: Found \(itemsNeedingSnapshots.count) items needing snapshots")
            
            // 关键修复：使用 Array() 立即物化 Results，避免懒加载导致的线程安全问题
            // freeze() 创建一个不可变的快照，可以安全地跨线程使用
            let frozenItems = itemsNeedingSnapshots.freeze()
            let itemsToProcess: [(id: UUID, url: String)] = Array(frozenItems).map { (id: $0.id, url: $0.url) }
            
            // 串行处理每个 item
            for itemInfo in itemsToProcess {
                let itemId = itemInfo.id
                let itemUrl = itemInfo.url
                var attemptCount = 0
                
                // 先持久化本次尝试，防止重复无限重试
                do {
                    let attemptRealm = try await Realm()
                    if let item = attemptRealm.object(ofType: AssetItem.self, forPrimaryKey: itemId) {
                        try attemptRealm.write {
                            item.snapshotAttemptCount += 1
                            item.snapshotLastAttemptAt = Date()
                            item.snapshotLastError = nil
                            attemptCount = item.snapshotAttemptCount
                        }
                    }
                } catch {
                    print("StashApp: Failed to record snapshot attempt for \(itemId) - \(error)")
                }
                
                // 调用快照服务
                let imagePath = await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
                    AppServices.shared.snapshot.capture(urlString: itemUrl) { path in
                        continuation.resume(returning: path)
                    }
                }
                
                if let imagePath = imagePath {
                    // 更新数据库 - 需要新的 Realm 实例
                    do {
                        let updateRealm = try await Realm()
                        if let itemToUpdate = updateRealm.object(ofType: AssetItem.self, forPrimaryKey: itemId) {
                            try updateRealm.write {
                                itemToUpdate.imageUrl = imagePath
                                itemToUpdate.snapshotStatusRaw = SnapshotRetryPolicy.nextStatus(after: .success, attemptCount: attemptCount).rawValue
                                itemToUpdate.snapshotLastError = SnapshotRetryPolicy.message(for: .success, attemptCount: attemptCount)
                            }
                            print("StashApp: Updated snapshot for item: \(itemId)")
                        }
                    } catch {
                        print("StashApp: Failed to update item \(itemId) - \(error)")
                    }
                } else {
                    do {
                        let updateRealm = try await Realm()
                        if let itemToUpdate = updateRealm.object(ofType: AssetItem.self, forPrimaryKey: itemId) {
                            try updateRealm.write {
                                itemToUpdate.snapshotStatusRaw = SnapshotRetryPolicy.nextStatus(after: .timeout, attemptCount: attemptCount).rawValue
                                itemToUpdate.snapshotLastError = SnapshotRetryPolicy.message(for: .timeout, attemptCount: attemptCount)
                            }
                        }
                    } catch {
                        print("StashApp: Failed to persist snapshot failure for \(itemId) - \(error)")
                    }
                    print("StashApp: Failed to capture snapshot for: \(itemUrl)")
                }
                
                // 每个请求之间间隔 0.5 秒，避免过于频繁
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            
            print("StashApp: Finished processing pending snapshots")
        } catch {
            print("StashApp: Error in processPendingSnapshots - \(error)")
        }
    }
}
