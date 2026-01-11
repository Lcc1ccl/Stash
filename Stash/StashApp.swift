//
//  StashApp.swift
//  Stash
//
//  Created by 超爹 on 2026/1/5.
//

import SwiftUI
import RealmSwift

@main
struct StashApp: SwiftUI.App {
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Configure Realm to use the shared App Group container
        let appGroupId = "group.com.chaosky.Stash"
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("Shared App Group container not found. Check Entitlements.")
        }
        let realmURL = container.appendingPathComponent("default.realm")
        let config = Realm.Configuration(fileURL: realmURL, schemaVersion: 5)
        Realm.Configuration.defaultConfiguration = config
        
        // Supabase is initialized via global client in SupabaseConfig.swift
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
