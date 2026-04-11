# Tasks: Clip Bridge v1

**Input**: Design documents from `/specs/001-clipboard-sync-app/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md, contracts/

**Tests**: TDD is mandatory per Constitution Principle II. Every implementation phase
includes test tasks that MUST be written and fail before implementation begins.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **HarmonyOS app**: `entry/src/main/ets/` (source), `entry/src/test/ets/` (unit tests),
  `entry/src/ohosTest/ets/` (instrumented tests), `entry/src/main/resources/` (resources)

---

## Phase 1: Setup (Project Initialization)

**Purpose**: HarmonyOS project scaffolding, build configuration, shared theme/constants

- [ ] T001 Initialize HarmonyOS HAP project in DevEco Studio with ArkTS template,
  target API 12+, module name `entry`
- [ ] T002 [P] Configure module.json5 with required permissions:
  `ohos.permission.READ_PASTEBOARD`, `ohos.permission.KEEP_BACKGROUND_RUNNING`,
  `ohos.permission.ACCESS_BIOMETRIC` in entry/src/main/module.json5
- [ ] T003 [P] Create directory structure per plan.md: entry/src/main/ets/{pages,
  viewmodel, model, repository, service, data/database, data/preferences, common/constants,
  common/utils, common/theme, component}
- [ ] T004 [P] Create test directory structure: entry/src/test/ets/test/{viewmodel,
  service, repository} and entry/src/ohosTest/ets/test/{pages, service}
- [ ] T005 [P] Define design tokens (colors, typography, spacing) in
  entry/src/main/ets/common/theme/ThemeTokens.ets
- [ ] T006 [P] Create base resource files: entry/src/main/resources/base/element/string.json
  (app name, common labels) and entry/src/main/resources/base/element/color.json
- [ ] T007 [P] Create dark mode resource overrides in
  entry/src/main/resources/dark/element/color.json
- [ ] T008 [P] Define app-wide constants (size limits, defaults) in
  entry/src/main/ets/common/constants/AppConstants.ets

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story implementation

**CRITICAL**: No user story work can begin until this phase is complete

### Data Layer

- [ ] T009 Write unit tests for AppDatabase initialization and migration in
  entry/src/test/ets/test/data/AppDatabaseTest.ets
- [ ] T010 Implement AppDatabase with encrypted SQLite via @ohos.data.relationalStore
  in entry/src/main/ets/data/database/AppDatabase.ets — creates DB with
  `encrypt: true`, defines schema for clipboard_entry, custom_category,
  entry_category_relation, app_blacklist_entry tables per data-model.md
- [ ] T011 [P] Write unit tests for ClipboardDao CRUD operations in
  entry/src/test/ets/test/data/ClipboardDaoTest.ets
- [ ] T012 [P] Implement ClipboardDao in entry/src/main/ets/data/database/ClipboardDao.ets
  — insert, getById, getHistory, getByType, getFavorites, search, findByHash,
  touchTimestamp, updatePin, updateFavorite, deleteById, deleteByIds, deleteAll,
  pruneOldest
- [ ] T013 [P] Write unit tests for CategoryDao in
  entry/src/test/ets/test/data/CategoryDaoTest.ets
- [ ] T014 [P] Implement CategoryDao in entry/src/main/ets/data/database/CategoryDao.ets
  — create, getAll, getById, update, delete, addTag, removeTag,
  getEntriesByCategory, getTagsForEntry
- [ ] T015 [P] Write unit tests for BlacklistDao in
  entry/src/test/ets/test/data/BlacklistDaoTest.ets
- [ ] T016 [P] Implement BlacklistDao in entry/src/main/ets/data/database/BlacklistDao.ets
  — insert, getAll, deleteById
- [ ] T017 Write unit tests for UserSettings preferences in
  entry/src/test/ets/test/data/UserSettingsTest.ets
- [ ] T018 Implement UserSettings via @ohos.data.preferences in
  entry/src/main/ets/data/preferences/UserSettings.ets — getHistoryLimit,
  setHistoryLimit, isPrivacyMode, setPrivacyMode, isBiometricEnabled,
  setBiometricEnabled

### Domain Models

- [ ] T019 [P] Implement ClipboardEntry model class in
  entry/src/main/ets/model/ClipboardEntry.ets — fields per data-model.md:
  id, contentHash, contentType, contentPreview, imagePath, thumbnailPath,
  contentSize, sourceApp, isPinned, isFavorite, pinnedAt, favoritedAt,
  createdAt, updatedAt
- [ ] T020 [P] Implement CustomCategory model class in
  entry/src/main/ets/model/CustomCategory.ets — id, name, color, sortOrder,
  createdAt, updatedAt
- [ ] T021 [P] Implement EntryCategoryRelation model in
  entry/src/main/ets/model/EntryCategoryRelation.ets — entryId, categoryId,
  createdAt
- [ ] T022 [P] Implement AppBlacklistEntry model in
  entry/src/main/ets/model/AppBlacklistEntry.ets — id, bundleName, appName,
  createdAt

### Core Services

- [ ] T023 Write unit tests for EncryptionService in
  entry/src/test/ets/test/service/EncryptionServiceTest.ets — test encrypt/decrypt
  roundtrip, hash determinism, hash uniqueness
- [ ] T024 Implement EncryptionService in
  entry/src/main/ets/service/EncryptionService.ets — encrypt (AES-256-GCM via
  @ohos.security.cryptoFramework), decrypt, hash (SHA-256)
- [ ] T025 Write unit tests for ContentTypeDetector in
  entry/src/test/ets/test/service/ContentTypeDetectorTest.ets — test email,
  phone, url, address, image, text detection with priority cascade
- [ ] T026 Implement ContentTypeDetector in
  entry/src/main/ets/service/ContentTypeDetector.ets — regex-based detection
  with priority: email > phone > url > address > image > text

### Repository Interfaces

- [ ] T027 [P] Define ClipboardRepository interface in
  entry/src/main/ets/repository/ClipboardRepository.ets — per contracts
- [ ] T028 [P] Define CategoryRepository interface in
  entry/src/main/ets/repository/CategoryRepository.ets — per contracts
- [ ] T029 [P] Define SettingsRepository interface in
  entry/src/main/ets/repository/SettingsRepository.ets — per contracts
- [ ] T030 Implement ClipboardRepositoryImpl wrapping ClipboardDao + EncryptionService
  in entry/src/main/ets/repository/ClipboardRepositoryImpl.ets — encrypts on insert,
  decrypts on read, delegates queries to DAO
- [ ] T031 [P] Implement CategoryRepositoryImpl wrapping CategoryDao in
  entry/src/main/ets/repository/CategoryRepositoryImpl.ets
- [ ] T032 [P] Implement SettingsRepositoryImpl wrapping UserSettings in
  entry/src/main/ets/repository/SettingsRepositoryImpl.ets

### App Entry Point

- [ ] T033 Implement EntryAbility in
  entry/src/main/ets/entryability/EntryAbility.ets — onCreate initializes DB,
  registers lifecycle callbacks (onForeground for biometric, onDestroy for cleanup)

**Checkpoint**: Foundation ready — database, models, services, repositories all implemented
and tested. User story implementation can now begin in parallel.

---

## Phase 3: User Story 1 — 自动记录剪贴板历史 (Priority: P1) MVP

**Goal**: Background clipboard monitoring with auto-capture, history list, detail page
with copy-to-clipboard

**Independent Test**: Copy multiple content types (text, URL, image) in other apps,
open Clip Bridge, verify history list shows all entries, tap entry to view detail,
tap copy to copy back

### Tests for User Story 1

- [ ] T034 [P] [US1] Write unit tests for DeduplicationService in
  entry/src/test/ets/test/service/DeduplicationServiceTest.ets — test checkDuplicate
  returns existing entry, promoteToTop updates timestamp
- [ ] T035 [P] [US1] Write unit tests for ClipboardMonitorService in
  entry/src/test/ets/test/service/ClipboardMonitorServiceTest.ets — test start/stop,
  onCapture callback, content size limit check
- [ ] T036 [P] [US1] Write unit tests for HistoryViewModel in
  entry/src/test/ets/test/viewmodel/HistoryViewModelTest.ets — test loadHistory,
  refresh, pagination
- [ ] T037 [P] [US1] Write unit tests for DetailViewModel in
  entry/src/test/ets/test/viewmodel/DetailViewModelTest.ets — test loadEntry,
  copyToClipboard, togglePin, delete

### Implementation for User Story 1

- [ ] T038 [US1] Implement DeduplicationService in
  entry/src/main/ets/service/DeduplicationService.ets — checkDuplicate via
  contentHash lookup, promoteToTop via touchTimestamp
- [ ] T039 [US1] Implement ClipboardMonitorService in
  entry/src/main/ets/service/ClipboardMonitorService.ets — registers
  @ohos.pasteboard on('update') listener, applies ContentTypeDetector,
  DeduplicationService, EncryptionService, size limit check, persists via
  ClipboardRepository; starts ContinuousTask via
  @ohos.resourceschedule.backgroundTaskManager
- [ ] T040 [P] [US1] Create ClipboardListItem component in
  entry/src/main/ets/component/ClipboardListItem.ets — displays contentPreview,
  contentType badge, timestamp, pin/favorite indicators, sync status placeholder
- [ ] T041 [P] [US1] Create EmptyState component in
  entry/src/main/ets/component/EmptyState.ets — shown when no clipboard entries
- [ ] T042 [P] [US1] Create LoadingState component in
  entry/src/main/ets/component/LoadingState.ets — shimmer/skeleton for loading
- [ ] T043 [US1] Implement HistoryViewModel in
  entry/src/main/ets/viewmodel/HistoryViewModel.ets — @ObservedV2 with @Trace
  properties for entries list, loading state, error state; loads history via
  ClipboardRepository with pagination
- [ ] T044 [US1] Implement HistoryPage in entry/src/main/ets/pages/HistoryPage.ets
  — ArkUI page with Navigation, LazyForEach + IDataSource for history list,
  ClipboardListItem for each row, FloatingActionButton for quick actions,
  bottom tab bar (history/favorites/settings)
- [ ] T045 [US1] Implement DetailViewModel in
  entry/src/main/ets/viewmodel/DetailViewModel.ets — loads single entry,
  decrypts content, provides copyToClipboard via @ohos.pasteboard, togglePin,
  toggleFavorite, delete
- [ ] T046 [US1] Implement DetailPage in entry/src/main/ets/pages/DetailPage.ets
  — displays full content (text with selectable, image with viewer), copy button,
  pin/favorite/delete action bar, metadata display (type, source, timestamp)
- [ ] T047 [US1] Integrate ClipboardMonitorService with EntryAbility lifecycle
  in entry/src/main/ets/entryability/EntryAbility.ets — start on onCreate,
  re-register on onForeground if needed, stop on onDestroy
- [ ] T048 [US1] Implement auto-prune logic in ClipboardRepositoryImpl — after
  each insert, check count against history_limit, prune oldest non-pinned
  non-favorited entries

**Checkpoint**: At this point, clipboard history capture + list + detail + copy
should be fully functional. User can copy content elsewhere, see it in history,
view details, and copy back.

---

## Phase 4: User Story 2 — 搜索与管理剪贴板历史 (Priority: P2)

**Goal**: Keyword search, single/batch delete, pin to top, clear all, privacy mode

**Independent Test**: Create 50+ entries, search by keyword, verify filter works,
long press to delete, batch select and delete, pin/unpin entries, toggle privacy mode

### Tests for User Story 2

- [ ] T049 [P] [US2] Write unit tests for search and delete in
  entry/src/test/ets/test/viewmodel/HistoryViewModelTest.ets — test searchEntries,
  deleteEntry, deleteBatch, clearAll, togglePin
- [ ] T050 [P] [US2] Write instrumented test for HistoryPage search interaction in
  entry/src/ohosTest/ets/test/pages/HistoryPageTest.ets — type in search bar,
  verify list updates

### Implementation for User Story 2

- [ ] T051 [P] [US2] Create SearchBar component in
  entry/src/main/ets/component/SearchBar.ets — text input with debounce (300ms),
  clear button, accessibility labels
- [ ] T052 [P] [US2] Create ConfirmationDialog component in
  entry/src/main/ets/component/ConfirmationDialog.ets — title, message, confirm/cancel
  buttons for destructive actions (delete all, clear history)
- [ ] T053 [US2] Add search functionality to HistoryViewModel — searchEntries method
  using ClipboardRepository.search, replaces list with search results, clear search
  restores full history
- [ ] T054 [US2] Add management operations to HistoryViewModel — deleteEntry,
  deleteBatch, clearAll (with confirmation), togglePin
- [ ] T055 [US2] Update HistoryPage — add SearchBar at top, long-press to enter
  selection mode, batch action bar (delete, pin), swipe-to-delete gesture,
  ConfirmationDialog for clear all
- [ ] T056 [US2] Implement SettingsPage skeleton in
  entry/src/main/ets/pages/SettingsPage.ets — sections for: history limit slider,
  privacy mode toggle, app blacklist entry, biometric toggle
- [ ] T057 [US2] Implement SettingsViewModel in
  entry/src/main/ets/viewmodel/SettingsViewModel.ets — loads/saves settings via
  SettingsRepository, manages privacy mode state, app blacklist CRUD
- [ ] T058 [US2] Implement privacy mode (monitoring pause) in
  ClipboardMonitorService — stop listening when privacy mode on, resume when off,
  support auto-expire via privacy_mode_until setting

**Checkpoint**: Search, delete, pin, and privacy mode all working. History list
is fully manageable.

---

## Phase 5: User Story 3 — 自动分类与自定义标签 (Priority: P2)

**Goal**: Auto-categorize entries by content type, user-defined custom categories,
filter by type or custom tag

**Independent Test**: Copy email/URL/phone/text/image, verify auto-type labels,
create custom categories, tag entries, filter by type and custom category

### Tests for User Story 3

- [ ] T059 [P] [US3] Write unit tests for CategoryViewModel in
  entry/src/test/ets/test/viewmodel/CategoryViewModelTest.ets — test
  createCategory, renameCategory, deleteCategory, addTag, removeTag, filterByCategory
- [ ] T060 [P] [US3] Write instrumented test for CategoryFilter component in
  entry/src/ohosTest/ets/test/component/CategoryFilterTest.ets — tap filter chip,
  verify list updates

### Implementation for User Story 3

- [ ] T061 [P] [US3] Create CategoryFilter component in
  entry/src/main/ets/component/CategoryFilter.ets — horizontal scrollable chip list
  showing auto-types (text/url/email/phone/image/address) + custom categories,
  multi-select with active state styling
- [ ] T062 [US3] Integrate ContentTypeDetector into capture pipeline — update
  ClipboardMonitorService to call detect() on each capture and store content_type
  in ClipboardEntry (already implemented in T026, wire into T039)
- [ ] T063 [US3] Add category management methods to HistoryViewModel —
  loadCategories, createCategory, renameCategory, deleteCategory, addTagToEntry,
  removeTagFromEntry, filterByType, filterByCategory
- [ ] T064 [US3] Update HistoryPage — add CategoryFilter above list, filter
  chips toggle type/category filter, empty state when no matches
- [ ] T065 [US3] Update DetailPage — add custom tag management section:
  show existing tags as chips, "add tag" button opens category picker,
  long-press tag to remove
- [ ] T066 [US3] Create CategoryPickerDialog component in
  entry/src/main/ets/component/CategoryPickerDialog.ets — shows all custom
  categories with checkboxes, "create new" option at bottom
- [ ] T067 [US3] Add category management section to SettingsPage — list custom
  categories with rename/delete, create new category with name + color picker,
  enforce 50-category limit

**Checkpoint**: Auto-categorization and custom tagging fully functional. Users can
filter history by type and custom categories.

---

## Phase 6: User Story 4 — 收藏剪贴板条目 (Priority: P2)

**Goal**: Favorite entries, independent favorites view, favorites protected from auto-prune

**Independent Test**: Mark entries as favorite, verify favorites view, unfavorite,
verify entry stays in history, verify favorites not auto-pruned

### Tests for User Story 4

- [ ] T068 [P] [US4] Write unit tests for FavoritesViewModel in
  entry/src/test/ets/test/viewmodel/FavoritesViewModelTest.ets — test
  loadFavorites, unfavorite, deleteFromFavorites, searchFavorites
- [ ] T069 [P] [US4] Write instrumented test for FavoritesPage in
  entry/src/ohosTest/ets/test/pages/FavoritesPageTest.ets — verify list loads,
  unfavorite removes entry from view

### Implementation for User Story 4

- [ ] T070 [P] [US4] Implement FavoritesViewModel in
  entry/src/main/ets/viewmodel/FavoritesViewModel.ets — loads favorited entries
  via ClipboardRepository.getFavorites, unfavorite, delete, search
- [ ] T071 [US4] Implement FavoritesPage in entry/src/main/ets/pages/FavoritesPage.ets
  — similar layout to HistoryPage but filtered to favorites only, LazyForEach,
  tap to DetailPage, unfavorite button on swipe
- [ ] T072 [US4] Add favorite toggle to DetailViewModel — toggleFavorite method
  via ClipboardRepository.updateFavorite
- [ ] T073 [US4] Update DetailPage — add favorite icon button in action bar
  (filled/outline based on state), toggles on tap
- [ ] T074 [US4] Add favorite indicator to ClipboardListItem — star icon overlay
  when is_favorite = true
- [ ] T075 [US4] Update bottom tab bar in HistoryPage — three tabs:
  History / Favorites / Settings, with badge count on Favorites tab
- [ ] T076 [US4] Verify auto-prune logic excludes favorites — update T048
  prune logic WHERE is_pinned = 0 AND is_favorite = 0

**Checkpoint**: All user stories (US1-US4) are independently functional.
Favorites view, auto-prune protection, and tab navigation all working.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements affecting multiple user stories

- [ ] T077 [P] Implement biometric re-authentication on foreground in
  EntryAbility.onForeground — use @ohos.userIAM.userAuth, show biometric prompt
  before revealing UI, fallback to device PIN, skip if biometric_enabled = false
- [ ] T078 [P] Add app blacklist management to SettingsPage — list installed apps
  (via @ohos.bundleManager), toggle blacklist, add/remove entries via BlacklistDao
- [ ] T079 [P] Integrate blacklist check into ClipboardMonitorService — skip capture
  when source app is in blacklist
- [ ] T080 [P] Add oversize content notification — when content exceeds limits
  (text >1MB, image >10MB), send system notification via @ohos.notificationManager
  informing user content was not saved
- [ ] T081 Review and optimize all database queries against performance targets
  in data-model.md (<50ms history, <500ms search, <5ms dedup)
- [ ] T082 [P] Add accessibility attributes to all interactive components —
  accessibilityText, accessibilityDescription per Constitution V
- [ ] T083 Run full test suite, verify all tests pass, fix any failures
- [ ] T084 Run quickstart.md validation — follow setup steps on clean environment

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — core MVP
- **US2 (Phase 4)**: Depends on Phase 2 — extends HistoryPage/ViewModel from US1
- **US3 (Phase 5)**: Depends on Phase 2 — extends HistoryPage/DetailPage from US1
- **US4 (Phase 6)**: Depends on Phase 2 — new page but shares DetailPage
- **Polish (Phase 7)**: Depends on all desired user stories

### User Story Dependencies

- **US1 (P1)**: Foundation only — no story dependencies
- **US2 (P2)**: Extends US1's HistoryPage and HistoryViewModel — build after US1
- **US3 (P2)**: Extends US1's HistoryPage and DetailPage — build after US1;
  independent from US2 (can be parallel with US2 if team allows)
- **US4 (P2)**: Depends on US1's models + DetailPage — build after US1;
  independent from US2/US3

### Within Each User Story

- Tests MUST be written and fail before implementation
- Models before services
- Services before ViewModels
- ViewModels before pages
- Shared components can be built in parallel with ViewModels

### Parallel Opportunities

- All Setup tasks (T002-T008) can run in parallel
- Within Foundational: DAOs (T011-T016) in parallel, models (T019-T022) in parallel,
  repository interfaces (T027-T029) in parallel
- US2 and US3 can be developed in parallel after US1 completes
  (they touch different files: US2 adds search/delete, US3 adds categories/tags)
- US4 can be developed in parallel with US2/US3 (new page + separate ViewModel)
- All Polish tasks (T077-T084) can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for US1 together:
Task T034: "DeduplicationService tests"
Task T035: "ClipboardMonitorService tests"
Task T036: "HistoryViewModel tests"
Task T037: "DetailViewModel tests"

# Then launch parallel components:
Task T040: "ClipboardListItem component"
Task T041: "EmptyState component"
Task T042: "LoadingState component"
```

## Parallel Example: Post-US1

```bash
# US2, US3, US4 can proceed in parallel:
Developer A: Phase 4 (US2 - Search & Manage)
Developer B: Phase 5 (US3 - Categories & Tags)
Developer C: Phase 6 (US4 - Favorites)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test clipboard capture, history list, detail page, copy
5. Deploy/demo if ready — this is a usable clipboard manager

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 → Test independently → MVP deploy
3. Add US2 → Search & management → Deploy
4. Add US3 → Categories & tags → Deploy
5. Add US4 → Favorites → Deploy
6. Polish → Cross-cutting concerns → v1 release

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Constitution requires TDD: tests before implementation, no exceptions
