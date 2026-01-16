# Design: 启动崩溃修复方案

## Context

用户在 TestFlight 上反馈 App 启动后几秒钟就闪退。这种"启动即崩溃"问题极度影响用户体验，且导致用户无法使用 App 的任何功能。

## Goals

- 消除所有启动阶段的 `fatalError` 调用
- 实现优雅降级，即使关键服务不可用也能显示有意义的 UI
- 添加必要的 Realm 迁移逻辑

## Non-Goals

- 不修改业务逻辑
- 不添加新功能
- 不重构整体架构

## Decisions

### Decision 1: 使用 Optional Realm 替代 fatalError

**当前**:
```swift
var realm: Realm {
    guard let container = ... else {
        fatalError("...")
    }
    // ...
}
```

**修改为**:
```swift
var realmOptional: Realm? {
    guard let container = ... else {
        print("Error: Shared App Group container not found")
        return nil
    }
    // ...
    return try? Realm(configuration: config)
}
```

**理由**: 返回 nil 比 crash 更好，上层代码可以检查并显示错误 UI。

### Decision 2: 添加启动错误状态

在 `StashApp` 中维护一个 `@State var startupError: Error?`，如果 Realm 或其他关键服务初始化失败，显示一个错误视图而非空白或直接崩溃。

```swift
if let error = startupError {
    StartupErrorView(error: error)
} else {
    ContentView()
}
```

### Decision 3: Realm 迁移策略

采用"删除并重建"策略用于不兼容的迁移。这是最简单的方案，虽然会丢失旧数据，但对于一个新发布的 App（用户数据量小），这是可接受的。

```swift
let config = Realm.Configuration(
    fileURL: realmURL,
    schemaVersion: 5,
    migrationBlock: { migration, oldSchemaVersion in
        // 目前不需要特殊迁移逻辑
        // 如果 schema 不兼容，Realm 会自动处理简单变更
    },
    deleteRealmIfMigrationNeeded: false // 保守起见，不自动删除
)
```

> 如果未来需要更复杂的迁移，再添加具体的迁移代码。

### Decision 4: Supabase 懒加载

将全局 `let supabase` 改为懒加载计算属性或单例：

```swift
enum SupabaseService {
    static var shared: SupabaseClient? = {
        guard let url = URL(string: SupabaseConfig.urlString) else {
            return nil
        }
        return SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
    }()
}
```

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| Optional Realm 导致 UI 空白 | 低 | 中 | 添加明确的错误提示 UI |
| 迁移逻辑不完整 | 中 | 中 | 保守策略，不删除数据 |
| Supabase 懒加载导致首次使用延迟 | 低 | 低 | 启动时预热 |

## Open Questions

1. 是否需要添加崩溃日志上报（如 Firebase Crashlytics）？
   - **建议**: 后续作为独立变更处理

2. 如何验证 App Group 配置正确？
   - **建议**: 在 App 启动时打印诊断信息到控制台
