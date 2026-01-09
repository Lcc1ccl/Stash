# Subscription Capability Spec

## Overview
提供订阅方案和积分系统，控制 AI 功能使用额度。

---

## ADDED Requirements

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
用户 SHALL 可选择默认 AI 或自定义 API。

#### Scenario: Use default AI
- **Given** 用户选择默认 AI 提供方
- **Then** 使用内置 API，消耗订阅积分

#### Scenario: Use custom API key
- **Given** 用户选择自定义提供方
- **When** 输入有效 API Key
- **Then** AI 调用使用用户 API Key，不消耗订阅积分
