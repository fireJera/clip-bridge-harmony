# Implementation Plan: Clip Bridge - 剪贴板管理与多端同步

**Branch**: `001-clipboard-sync-app` | **Date**: 2026-04-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-clipboard-sync-app/spec.md`

## Summary

Build a HarmonyOS native clipboard manager app (v1) that automatically captures clipboard
content in the background, provides searchable/browsable history with auto-categorization
(text/url/email/phone/image/address), user-defined custom tags, and favorites. Pure local
app with no login or sync — architecture must reserve interfaces for v2 (auth, distributed
sync, cloud sync).

## Technical Context

**Language/Version**: ArkTS (HarmonyOS NEXT SDK API 12+)
**Primary Dependencies**: ArkUI, @ohos.pasteboard, @ohos.data.relationalStore,
  @ohos.security.cryptoFramework, @ohos.resourceschedule.backgroundTaskManager
**Storage**: SQLite via @ohos.data.relationalStore (local encrypted database),
  @ohos.data.preferences (settings)
**Testing**: @ohos.testing (unit), UiTest framework (instrumented/UI)
**Target Platform**: HarmonyOS NEXT (API 12+), mid-range mobile devices
**Project Type**: Mobile app (HAP module)
**Performance Goals**: 60fps list rendering, <2s cold start, <2s clipboard capture delay,
  <500ms search on 500 records
**Constraints**: <1% battery/hour background monitoring, encrypted local storage,
  offline-first (no network dependency in v1)
**Scale/Scope**: Up to 500 clipboard entries, 50 custom categories, 4 main screens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. HarmonyOS Native First | PASS | ArkTS + ArkUI + native APIs only |
| II. TDD (Non-negotiable) | PASS | Plan includes test-first workflow |
| III. Modern Architecture (MVVM+Clean) | PASS | MVVM + Repository pattern + DI |
| IV. Code Quality | PASS | Static analysis, naming conventions |
| V. UX Consistency | PASS | Shared design tokens, dark mode, accessibility |
| VI. Performance First | PASS | LazyForEach, encrypted storage, background limits |
| VII. Data Privacy & Security | PASS | Encryption at rest, biometric re-auth |

**Result**: All gates PASS. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/001-clipboard-sync-app/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (internal contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
entry/
├── src/main/
│   ├── ets/
│   │   ├── entryability/            # UIAbility (app lifecycle)
│   │   │   └── EntryAbility.ets
│   │   ├── pages/                   # ArkUI pages (Views)
│   │   │   ├── HistoryPage.ets      # Main history list (US1)
│   │   │   ├── DetailPage.ets       # Entry detail view (US1)
│   │   │   ├── FavoritesPage.ets    # Favorites view (US4)
│   │   │   └── SettingsPage.ets     # Settings (privacy, blacklist, limits)
│   │   ├── viewmodel/               # ViewModels (MVVM)
│   │   │   ├── HistoryViewModel.ets
│   │   │   ├── DetailViewModel.ets
│   │   │   ├── FavoritesViewModel.ets
│   │   │   └── SettingsViewModel.ets
│   │   ├── model/                   # Domain entities
│   │   │   ├── ClipboardEntry.ets
│   │   │   ├── CustomCategory.ets
│   │   │   ├── EntryCategoryRelation.ets
│   │   │   └── AppBlacklistEntry.ets
│   │   ├── repository/              # Repository interfaces + impls
│   │   │   ├── ClipboardRepository.ets
│   │   │   ├── CategoryRepository.ets
│   │   │   └── SettingsRepository.ets
│   │   ├── service/                 # Business logic services
│   │   │   ├── ClipboardMonitorService.ets   # Background monitoring
│   │   │   ├── ContentTypeDetector.ets       # Auto-categorization
│   │   │   ├── DeduplicationService.ets      # Global dedup
│   │   │   └── EncryptionService.ets        # Data encryption
│   │   ├── data/                    # Data layer (SQLite, preferences)
│   │   │   ├── database/
│   │   │   │   ├── AppDatabase.ets           # DB init + migrations
│   │   │   │   ├── ClipboardDao.ets
│   │   │   │   ├── CategoryDao.ets
│   │   │   │   └── BlacklistDao.ets
│   │   │   └── preferences/
│   │   │       └── UserSettings.ets
│   │   ├── common/                  # Shared utilities
│   │   │   ├── constants/
│   │   │   ├── utils/
│   │   │   └── theme/               # Design tokens, colors, typography
│   │   └── component/               # Reusable ArkUI components
│   │       ├── ClipboardListItem.ets
│   │       ├── SearchBar.ets
│   │       ├── CategoryFilter.ets
│   │       ├── EmptyState.ets
│   │       ├── LoadingState.ets
│   │       └── ConfirmationDialog.ets
│   └── resources/                   # Strings, images, dark mode qualifiers
│       ├── base/
│       │   ├── element/
│       │   │   ├── string.json
│       │   │   └── color.json
│       │   └── media/
│       └── dark/
│           └── element/
│               └── color.json
└── src/ohosTest/                    # Instrumented tests
    └── ets/
        └── test/
            ├── pages/
            │   └── HistoryPageTest.ets
            └── service/
                └── ContentTypeDetectorTest.ets

entry/src/test/                      # Unit tests (mirrors src/main/ets)
└── ets/
    └── test/
        ├── viewmodel/
        │   ├── HistoryViewModelTest.ets
        │   └── DetailViewModelTest.ets
        ├── service/
        │   ├── ContentTypeDetectorTest.ets
        │   ├── DeduplicationServiceTest.ets
        │   └── EncryptionServiceTest.ets
        └── repository/
            ├── ClipboardRepositoryTest.ets
            └── CategoryRepositoryTest.ets
```

**Structure Decision**: Single HAP entry module using MVVM + Clean Architecture layers.
Pages = Views, viewmodel/ = ViewModels, model/ = domain entities, repository/ = data
abstractions, data/ = persistence implementations, service/ = business logic. Tests mirror
source structure under `entry/src/test/` (unit) and `entry/src/ohosTest/` (instrumented).

## Complexity Tracking

> No violations — all principles pass.
