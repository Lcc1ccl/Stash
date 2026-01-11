# Tasks: 卡片交互与缩略图抓取优化

## 1. 卡片手势交互修复

- [x] 1.1 修改 `SwipeableAssetCard` 组件，添加拖动状态追踪（`isDragging`）
- [x] 1.2 调整 `DragGesture` 逻辑，增加水平滑动意图检测（水平位移 > 垂直位移 × 2）
- [x] 1.3 将 `NavigationLink` 改为手动导航控制（使用 `NavigationLink(isActive:)` 或 `navigationDestination`）
- [x] 1.4 确保在拖动状态下不触发点击导航
- [x] 1.5 测试验证：垂直滚动、左滑操作、点击进入详情三者互不干扰（构建成功，待手动测试）

## 2. 异步快照抓取服务

- [x] 2.1 创建 `WebSnapshotService.swift`，封装 WKWebView 快照逻辑
- [x] 2.2 实现 `captureSnapshot(url:completion:)` 方法，加载网页并截图
- [x] 2.3 添加超时控制（10 秒），超时返回 nil
- [x] 2.4 实现图片保存逻辑（复用 App Group 图片存储路径）

## 3. 后台任务触发

- [x] 3.1 在 `StashApp.swift` 中监听 `scenePhase` 变化，App 进入前台时触发检查
- [x] 3.2 查询所有 `imageUrl == nil` 的 AssetItem
- [x] 3.3 串行处理待抓取列表，调用 `WebSnapshotService` 获取快照
- [x] 3.4 更新 AssetItem 的 `imageUrl` 字段

## 4. 验证与测试

- [ ] 4.1 验证手势问题：垂直滚动不误触发左滑
- [ ] 4.2 验证手势问题：左滑操作不触发详情页跳转
- [ ] 4.3 验证快照抓取：保存无 og:image 的链接后，重启 App 能自动补充缩略图
- [ ] 4.4 验证快照抓取：已有图片的 item 不会被重复处理

