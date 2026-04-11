# Research: 剪贴板条目详情页 (Entry Detail Page)

**Branch**: `002-entry-detail-page` | **Date**: 2026-04-08

## Research Tasks

### R-001: Navigation approach for DetailPage

**Decision**: Use HarmonyOS `Navigation` component with `NavDestination` for page-stack navigation. Wrap the existing Tabs layout inside a `Navigation` component in Index.ets. DetailPage becomes a `NavDestination` that is pushed onto the nav stack when an item is clicked.

**Rationale**:
- The spec requires DetailPage as an independent page (not a dialog).
- Constitution V (UX Consistency) mandates `Navigation` component with unified nav router.
- The existing codebase already uses `@Component struct DetailPage` which can be wrapped in `NavDestination`.
- `Navigation` provides built-in back-button handling and page transition animations.

**Alternatives considered**:
- `router.pushUrl()`: Constitution explicitly discourages this except for deep links. Does not provide shared state across pages.
- `@CustomDialog`: Spec says detail page should be a full page, not a dialog. Would not support text editing UX well.
- Sheet/modal: Limited screen real estate, poor UX for text editing.

### R-002: Text editing approach

**Decision**: Use ArkUI `TextArea` component for text editing. Track dirty state by comparing current text against `decryptedContent`. Save button triggers re-encryption and repository update.

**Rationale**:
- `TextArea` supports multi-line text editing with scrolling (spec edge case: long text).
- `TextInput` is single-line only — unsuitable for multi-line content.
- Dirty tracking is straightforward: compare `editedText !== decryptedContent`.
- Save triggers: explicit save button (no auto-save per spec FR-004).

**Alternatives considered**:
- `RichEditor`: Supports rich text but spec explicitly says "纯文本编辑，不支持富文本格式".
- Auto-save with debounce: Spec requires explicit save action (FR-004 "用户必须能保存修改").

### R-003: Content update with re-encryption

**Decision**: Add `updateContent(id, newContent)` to ClipboardRepository → ClipboardRepositoryImpl → ClipboardDao. The repository layer handles: (1) hash the new content, (2) encrypt new content, (3) update DB row with new encrypted data + hash + preview + size + timestamp.

**Rationale**:
- Constitution VII requires encryption at rest — editing must re-encrypt.
- Existing `insert()` method shows the encryption pattern — follow the same approach for update.
- Content hash must be recalculated for deduplication integrity.
- `contentPreview` must be regenerated from new content.
- `updatedAt` timestamp must be set to current time.

**Alternatives considered**:
- Delete + re-insert: Would lose metadata (createdAt, isFavorite, isPinned, tags). Unacceptable.
- Update only encrypted fields: Correct approach — update only content-related columns.

### R-004: Unsaved changes detection and back navigation

**Decision**: Track `isDirty` flag in DetailViewModel. When user presses back with `isDirty === true`, show `AlertDialog.confirm` asking whether to discard changes. If confirmed, pop nav stack. If cancelled, stay on page.

**Rationale**:
- Spec FR-005 requires unsaved change confirmation.
- ArkUI `Navigation` provides `onBackPressed` callback that can return `true` to intercept back navigation.
- AlertDialog is the standard HarmonyOS confirmation pattern (used elsewhere in the app for clear-all, delete confirmations).

**Alternatives considered**:
- Custom dialog: Overkill for a simple yes/no confirmation.
- Toast warning: Too subtle for potential data loss.

### R-005: Integration with existing list pages

**Decision**: Modify `onItemClick` in both HistoryPage and FavoritesPage to navigate to DetailPage by pushing a `NavDestination` onto the Navigation stack. Pass `entryId` as parameter.

**Rationale**:
- Both pages already have `onItemClick` stubs with `console.info`.
- Navigation stack approach means back-button returns to the list with its state preserved.
- `AppContext.notifyDataChanged()` is already used after mutations — DetailPage will call this after save/delete so lists refresh.

**Alternatives considered**:
- Re-create page each time: Simpler but loses list scroll position. Navigation stack preserves it.
- Global state: No need — entryId is sufficient to load entry data.

### R-006: Image type handling (v1)

**Decision**: For image-type entries, display a placeholder area with "[Image]" text, show metadata (source app, content type, timestamp), and provide action buttons (copy, favorite, delete). No editing.

**Rationale**:
- Spec explicitly states: "图片内容暂时只显示占位符'[Image]'，未来版本支持真正图片预览".
- Spec assumption: "图片类型在 v1 仅显示占位信息和元信息，不提供编辑功能".

**Alternatives considered**:
- Full image preview: Out of scope per spec.
- Skip image types entirely: Would leave users confused when clicking image entries.

### R-007: Data consistency when entry deleted externally

**Decision**: When DetailPage loads and `repo.getById()` returns null, show an error state with message "该条目已被删除" and a back button. Use existing `EmptyState` component pattern.

**Rationale**:
- Spec edge case: "条目在详情页打开期间被外部删除".
- Simple and clear UX — inform user and let them go back.

**Alternatives considered**:
- Auto-navigate back: Abrupt, users may not understand what happened.
- Show cached data: Misleading — data doesn't exist anymore.

## Summary of All Decisions

| ID | Topic | Decision |
|----|-------|----------|
| R-001 | Navigation | Navigation + NavDestination page stack |
| R-002 | Text editing | TextArea with dirty tracking |
| R-003 | Content update | New updateContent() method through DAO → Repo → ViewModel |
| R-004 | Unsaved changes | isDirty flag + AlertDialog confirmation on back |
| R-005 | List integration | Push NavDestination from onItemClick in History/Favorites pages |
| R-006 | Image handling | Placeholder + metadata, no editing |
| R-007 | External deletion | Error state with message + back button |
