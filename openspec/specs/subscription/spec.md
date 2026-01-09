# subscription Specification

## Purpose
TBD - created by archiving change add-settings. Update Purpose after archive.
## Requirements
### Requirement: Subscription Plans
应用 SHALL 提供三档订阅方案：FREE、PLUS、PRO。

#### Scenario: View subscription plans
- **Given** 用户打开订阅页面
- **Then** 显示三档方案及其每日积分额度：
  - FREE: 10 积分/日
  - PLUS: 50 积分/日
  - PRO: 200 积分/日

#### Scenario: Select subscription plan
- **Given** 用户查看订阅方案
- **When** 选择一个方案
- **Then** 订阅状态更新（模拟，不涉及真实支付）

---

### Requirement: Credits System
积分系统 SHALL 用于 AI 功能消耗，每日刷新。

#### Scenario: Daily credits refresh
- **Given** 用户打开应用且距上次刷新已过 24 小时
- **Then** 积分重置为当前方案的每日额度

#### Scenario: Credits consumption
- **Given** 用户使用 AI 功能
- **When** 调用成功
- **Then** 扣减相应积分

#### Scenario: Insufficient credits
- **Given** 用户积分余额不足
- **When** 尝试使用 AI 功能
- **Then** 提示积分不足并建议升级

---

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

