# Tasks: add-custom-provider-fee

## 1. 数据模型更新
- [x] 1.1 在 Supabase `subscriptions` 表中添加 `custom_provider_unlocked` 布尔字段
- [x] 1.2 更新 `SubscriptionRecord` 模型增加 `customProviderUnlocked` 属性
- [x] 1.3 在 `CreditsManager` 中增加 `customProviderUnlocked` 状态管理

## 2. 业务逻辑实现
- [x] 2.1 在 `CreditsManager` 中添加 `unlockCustomProvider()` 方法，处理积分扣除和状态更新
- [x] 2.2 在 `CreditsManager` 中添加 `canUseCustomProvider()` 方法

## 3. UI 交互更新
- [x] 3.1 修改 `AIProviderSettingsView` 保存逻辑，检查是否需要扣除积分
- [x] 3.2 添加积分不足提示弹窗
- [x] 3.3 添加首次解锁确认弹窗（告知用户将扣除 10 积分）

## 4. 验证
- [x] 4.1 构建验证通过
- [ ] 4.2 测试首次切换到自定义提供方时触发积分扣除
- [ ] 4.3 测试积分不足时阻止保存
- [ ] 4.4 测试已解锁后再次切换不重复扣费

---

**注意**: Supabase 数据库需要手动添加 `custom_provider_unlocked` 字段：

```sql
ALTER TABLE subscriptions 
ADD COLUMN custom_provider_unlocked BOOLEAN DEFAULT FALSE;
```
