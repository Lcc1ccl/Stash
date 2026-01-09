# Settings Capability Spec

## Overview
提供应用内设置入口，管理用户偏好和应用配置。

---

## ADDED Requirements

### Requirement: Settings Entry Point
首页右上角按钮 SHALL 作为设置功能入口。

#### Scenario: User opens settings
- **Given** 用户在首页
- **When** 点击右上角设置按钮
- **Then** 展示设置页面 Sheet

---

### Requirement: Settings Structure
设置页面 SHALL 按功能分组展示。

#### Scenario: Settings page layout
- **Given** 用户打开设置页面
- **Then** 页面包含以下分组：账号、订阅与积分、AI 设置、通用设置、关于

---

### Requirement: Basic Settings
应用 SHALL 提供基础设置项。

#### Scenario: Toggle notifications
- **Given** 用户在设置页通用设置区
- **When** 切换通知开关
- **Then** 通知权限状态更新

#### Scenario: Clear cache
- **Given** 用户在设置页通用设置区
- **When** 点击清除缓存
- **Then** 应用缓存被清除
