## ADDED Requirements

### Requirement: 网页缩略图获取优先级

系统在保存网页链接时 SHALL 按以下优先级获取缩略图：
1. iOS 系统传递的附件图片（来自 Share Sheet）
2. 网页 HTML 中的 `og:image` 或 `twitter:image` 元标签
3. 后台异步 WebView 快照（当前两项均不可用时）

#### Scenario: 使用系统附件图片

- **GIVEN** 用户从 Safari 分享一个链接到 Stash
- **WHEN** iOS 系统传递了附带的缩略图附件
- **THEN** 系统优先使用该附件图片作为卡片缩略图

#### Scenario: 使用 og:image 元标签

- **GIVEN** 用户分享的链接没有系统附件图片
- **WHEN** 网页 HTML 包含有效的 `og:image` 或 `twitter:image` 元标签
- **THEN** 系统使用该元标签指向的图片 URL 作为缩略图

#### Scenario: 回退到 emoji 占位

- **GIVEN** 分享的链接既没有系统附件，也没有有效的 og:image
- **WHEN** 用户完成保存操作
- **THEN** 卡片暂时显示 emoji 占位图，链接被标记为待后台抓取快照

### Requirement: 后台异步快照抓取

当保存的链接缺少缩略图时，系统 SHALL 在主 App 进入前台时自动尝试为其抓取网页快照。

#### Scenario: App 进入前台触发快照任务

- **GIVEN** 存在一条或多条 imageUrl 为空的 AssetItem
- **WHEN** App 从后台进入前台
- **THEN** 系统在后台队列中依次加载这些链接的网页，并截取快照

#### Scenario: 快照成功更新缩略图

- **GIVEN** 后台快照任务正在处理某个 AssetItem
- **WHEN** WebView 成功加载网页并截取快照
- **THEN** 快照图片保存到 App Group 目录，AssetItem 的 imageUrl 更新为本地路径，UI 自动刷新显示缩略图

#### Scenario: 快照失败保留 emoji

- **GIVEN** 后台快照任务正在处理某个 AssetItem
- **WHEN** 网页加载失败或超时（超过 10 秒）
- **THEN** AssetItem 保持 emoji 显示，不再重复尝试该链接的快照抓取
