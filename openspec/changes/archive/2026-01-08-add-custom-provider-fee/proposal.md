# Change: 自定义 AI 提供方启用费用

## Why
当前用户可以无限制地切换到自定义 AI 提供方（OpenAI/Anthropic），绕过积分消耗机制。为平衡免费用户与付费功能，需要对启用自定义提供方设置一次性费用门槛。

## What Changes
- 用户首次保存自定义 AI 提供方配置时，需消耗 10 积分
- 单账号仅扣除一次，后续可自由切换
- 若积分不足，提示无法保存并阻止操作

## Impact
- **Affected specs**: subscription（AI Provider Selection 需求修改）
- **Affected code**: 
  - `Stash/Shared/AIProviderConfig.swift` - 增加已解锁标记字段
  - `Stash/SettingsView.swift` - 保存时检查积分并触发扣除逻辑
  - `Stash/Shared/CreditsManager.swift` - 新增解锁状态管理
