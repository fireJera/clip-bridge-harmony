# clip-bridge-harmony Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-05

## Active Technologies

- ArkTS (HarmonyOS NEXT SDK API 12+) + ArkUI, @ohos.pasteboard, @ohos.data.relationalStore, (001-clipboard-sync-app)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for ArkTS (HarmonyOS NEXT SDK API 12+)

## Code Style

ArkTS (HarmonyOS NEXT SDK API 12+): Follow standard conventions

## Recent Changes

- 001-clipboard-sync-app: Added ArkTS (HarmonyOS NEXT SDK API 12+) + ArkUI, @ohos.pasteboard, @ohos.data.relationalStore,

<!-- MANUAL ADDITIONS START -->

## 重要规则：数据变更后必须通知刷新

本项目使用 `AppContext.notifyDataChanged()` 做跨页面数据刷新。**任何修改数据库数据（增、删、改、关联、取消关联）的操作完成后，都必须调用 `AppContext.notifyDataChanged()`**，否则其他页面不会刷新。

已踩过的坑：
- DetailPage 保存/删除/置顶后忘记调用
- FavoritesPage 左划移除收藏夹后忘记调用
- 任何 ViewModel/Repository 的写操作（addTag、removeTag、updatePin、deleteEntry 等）所在页面都必须在操作完成后通知

检查清单：每写完一个数据操作 handler，确认最后有 `AppContext.notifyDataChanged()`。

## ForEach key 必须包含可变字段

ArkUI 的 `ForEach` 通过 key 决定是否复用组件。key 不变则不重新渲染，即使数据已更新。**ForEach 的 key 生成函数必须包含所有需要在 UI 上反映的字段**（如 `entryCount`、`isPinned`、`updatedAt` 等）。

<!-- MANUAL ADDITIONS END -->
