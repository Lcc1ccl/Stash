# Tasks for add-settings

## 实施任务

1. **数据模型层**
   - [ ] 创建 `UserProfile.swift` 用户模型
   - [ ] 创建 `SubscriptionInfo.swift` 订阅积分模型
   - [ ] 创建 `AIProviderConfig.swift` AI配置模型

2. **服务管理层**
   - [ ] 创建 `AuthManager.swift` 认证管理器
   - [ ] 创建 `CreditsManager.swift` 积分管理器
   - [ ] 修改 `OpenAIClient.swift` 支持动态配置

3. **视图层**
   - [ ] 创建 `SettingsView.swift` 设置主视图
   - [ ] 创建 `LoginView.swift` 登录视图
   - [ ] 创建 `SubscriptionView.swift` 订阅视图
   - [ ] 修改 `ContentView.swift` 替换入口按钮

4. **集成与验证**
   - [ ] 修改 `StashApp.swift` 初始化管理器
   - [ ] Xcode 构建测试
   - [ ] 功能验收测试

## 依赖关系
- 模型层 → 服务层 → 视图层（顺序依赖）
- 视图层各文件可并行开发
