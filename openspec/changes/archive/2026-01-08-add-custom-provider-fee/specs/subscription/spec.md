## MODIFIED Requirements

### Requirement: AI Provider Selection
用户 SHALL 可选择默认 AI 或自定义 API，首次启用自定义提供方需消耗 10 积分。

#### Scenario: Use default AI
- **Given** 用户选择默认 AI 提供方
- **Then** 使用内置 API，消耗订阅积分

#### Scenario: Use custom API key (first time)
- **Given** 用户选择自定义提供方
- **And** 该账号从未解锁过自定义提供方
- **When** 输入有效 API Key 并尝试保存
- **Then** 系统提示将扣除 10 积分以解锁
- **When** 用户确认
- **Then** 扣除 10 积分，保存配置，标记账号已解锁

#### Scenario: Use custom API key (already unlocked)
- **Given** 用户选择自定义提供方
- **And** 该账号已解锁过自定义提供方
- **When** 输入有效 API Key 并保存
- **Then** AI 调用使用用户 API Key，不消耗订阅积分

#### Scenario: Insufficient credits for unlock
- **Given** 用户选择自定义提供方
- **And** 该账号从未解锁过自定义提供方
- **And** 用户积分余额不足 10 积分
- **When** 尝试保存配置
- **Then** 提示积分不足，阻止保存操作
