# Fix Thumbnail Capture in Share Extension

## Why

当用户从 Safari 或其他 App 分享链接到 Stash 时，iOS 系统会传递缩略图作为附件。但当前的 Share Extension 代码只从 HTML 中提取 `og:image`，没有处理系统传递的图片附件，导致缩略图丢失。

## What Changes

### 问题分析
1. **当前行为**: Share Extension 只提取 `UTType.url`，忽略了 `UTType.image` 附件
2. **期望行为**: 优先使用系统传递的图片附件，若无则回退到 og:image 提取

### 解决方案
修改 `ShareViewController.swift` 的 `extractURL()` 方法，同时提取：
- URL 附件
- Image 附件（如果有）

### 图片存储策略
由于 `imageUrl` 字段期望的是 URL 字符串，而附件是 Data，需要：
1. 将图片 Data 保存到 App Group 共享目录
2. 存储本地文件路径到 `imageUrl` 字段
3. 在 `AssetCardView` 中支持加载本地图片路径

## Out of Scope
- 图片压缩优化
- 云端图片存储
