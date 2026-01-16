# Change: 修复 App 启动崩溃问题

## Why

TestFlight 发布后，用户反馈 App 启动后几秒钟自动闪退，崩溃率极高。经代码审查，发现多处致命的启动阶段崩溃风险。

## 问题根源分析

### 1. **`fatalError` 导致启动崩溃** [严重性: 致命]

在 `StashApp.swift` 和 `StorageManager.swift` 中，当 App Group 容器无法获取时，代码调用 `fatalError`:

```swift
// StashApp.swift:18-19
guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
    fatalError("Shared App Group container not found. Check Entitlements.")
}

// StorageManager.swift:11-12
guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
    fatalError("Shared App Group container not found. Check Entitlements.")
}
```

**风险分析**: 
- 如果 App Group entitlement 在真实设备上未正确配置（开发/生产 provisioning profile 不一致）
- 或用户设备存储空间紧张导致容器创建失败
- 将立即触发 `fatalError` 崩溃

### 2. **强制解包 URL** [严重性: 高]

```swift
// SupabaseConfig.swift:6
static let url = URL(string: "https://aikwrkcamqqzwlceyppu.supabase.co")!
```

虽然这个 URL 是硬编码的合法字符串，但强制解包（`!`）是不好的实践。如果 Supabase SDK 在初始化时有任何问题，可能导致连锁崩溃。

### 3. **全局单例初始化链** [严重性: 高]

```swift
// SupabaseConfig.swift:11-14
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)
```

这是一个**全局常量**，在 App 启动时立即初始化。如果 SupabaseClient 初始化过程中有任何网络或配置问题，将导致 App 无法启动。

### 4. **单例 `@MainActor` 初始化冲突** [严重性: 中]

`AuthManager.shared` 和 `CreditsManager.shared` 使用 `@MainActor` 标注：

```swift
// AuthManager.swift:6-8
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
```

如果在非主线程首次访问这些单例（例如后台任务中），可能导致运行时警告或潜在死锁。

### 5. **Realm Schema 迁移问题** [严重性: 高]

```swift
// StashApp.swift:22
let config = Realm.Configuration(fileURL: realmURL, schemaVersion: 5)
```

如果用户设备上存在旧版本 Realm 数据库，而 `schemaVersion: 5` 需要迁移逻辑但未提供 `migrationBlock`，将导致 Realm 打开失败并可能崩溃。

## What Changes

### 核心修复

- [ ] **移除所有 `fatalError` 调用**，改为优雅降级或错误处理
- [ ] **添加 Realm 迁移逻辑**，处理版本升级场景
- [ ] **将全局 Supabase 客户端改为懒加载**，避免启动时阻塞
- [ ] **添加 App 启动健康检查**，在关键路径失败时显示用户友好的错误界面

### 架构改进

- [ ] 使用 `Result` 类型或 `Optional` 替代强制崩溃逻辑
- [ ] 添加错误边界（Error Boundary）机制
- [ ] 记录启动阶段的关键日志用于调试

## Impact

- **受影响规范**: stability (新规范)
- **受影响代码**:
  - `Stash/StashApp.swift`
  - `Stash/Shared/StorageManager.swift`
  - `Stash/Shared/SupabaseConfig.swift`
  - `Stash/Shared/AuthManager.swift`
  - `Stash/Shared/CreditsManager.swift`

## 风险评估

| 修复项 | 影响范围 | 回归风险 |
|--------|---------|---------|
| 移除 fatalError | 核心启动流程 | 低 |
| Realm 迁移 | 数据持久化 | 中（需测试迁移路径）|
| Supabase 懒加载 | 认证/积分功能 | 低 |
| 错误边界 | 全局 UI | 低 |
