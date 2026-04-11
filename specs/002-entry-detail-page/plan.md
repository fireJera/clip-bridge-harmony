# Implementation Plan: 剪贴板条目详情页 (Entry Detail Page)

**Branch**: `002-entry-detail-page` | **Date**: 2026-04-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-entry-detail-page/spec.md`

## Summary

Build a fully functional detail page for clipboard entries that supports:
- **Text editing** — inline TextArea for text-type entries with save (re-encrypt) and discard (with confirmation) flows
- **Non-text preview** — image placeholders and metadata display for image/URL/phone/email/address types
- **Management actions** — favorite toggle, delete (with confirmation), copy-to-clipboard
- **Navigation** — wire HistoryPage and FavoritesPage item clicks to navigate to DetailPage

**Key insight**: DetailPage and DetailViewModel already exist as partial implementations. This feature completes them by adding text editing, content update (with re-encryption), navigation integration, and unsaved-changes detection.

## Technical Context

**Language/Version**: ArkTS (HarmonyOS NEXT SDK API 12+)
**Primary Dependencies**: ArkUI declarative components, @ohos.pasteboard, @ohos.data.relationalStore
**Storage**: SQLite via @ohos.data.relationalStore (existing `clipboard_entry` table)
**Testing**: @ohos.testing (unit), UiTest framework (instrumented)
**Target Platform**: HarmonyOS NEXT (API 12+, compatible through API 14)
**Project Type**: Mobile app (HarmonyOS native HAP)
**Performance Goals**: 60 fps UI, <1s save operation, instant navigation transition
**Constraints**: Content must be re-encrypted on save (AES-256-GCM), offline-first
**Scale/Scope**: Single detail page, 3 navigation entry points (History, Favorites, Search results)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. HarmonyOS Native First | PASS | All implementation uses ArkTS/ArkUI native APIs |
| II. Test-Driven Development | PASS | Plan includes tests for ViewModel logic (edit/save/discard) and DAO update |
| III. Modern Architecture Patterns | PASS | MVVM — DetailViewModel handles all logic, DetailPage is pure UI. Repository pattern for data access. |
| IV. Code Quality & Maintainability | PASS | Existing code follows conventions; new code will match |
| V. UX Consistency | PASS | Uses ThemeTokens, consistent navigation patterns, handles error/empty/loading states |
| VI. Performance First | PASS | Async save, no UI thread blocking. LazyForEach not needed (single entry view) |
| VII. Data Privacy & Security | PASS | Re-encryption on save using EncryptionService. No content in logs. |

**No violations detected. Complexity Tracking table not needed.**

## Project Structure

### Documentation (this feature)

```text
specs/002-entry-detail-page/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── contracts/           # Phase 1 output
```

### Source Code (repository root)

```text
entry/src/main/ets/
├── pages/
│   ├── DetailPage.ets          # MODIFY — add text editing, delete confirmation, back navigation
│   ├── HistoryPage.ets         # MODIFY — wire onItemClick to navigate to DetailPage
│   ├── FavoritesPage.ets       # MODIFY — wire onItemClick to navigate to DetailPage
│   └── Index.ets               # MODIFY — add Navigation wrapper for page stack
├── viewmodel/
│   └── DetailViewModel.ets     # MODIFY — add saveContent(), isDirty tracking, delete with callback
├── repository/
│   ├── ClipboardRepository.ets # MODIFY — add updateContent(id, newContent) to interface
│   └── ClipboardRepositoryImpl.ets # MODIFY — implement updateContent with re-encryption
├── data/database/
│   └── ClipboardDao.ets        # MODIFY — add updateContent() DAO method
├── component/
│   └── CategoryPickerDialog.ets # EXISTING — used as-is
├── model/
│   └── ClipboardEntry.ets      # EXISTING — used as-is
├── common/
│   ├── theme/ThemeTokens.ets   # EXISTING — used as-is
│   └── utils/AppContext.ets    # EXISTING — used as-is for refresh notifications
└── service/
    └── EncryptionService.ets   # EXISTING — used as-is for re-encryption
```

**Structure Decision**: Single project structure. All changes are within the existing `entry/src/main/ets/` module. No new files needed — all modifications to existing files.

## Complexity Tracking

> No violations to justify. All changes conform to constitution principles.
