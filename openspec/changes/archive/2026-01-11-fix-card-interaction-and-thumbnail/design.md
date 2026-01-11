# Design: 卡片交互与缩略图抓取优化

## Context

### 卡片交互问题背景
- 当前 `SwipeableAssetCard` 将 `DragGesture` 附加在 `NavigationLink` 外层
- iOS 手势系统中，水平和垂直手势存在竞争，轻微的水平位移会触发左滑状态
- `NavigationLink` 在手势结束时可能被误触发

### 缩略图问题背景
- 部分网页（如澎湃新闻移动端 `m.thepaper.cn`）的 `og:image` 元数据可能：
  - 不存在于初始 HTML 中（需要 JavaScript 渲染）
  - 路径为相对路径或特殊格式
  - 被反爬策略屏蔽
- 当前 Share Extension 使用 `Data(contentsOf:)` 同步获取 HTML，无法执行 JavaScript

## Goals / Non-Goals

### Goals
- 修复左滑手势冲突，提供流畅的交互体验
- 当 `og:image` 不可用时，提供备选的网页快照方案
- 异步处理不阻塞用户的保存流程

### Non-Goals
- 完美还原所有网页的截图（某些网页可能有登录墙或反爬策略）
- 支持云端图片存储
- 修改数据模型

## Decision 1: 手势冲突解决方案

### 问题分析
当前代码结构：
```swift
NavigationLink(...) {
    AssetCardView(...)
}
.gesture(DragGesture()...)  // 与 NavigationLink 点击冲突
```

### 方案选择

| 方案 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A. 增加滑动阈值 + 手势状态管理 | 检测水平位移超过阈值时才激活左滑，同时使用 `@GestureState` 追踪拖动状态 | 保留原有交互模式，修改量小 | 需要仔细调参 |
| B. 禁用 NavigationLink，改用按钮导航 | 用 `Button` + `NavigationLink(isActive:)` 控制导航 | 完全控制何时触发导航 | 代码改动较大 |
| C. 使用 `simultaneousGesture` | 将拖动与点击设为并行手势 | SwiftUI 原生支持 | 仍可能有微妙冲突 |

**选择方案 A + B 结合**：
1. 使用 `@State` 追踪是否正在拖动（`isDragging`）
2. 使用 `Button` 替代 `NavigationLink` 作为点击触发器，仅在非拖动状态下触发导航
3. 增加水平滑动的最小位移阈值（建议 20-30pt），避免垂直滚动误触发

### 实现要点
```swift
struct SwipeableAssetCard: View {
    @State private var isDragging = false
    @State private var navigateToDetail = false
    
    // 只有明确的水平滑动（超过阈值）才算开始拖动
    .gesture(
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let horizontalMovement = abs(value.translation.width)
                let verticalMovement = abs(value.translation.height)
                // 水平位移大于垂直位移的2倍时，才认为是左滑意图
                if horizontalMovement > verticalMovement * 2 && value.translation.width < 0 {
                    isDragging = true
                    // 处理 offset...
                }
            }
            .onEnded { ... }
    )
    
    // 点击进入详情，但拖动时不触发
    .onTapGesture {
        if !isDragging && offset == 0 {
            navigateToDetail = true
        }
    }
}
```

## Decision 2: 异步快照抓取方案

### 方案设计

```
┌─────────────────────────────────────────────────────────────┐
│                    Share Extension                           │
│  1. 保存 URL → 尝试获取 og:image                              │
│  2. 如果有 og:image → 直接保存                                 │
│  3. 如果没有 → 保存 item（imageUrl = nil），标记待抓取           │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    （用户使用 App）
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Main App                                │
│  1. 进入前台时检查是否有 imageUrl 为空的 item                    │
│  2. 逐个使用 WKWebView 加载网页                                │
│  3. 等待页面加载完成后截图                                      │
│  4. 保存截图到 App Group 并更新 imageUrl                        │
└─────────────────────────────────────────────────────────────┘
```

### 技术细节

1. **WKWebView 快照**：使用 `WKWebView.takeSnapshot(with:completionHandler:)` API
2. **后台处理**：使用 `Task` 在后台串行处理，避免同时加载多个网页
3. **超时控制**：单个页面最多等待 10 秒，超时跳过
4. **重试策略**：失败的 item 标记 `snapshotAttempted = true`，避免重复尝试
5. **图片尺寸**：截取 375x200 区域（适合卡片展示），压缩为 JPEG

### 新增字段（可选优化，暂不纳入）
考虑到 KISS 原则，暂时通过判断 `imageUrl == nil` 来识别待抓取的 item，不新增数据模型字段。

## Risks / Trade-offs

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| WKWebView 需要在主线程创建 | 可能影响 App 启动性能 | 延迟 2 秒后开始处理，分批处理 |
| 部分网页无法正常加载 | 截图失败 | 设置超时，保留 emoji 兜底 |
| 手势阈值调参不当 | 交互仍有问题 | 提供合理默认值，后续可根据反馈调整 |

## Open Questions

- [ ] 是否需要在设置中提供"禁用自动快照"选项？ → 暂不实现，后续根据反馈决定
