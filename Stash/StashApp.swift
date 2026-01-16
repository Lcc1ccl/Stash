//
//  StashApp.swift
//  Stash
//
//  Created by 超爹 on 2026/1/5.
//

import SwiftUI
import RealmSwift

/// 启动阶段可能发生的错误
enum StartupError: LocalizedError {
    case appGroupUnavailable
    case realmInitFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "无法访问共享存储空间。请尝试重新安装 App。"
        case .realmInitFailed(let error):
            return "数据库初始化失败: \(error.localizedDescription)"
        }
    }
}

@main
struct StashApp: SwiftUI.App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var startupError: StartupError?
    
    init() {
        configureRealm()
        
        // 预热关键单例（确保在主线程初始化）
        _ = AuthManager.shared
        _ = CreditsManager.shared
    }
    
    /// 配置 Realm 数据库
    private func configureRealm() {
        let appGroupId = "group.com.chaosky.Stash"
        
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("StashApp: ERROR - Shared App Group container not found")
            // 不调用 fatalError，而是设置错误状态
            // 注意：在 init() 中无法直接设置 @State，需要在 body 中处理
            // 这里先设置默认配置，让 App 能够启动
            let fallbackURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("fallback.realm")
            let config = Realm.Configuration(
                fileURL: fallbackURL,
                schemaVersion: 5,
                migrationBlock: realmMigrationBlock
            )
            Realm.Configuration.defaultConfiguration = config
            return
        }
        
        let realmURL = container.appendingPathComponent("default.realm")
        let config = Realm.Configuration(
            fileURL: realmURL,
            schemaVersion: 5,
            migrationBlock: realmMigrationBlock
        )
        Realm.Configuration.defaultConfiguration = config
        
        print("StashApp: Realm configured at \(realmURL.path)")
    }
    
    /// Realm 迁移逻辑
    private var realmMigrationBlock: MigrationBlock {
        return { migration, oldSchemaVersion in
            print("StashApp: Migrating Realm from schema version \(oldSchemaVersion) to 5")
            // 目前不需要特殊迁移逻辑
            // Realm 会自动处理简单的 schema 变更（添加/删除属性）
            // 如果未来需要复杂迁移，在这里添加
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // App 进入前台时，触发后台快照抓取
                        Task {
                            await processPendingSnapshots()
                        }
                    }
                }
        }
    }
    
    /// 处理待抓取快照的 AssetItem
    @MainActor
    private func processPendingSnapshots() async {
        // 延迟 2 秒，避免影响 App 启动性能
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 使用 async Realm 初始化
        let realm: Realm
        do {
            realm = try await Realm()
        } catch {
            print("StashApp: Failed to open Realm for snapshot processing - \(error)")
            return
        }
        
        // 查询所有 imageUrl 为空的 item
        let itemsNeedingSnapshots = realm.objects(AssetItem.self)
            .filter("imageUrl == nil OR imageUrl == ''")
        
        guard !itemsNeedingSnapshots.isEmpty else {
            return
        }
        
        print("StashApp: Found \(itemsNeedingSnapshots.count) items needing snapshots")
        
        // 复制需要处理的 item 信息，避免迭代过程中 Results 变化
        let itemsToProcess = itemsNeedingSnapshots.map { (id: $0.id, url: $0.url) }
        
        // 串行处理每个 item
        for itemInfo in itemsToProcess {
            let itemId = itemInfo.id
            let itemUrl = itemInfo.url
            
            // 调用快照服务
            let imagePath = await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
                WebSnapshotService.shared.captureSnapshot(for: itemUrl) { path in
                    continuation.resume(returning: path)
                }
            }
            
            if let imagePath = imagePath {
                // 更新数据库
                do {
                    let updateRealm = try await Realm()
                    if let itemToUpdate = updateRealm.object(ofType: AssetItem.self, forPrimaryKey: itemId) {
                        try updateRealm.write {
                            itemToUpdate.imageUrl = imagePath
                        }
                        print("StashApp: Updated snapshot for item: \(itemId)")
                    }
                } catch {
                    print("StashApp: Failed to update item \(itemId) - \(error)")
                }
            } else {
                print("StashApp: Failed to capture snapshot for: \(itemUrl)")
            }
            
            // 每个请求之间间隔 0.5 秒，避免过于频繁
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        print("StashApp: Finished processing pending snapshots")
    }
}
