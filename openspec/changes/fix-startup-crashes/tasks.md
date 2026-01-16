# Tasks: 修复 App 启动崩溃问题

## 1. 消除 fatalError 崩溃点

- [x] 1.1 修改 `StashApp.swift`：将 App Group 容器获取失败改为显示错误界面而非崩溃
- [x] 1.2 修改 `StorageManager.swift`：将 `realm` 属性改为返回 `Optional` 或 `Result` 类型
- [x] 1.3 在 `ContentView` 中添加错误状态处理，当 Realm 不可用时显示友好提示

## 2. 添加 Realm 迁移支持

- [x] 2.1 在 Realm Configuration 中添加 `migrationBlock` 处理 schema 变更
- [x] 2.2 添加迁移日志以便调试

## 3. Supabase 客户端安全初始化

- [x] 3.1 将全局 `supabase` 常量改为懒加载单例模式
- [x] 3.2 添加 Supabase 初始化失败的优雅处理

## 4. 单例访问安全

- [x] 4.1 确保 `AuthManager.shared` 和 `CreditsManager.shared` 在主线程首次初始化
- [x] 4.2 在 `StashApp.init()` 中预热关键单例

## 5. 验证

- [x] 5.1 在模拟器上验证 App 正常启动
- [ ] 5.2 模拟 App Group 不可用场景，验证不崩溃
- [ ] 5.3 创建新的 TestFlight 构建并验证稳定性
