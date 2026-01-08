# Authentication Capability Spec

## Overview
提供本地优先的用户账号体系，支持邮箱登录和第三方绑定。

---

## ADDED Requirements

### Requirement: Email Authentication
用户 SHALL 可使用邮箱注册和登录。

#### Scenario: Register with email
- **Given** 用户未登录
- **When** 输入邮箱和密码并提交注册
- **Then** 创建本地用户账号并自动登录

#### Scenario: Login with email
- **Given** 用户已注册但未登录
- **When** 输入正确的邮箱和密码
- **Then** 登录成功并显示用户信息

#### Scenario: Login failed
- **Given** 用户输入错误密码
- **When** 提交登录
- **Then** 显示错误提示

---

### Requirement: Third-party Login Binding
应用 SHALL 提供 Apple 和 Google 账号绑定选项（UI 占位）。

#### Scenario: View binding options
- **Given** 用户已登录
- **When** 查看账号设置
- **Then** 显示 Apple 和 Google 绑定选项

---

### Requirement: Logout
用户 SHALL 可登出当前账号。

#### Scenario: User logs out
- **Given** 用户已登录
- **When** 点击登出按钮
- **Then** 清除登录状态并返回未登录界面
