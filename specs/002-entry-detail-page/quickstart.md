# Quickstart: Entry Detail Page Implementation

**Branch**: `002-entry-detail-page` | **Date**: 2026-04-08

## Prerequisites

- HarmonyOS NEXT SDK API 12+ (DevEco Studio)
- Existing codebase with Phase 7 complete (clipboard history, favorites, settings, categories)

## What's Being Built

A detail page accessible from History and Favorites lists that allows:
1. **Viewing** full clipboard entry content (text, URL, email, phone, address, image)
2. **Editing** text-type entries inline with save/discard flows
3. **Managing** entries (favorite, pin, delete, copy, tag)

## Implementation Order

### Step 1: Data Layer (DAO + Repository)
1. Add `updateContent()` to `ClipboardDao.ets`
2. Add `updateContent()` to `IClipboardRepository` interface
3. Implement `updateContent()` in `ClipboardRepositoryImpl.ets` (re-encryption)

### Step 2: ViewModel (DetailViewModel.ets)
1. Add `editedContent`, `isDirty`, `isSaving`, `isNotFound` state
2. Add `saveContent()` — calls repo.updateContent(), refreshes state, notifies
3. Add `revertContent()` — resets editor to saved content
4. Add `isEntryDirty()` — compares edited vs saved content
5. Add `onContentEdited(newText)` — updates editedContent and isDirty
6. Modify `loadEntry()` — handle null return (isNotFound = true)

### Step 3: Navigation (Index.ets)
1. Wrap Tabs in `Navigation` component
2. Register DetailPage as `NavDestination`
3. Provide nav path stack to child components

### Step 4: List Page Integration
1. Modify `HistoryPage.onItemClick()` — push DetailPage onto nav stack with entryId
2. Modify `FavoritesPage.onItemClick()` — push DetailPage onto nav stack with entryId

### Step 5: Detail Page UI (DetailPage.ets)
1. Replace content `Text` with `TextArea` for text-type entries (editable)
2. Add save button in bottom bar when dirty
3. Add delete button with confirmation dialog
4. Add back navigation with unsaved changes detection
5. Handle isNotFound state
6. Handle image-type entries (placeholder + metadata only)

## Key Files to Modify

| File | Change Type |
|------|-------------|
| `ClipboardDao.ets` | Add `updateContent()` method |
| `ClipboardRepository.ets` | Add `updateContent()` to interface |
| `ClipboardRepositoryImpl.ets` | Implement `updateContent()` with re-encryption |
| `DetailViewModel.ets` | Add editing state, save/revert/dirty tracking |
| `DetailPage.ets` | Add TextArea, save/delete/discard UI, back navigation |
| `Index.ets` | Add Navigation wrapper |
| `HistoryPage.ets` | Wire onItemClick to navigate |
| `FavoritesPage.ets` | Wire onItemClick to navigate |

## Testing Strategy

Per Constitution II (TDD):
1. **Unit tests** for `DetailViewModel.saveContent()`, `revertContent()`, `isEntryDirty()`
2. **Unit tests** for `ClipboardDao.updateContent()`
3. **Unit tests** for `ClipboardRepositoryImpl.updateContent()` (re-encryption verification)
