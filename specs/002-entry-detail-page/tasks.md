# Tasks: 剪贴板条目详情页 (Entry Detail Page)

**Input**: Design documents from `/specs/002-entry-detail-page/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Constitution II mandates TDD. Test tasks are included per Red-Green-Refactor cycle.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- All paths relative to repository root
- Source code: `entry/src/main/ets/`
- Tests: `entry/src/ohosTest/ets/` (instrumented) or `entry/src/test/ets/` (unit)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add Navigation infrastructure and data layer support for content updates

- [ ] T001 Wrap Tabs in `Navigation` component in `entry/src/main/ets/pages/Index.ets`, expose nav path stack to child pages
- [ ] T002 Add `updateContent(id: number, data: ContentUpdateData): Promise<void>` to `entry/src/main/ets/data/database/ClipboardDao.ets`
- [ ] T003 Add `updateContent(id: number, newContent: string): Promise<void>` to `IClipboardRepository` interface in `entry/src/main/ets/repository/ClipboardRepository.ets`
- [ ] T004 Implement `updateContent()` with re-encryption (hash, encrypt, preview, size, timestamp) in `entry/src/main/ets/repository/ClipboardRepositoryImpl.ets`

**Checkpoint**: Data layer ready for content updates. Navigation wrapper in place.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: ViewModel editing state and list page navigation wiring — MUST complete before UI work

- [ ] T005 [P] Add `editedContent`, `isDirty`, `isSaving`, `isNotFound` state properties and `onContentEdited()`, `saveContent()`, `revertContent()`, `isEntryDirty()` methods to `entry/src/main/ets/viewmodel/DetailViewModel.ets`
- [ ] T006 [P] Modify `onItemClick()` in `entry/src/main/ets/pages/HistoryPage.ets` to push DetailPage NavDestination with entryId
- [ ] T007 [P] Modify `onItemClick()` in `entry/src/main/ets/pages/FavoritesPage.ets` to push DetailPage NavDestination with entryId
- [ ] T008 Modify `loadEntry()` in `entry/src/main/ets/viewmodel/DetailViewModel.ets` to set `isNotFound = true` when `getById()` returns null, and initialize `editedContent = decryptedContent` on success

**Checkpoint**: ViewModel supports editing state. Both list pages navigate to detail on click.

---

## Phase 3: User Story 1 - 查看文本内容详情并编辑 (Priority: P1) 🎯 MVP

**Goal**: User can click a text entry from history/favorites, view full content, edit inline, save (re-encrypt) or discard with confirmation

**Independent Test**: Copy text → click entry in history → see full text in editable area → modify text → tap save → return to list → confirm content updated. Try editing and pressing back → confirm discard dialog appears.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T009 [P] [US1] Unit test for `DetailViewModel.saveContent()` — verifies isDirty resets, repo.updateContent called, AppContext notified in `entry/src/test/ets/test/DetailViewModelTest.ets`
- [ ] T010 [P] [US1] Unit test for `DetailViewModel.isEntryDirty()` and `onContentEdited()` — verifies dirty tracking in `entry/src/test/ets/test/DetailViewModelTest.ets`
- [ ] T011 [P] [US1] Unit test for `ClipboardDao.updateContent()` — verifies DB row updated with correct values in `entry/src/test/ets/test/ClipboardDaoTest.ets`

### Implementation for User Story 1

- [ ] T012 [US1] Replace content `Text` with `TextArea` for text-type entries in `entry/src/main/ets/pages/DetailPage.ets`, bind to `viewModel.editedContent` via `onContentEdited()`
- [ ] T013 [US1] Add save button to bottom bar (visible only when `isDirty`), call `viewModel.saveContent()` on tap, show success toast in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T014 [US1] Implement back navigation with unsaved changes detection — if `isDirty`, show AlertDialog confirming discard; intercept `onBackPressed` in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T015 [US1] Add `isNotFound` state handling — show "该条目已被删除" with back button when entry is null in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T016 [US1] Wire `AppContext.notifyDataChanged()` calls in `saveContent()`, `deleteEntry()`, `toggleFavorite()`, `togglePin()` in `entry/src/main/ets/viewmodel/DetailViewModel.ets`

**Checkpoint**: User Story 1 complete — text entries are viewable, editable, and saveable with unsaved changes protection.

---

## Phase 4: User Story 2 - 预览非文本内容 (Priority: P2)

**Goal**: User can click image/non-text entries and see appropriate preview with metadata

**Independent Test**: Copy an image → click image entry → see "[Image]" placeholder with metadata (source app, type, timestamp). Click URL/phone/email entries → see full content with metadata.

### Implementation for User Story 2

- [ ] T017 [US2] Add image-type placeholder UI — display "[Image]" text with icon in a styled container for `contentType === 'image'` entries in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T018 [US2] Add read-only content display for non-editable types (URL, email, phone, address) — use `Text` with `copyOption(CopyOptions.LocalDevice)` instead of `TextArea` in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T019 [US2] Ensure metadata section (type, source app, created time, updated time) displays for all content types in `entry/src/main/ets/pages/DetailPage.ets`

**Checkpoint**: User Story 2 complete — all content types display appropriately with metadata.

---

## Phase 5: User Story 3 - 管理条目操作 (Priority: P3)

**Goal**: User can favorite/unfavorite, delete (with confirmation), and copy content from detail page

**Independent Test**: Enter detail → tap favorite → confirm state changes → tap delete → confirm dialog → entry removed from list. Tap copy → content in system clipboard.

### Implementation for User Story 3

- [ ] T020 [P] [US3] Add delete button to top bar with `AlertDialog` confirmation, call `viewModel.deleteEntry()` and pop nav stack on success in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T021 [P] [US3] Ensure existing favorite toggle button in top bar updates UI state reactively (opacity based on `isFavorite`) and calls `viewModel.toggleFavorite()` in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T022 [US3] Ensure copy-to-clipboard button in bottom bar works for all content types using `viewModel.copyToClipboard()` with success feedback toast in `entry/src/main/ets/pages/DetailPage.ets`

**Checkpoint**: User Story 3 complete — all management actions functional from detail page.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Ensure consistency, handle edge cases, validate against constitution

- [ ] T023 Handle empty content validation — disable save button when edited content is empty in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T024 Ensure long text content scrolls properly in `TextArea` with adequate height constraints in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T025 Add `accessibilityText` and `accessibilityDescription` to all interactive elements (buttons, TextArea) in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T026 Verify dark mode support — all new UI uses `ThemeTokens` constants, no hardcoded colors in `entry/src/main/ets/pages/DetailPage.ets`
- [ ] T027 Run quickstart.md validation — verify full user flow: list → detail → edit → save → back

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — MVP target
- **US2 (Phase 4)**: Depends on Phase 2 — can run in parallel with US1
- **US3 (Phase 5)**: Depends on Phase 2 — can run in parallel with US1/US2
- **Polish (Phase 6)**: Depends on US1 (at minimum)

### User Story Dependencies

- **US1 (P1)**: Depends on foundational (T005, T006, T007, T008) — no dependency on other stories
- **US2 (P2)**: Depends on foundational — no dependency on US1 (different UI paths in same file, but US1 edits the same DetailPage)
- **US3 (P3)**: Depends on foundational — extends existing buttons in DetailPage

**Note**: US1, US2, and US3 all modify `DetailPage.ets` so they are file-conflicting. In practice, implement sequentially: US1 → US2 → US3.

### Within Each User Story

- Tests MUST be written and FAIL before implementation (Constitution II)
- Data layer before ViewModel
- ViewModel before UI
- Core implementation before edge cases

### Parallel Opportunities

- T002, T003, T004 can run in sequence (DAO → interface → impl) but T001 is independent
- T005, T006, T007 are parallel (different files) within Phase 2
- T009, T010, T011 are parallel (different test files) within US1
- T020, T021 are parallel conceptually but same file — implement sequentially

---

## Parallel Example: Phase 2

```text
# These tasks touch different files and can run in parallel:
Task T005: "Add editing state to DetailViewModel.ets"
Task T006: "Wire HistoryPage onItemClick to navigate"
Task T007: "Wire FavoritesPage onItemClick to navigate"

# After T005-T007 complete, T008 updates DetailViewModel (sequential)
```

## Parallel Example: US1 Tests

```text
# These test tasks can run in parallel (different test focuses):
Task T009: "Unit test for saveContent()"
Task T010: "Unit test for dirty tracking"
Task T011: "Unit test for DAO updateContent()"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T008)
3. Complete Phase 3: User Story 1 (T009-T016)
4. **STOP and VALIDATE**: Click entry → view → edit → save → back. Confirm list refreshes.
5. Ship MVP if desired

### Incremental Delivery

1. Setup + Foundational → Infrastructure ready
2. Add US1 → Text editing works → MVP!
3. Add US2 → Image/non-text preview works
4. Add US3 → Favorite/delete/copy from detail works
5. Polish → Edge cases, accessibility, dark mode

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- All user stories modify DetailPage.ets — implement sequentially to avoid conflicts
- Tests are mandatory per Constitution II (TDD)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
