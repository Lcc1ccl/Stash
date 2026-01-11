# Change: 修复卡片交互与缩略图抓取问题

## Why

当前存在两个影响用户体验的问题：
1. **卡片左滑手势冲突**：左滑操作与页面垂直滚动及 NavigationLink 点击存在冲突，导致误触进入详情页或干扰页面滚动。
2. **缩略图抓取失败**：部分网页（尤其是移动端页面）无法正确抓取 `og:image`，导致卡片显示 emoji 而非网页图片。

## What Changes

### 卡片交互优化

1. **手势冲突修复**：调整 `DragGesture` 和 `NavigationLink` 的手势识别策略
   - 增加水平滑动触发阈值（需要明确的水平意图才触发左滑）
   - 使用 `simultaneousGesture` 或手势状态管理避免与垂直滚动冲突
   - 在用户正在拖动时禁用 NavigationLink 的响应

### 缩略图抓取增强

2. **异步快照抓取机制**：当网页没有可用的 `og:image` 时，在后台异步使用 WebView 渲染并截图
   - 保存时立即完成（使用 emoji 占位），用户无感知
   - 主 App 启动或进入前台时，后台检查没有图片的 AssetItem
   - 使用 `WKWebView` 在本地渲染网页并截取快照
   - 截图完成后更新 `imageUrl` 字段，UI 自动刷新

## Impact

- **Affected specs**: `card-interaction`（新增）, `thumbnail-capture`（新增）
- **Affected code**:
  - `ContentView.swift` - `SwipeableAssetCard` 组件手势处理
  - `ShareExtension/ShareViewController.swift` - 图片抓取逻辑
  - 新增 `WebSnapshotService.swift` - WebView 快照服务
  - `StashApp.swift` - 后台任务触发

## Out of Scope

- 云端图片存储或 CDN 加速
- 用户手动截图功能
- 深度定制的手势交互（如右滑、多级滑动）
