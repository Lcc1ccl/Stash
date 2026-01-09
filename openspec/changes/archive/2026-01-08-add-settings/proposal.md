# Add Settings Module

## Summary
将首页右上角按钮从【周回顾】入口替换为【设置】入口，并实现完整的设置功能体系，包含：
- 账号登录体系（邮箱为主，Apple/Google 绑定预留）
- 订阅积分系统（FREE/PLUS/PRO 三档方案）
- AI 提供方切换（默认/自定义 API）
- 基础设置项（通知、外观、缓存、关于）

## Motivation
当前右上角按钮打开周回顾功能，但设置入口是用户高频需求。需要提供统一的设置入口管理账号、订阅和 AI 配置。

## Scope
- **In Scope**: 设置主视图、账号模型与登录UI、订阅积分模型与UI、AI提供方切换、基础设置项
- **Out of Scope**: 真实支付集成、后端认证服务、Apple/Google OAuth 完整实现

## Status
PROPOSED
