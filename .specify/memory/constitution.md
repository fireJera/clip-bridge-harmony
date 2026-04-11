<!--
Sync Impact Report:
- Version change: N/A → 1.1.0 (initial ratification with app-specific additions)
- Added principles:
  - I. HarmonyOS Native First
  - II. Test-Driven Development (NON-NEGOTIABLE)
  - III. Modern Architecture Patterns
  - IV. Code Quality & Maintainability
  - V. UX Consistency
  - VI. Performance First
  - VII. Data Privacy & Security (application-specific)
- Added sections:
  - Application Domain Constraints (clipboard-specific rules)
  - Technology Stack
  - Development Workflow
- Removed sections: N/A (first version)
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ compatible (no changes needed)
  - .specify/templates/spec-template.md ✅ compatible (no changes needed)
  - .specify/templates/tasks-template.md ✅ compatible (no changes needed)
- Follow-up TODOs: None
- Version bump rationale: MINOR — added Principle VII (Data Privacy & Security)
  and Application Domain Constraints section beyond the initial 6 principles.
-->

# Clip Bridge Harmony Constitution

## Core Principles

### I. HarmonyOS Native First

All features MUST be implemented using HarmonyOS native APIs and ArkTS/ArkUI as
the primary development stack. Cross-platform abstractions are only acceptable
when HarmonyOS provides no native equivalent for a required capability.

- Use ArkTS (eTS) as the primary language; avoid JS/TS compatibility shims
  unless interfacing with third-party libraries that lack ArkTS bindings.
- Use ArkUI declarative components for all UI; no web-view-based UI except for
  embedded content viewers (e.g., rich text preview).
- Leverage HarmonyOS system capabilities (Background Task Manager, Distributed
  Data, Pasteboard, etc.) through their native APIs.
- All module boundaries MUST align with HAP/HSP module conventions.
- Target HarmonyOS NEXT SDK API 12+; code MUST compile and run on both API 12
  and API 14 without conditional branching unless a feature is genuinely
  API-level-gated.

**Why**: Native development maximizes performance, access to platform features,
and long-term maintainability on the HarmonyOS ecosystem. API 12+ compatibility
ensures broad device coverage while avoiding legacy API surface.

### II. Test-Driven Development (NON-NEGOTIABLE)

TDD is mandatory for all production code. The Red-Green-Refactor cycle is
strictly enforced.

- Tests MUST be written before implementation code.
- Every feature task follows: write tests → user approves tests → confirm tests
  fail → implement → confirm tests pass → refactor.
- Unit tests MUST cover ViewModel/Model logic; instrumented tests MUST cover
  UI components where feasible.
- Minimum coverage target: 80% for business logic (ViewModel/Service layers).
- Test files MUST mirror source structure under a `mock/` or `test/` directory
  within each module.
- Sync-related logic (conflict resolution, delta computation, retry) MUST have
  dedicated unit tests covering edge cases (network loss, concurrent edits,
  data corruption).

**Why**: TDD ensures correctness by design, provides living documentation, and
enables safe refactoring. In a native platform context where debugging tools
are still maturing, tests are the primary safety net — especially critical
for sync logic where race conditions are subtle and costly.

### III. Modern Architecture Patterns

The project MUST follow established, modern architecture patterns suited for
HarmonyOS application development.

- **MVVM (Model-View-ViewModel)** is the required UI architecture pattern.
  - View: ArkUI declarative pages (`@Component` structs).
  - ViewModel: `@ObservedV2` / `@Observable` classes managing UI state.
  - Model: Plain data classes and repository interfaces.
- **Clean Architecture layering** for module internals:
  - **Presentation**: UI components + ViewModels.
  - **Domain**: Use cases / business logic (optional for simple modules,
    mandatory for complex ones like sync engine).
  - **Data**: Repositories, data sources, remote/local persistence.
- **Repository Pattern** for all data access: ViewModels MUST NOT directly
  access `@ohos.data.*` or network APIs. All data flows through a Repository
  abstraction that encapsulates local storage, distributed data, and cloud
  sync sources behind a unified interface.
- **Dependency Injection**: Use constructor injection or HarmonyOS-native DI
  mechanisms. Avoid service locator patterns.
- **Unidirectional Data Flow**: State flows down (ViewModel → View), events
  flow up (View → ViewModel). Avoid two-way binding except for form inputs.

**Why**: MVVM + Clean Architecture separates concerns cleanly, makes code
testable at each layer, and aligns with HarmonyOS recommended practices.
The Repository pattern is essential for abstracting the dual sync strategy
(distributed + cloud) behind a single interface.

### IV. Code Quality & Maintainability

Code quality is a non-negotiable discipline, not an afterthought.

- All code MUST pass static analysis (hvigor lint / custom rules) with zero
  warnings before merge.
- Naming conventions MUST follow HarmonyOS/ArkTS community standards:
  PascalCase for classes/components, camelCase for functions/variables,
  UPPER_SNAKE_CASE for constants.
- Functions MUST do one thing. If a function exceeds 40 lines, it MUST be
  refactored into smaller, named functions.
- Magic numbers and hardcoded strings MUST be extracted into constants or
  resource files (`string.json`, `constants.ets`).
- Comments MUST explain "why", not "what". Code should be self-documenting;
  comments are for non-obvious decisions.
- All `@Prop`, `@Link`, `@State`, `@Provide`, `@Consume` decorators MUST have
  explicit type annotations.

**Why**: Consistent, clean code reduces bugs, accelerates onboarding, and
makes code reviews effective. Static analysis catches issues that reviews miss.

### V. UX Consistency

User experience MUST be consistent across all screens and interactions within
the application.

- All UI components MUST use the project's shared design tokens (colors,
  typography, spacing) defined in a centralized theme/resource module.
- Navigation patterns MUST be consistent: use `Navigation` component with a
  unified `NavRouter`; avoid ad-hoc `router.pushUrl` except for deep links.
- Interactive elements MUST have consistent touch targets (minimum 44vp),
  feedback (haptic/visual), and animation curves.
- Error states, empty states, and loading states MUST be handled for every
  data-driven screen using shared skeleton/shimmer/placeholder components.
- Accessibility: all interactive elements MUST have `accessibilityText` and
  `accessibilityDescription` set; support for screen readers is mandatory.
- Dark mode MUST be supported from day one via resource qualifiers
  (`dark/` resource folders).
- Clipboard list items MUST display: content preview (truncated), source app
  icon/name (when available), timestamp, and sync status indicator.

**Why**: Consistency builds user trust and reduces learning curve. A shared
design system prevents visual drift across modules developed by different
contributors.

### VI. Performance First

Performance is a feature, not an optimization phase.

- UI rendering MUST maintain 60 fps; jank exceeding 3 frames in any
  interaction is a bug.
- List rendering MUST use `LazyForEach` with `IDataSource` for collections
  exceeding 20 items; no `ForEach` for large lists. Clipboard history can
  grow to hundreds of items — `LazyForEach` is mandatory for the history list.
- Network calls MUST be asynchronous and non-blocking; the UI thread MUST
  never wait on I/O.
- Clipboard monitoring MUST run as a lightweight Background Task with minimal
  CPU/memory footprint. Background monitoring MUST NOT drain more than 1%
  battery per hour on mid-range devices.
- Memory: avoid retaining large object graphs in `@State`; use `@LocalStorage`
  or `@PersistentStorage` for shared state, and release resources in
  `aboutToDisappear`. Clipboard image content MUST be stored on disk and
  loaded lazily — never held in memory for the full list.
- Startup time: the first meaningful frame MUST render within 2 seconds on
  mid-range devices. Defer non-critical initialization (cloud sync, analytics).
- Every PR that touches rendering or data flow MUST include a performance
  self-assessment noting impact on frame rate, memory, and startup time.

**Why**: Mobile users perceive performance directly. A clipboard manager runs
constantly in the background — resource efficiency is critical for user trust
and system health.

### VII. Data Privacy & Security

Clipboard data is inherently sensitive. Security and privacy MUST be treated
as first-class requirements.

- All clipboard content stored locally MUST be encrypted at rest using
  HarmonyOS-provided encryption APIs (`@ohos.security.cryptoFramework`).
- Synced data in transit MUST use TLS 1.2+; cloud storage MUST encrypt data
  at rest with a key derived from the user's identity.
- The app MUST NOT log or transmit clipboard content for analytics purposes.
  Analytics MAY track metadata (content type, size, timestamp) with user
  consent — never actual content.
- Users MUST be able to:
  - Exclude specific apps from clipboard monitoring (app-level blacklist).
  - Manually purge individual or all clipboard history entries.
  - Pause monitoring temporarily (e.g., "incognito mode" for 30 minutes).
- Biometric / device credential MUST be required to access the clipboard
  history when the app is opened from background (re-authentication).
- Cloud sync MUST be opt-in, not enabled by default. Users MUST be clearly
  informed about what data is synced and where it is stored.

**Why**: Clipboard content frequently includes passwords, personal messages,
financial information, and other sensitive data. Mishandling this data is a
critical privacy violation that can cause real harm to users.

## Application Domain Constraints

This section captures rules specific to the Clip Bridge application domain.

### Clipboard Monitoring

- The app MUST use `@ohos.pasteboard` (Pasteboard Service) with change
  listener to detect clipboard updates in real time.
- Background monitoring MUST use `BackgroundTaskManager` with the appropriate
  long-running task type, respecting system resource quotas.
- Each clipboard entry MUST capture: content (text/image/URI), content type,
  source app identifier (when system permits), and timestamp.
- Duplicate consecutive entries (same content within 2 seconds) MUST be
  deduplicated — only one entry stored.
- Maximum history retention MUST be configurable (default: 500 entries).
  Oldest entries are pruned automatically.

### Multi-Device Sync

The app MUST support two sync strategies, with a unified user experience:

1. **HarmonyOS Distributed Sync** (preferred for HarmonyOS-to-HarmonyOS):
   - Use `@ohos.data.distributedData` (KV store) or
     `@ohos.data.distributedDataObject` for real-time sync between devices
     on the same HarmonyOS account.
   - Conflict resolution: last-write-wins with timestamp comparison.
     Distributed timestamp MUST use `@ohos.systemDateTime` for consistency.

2. **Cloud Sync** (fallback / cross-platform):
   - Backend API with RESTful endpoints for clipboard entry CRUD operations.
   - WebSocket or SSE for real-time push notifications of new entries.
   - Incremental sync using sequence IDs — never full-history sync unless
     explicitly triggered by the user.
   - Offline-first: local storage is the source of truth; cloud sync is
     eventual consistency. The app MUST be fully functional without network.

3. **Unified Sync Engine**:
   - A single `SyncEngine` abstraction manages both distributed and cloud
     sync channels.
   - Users see one sync status indicator per entry, regardless of the
     underlying transport.
   - Sync conflicts MUST be surfaced to the user with a resolution UI
     (keep local / keep remote / keep both) when automatic resolution is
     not possible.

## Technology Stack

- **Language**: ArkTS (HarmonyOS-native TypeScript superset)
- **UI Framework**: ArkUI (declarative UI)
- **Build System**: Hvigor (HarmonyOS native build tool)
- **IDE**: DevEco Studio (required for emulation and profiling)
- **SDK**: HarmonyOS NEXT SDK (API 12+, compatible through API 14)
- **Testing Framework**: `@ohos.testing` (unit), `UiTest` framework
  (instrumented/UI)
- **State Management**: `@ObservedV2` / `@Trace` (preferred), `AppStorage`
  / `LocalStorage` for cross-component shared state
- **Clipboard Access**: `@ohos.pasteboard` with change listener
- **Local Storage**: `@ohos.data.relationalStore` (SQLite) for clipboard
  history, `@ohos.data.preferences` for settings
- **Distributed Sync**: `@ohos.data.distributedData` /
  `@ohos.data.distributedDataObject`
- **Cloud Sync**: `@ohos.net.http` (REST), `@ohos.net.webSocket` (real-time)
- **Security**: `@ohos.security.cryptoFramework` for encryption at rest
- **Background Tasks**: `@ohos.resourceschedule.backgroundTaskManager`
- **DI Pattern**: Constructor injection with factory/provider functions;
  no framework dependency for DI

## Development Workflow

1. **Feature Branch**: Every feature or fix MUST be developed on a branch
   named `[type]/[short-description]` (e.g., `feat/clipboard-sync`,
   `fix/list-jank`).
2. **TDD Cycle**: Write tests → Verify tests fail → Implement → Verify
   tests pass → Refactor → Commit.
3. **Code Review**: All PRs MUST pass:
   - Static analysis with zero warnings.
   - All tests green (unit + instrumented).
   - At least one peer review approval.
   - Constitution compliance check (principles I-VII).
4. **Commit Convention**: Use Conventional Commits
   (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
5. **Performance Check**: PRs affecting UI or data flow MUST include a
   performance self-assessment in the PR description.
6. **Security Review**: PRs touching clipboard data handling, sync logic,
   or storage MUST include a security self-assessment covering encryption,
  data exposure, and user consent.

## Governance

This constitution is the authoritative source for development principles
in the Clip Bridge Harmony project. It supersedes informal practices,
verbal agreements, and individual preferences.

- **Amendment Process**: Proposed changes MUST be documented with rationale,
  reviewed by at least one project contributor, and include a migration plan
  for existing code that violates the new principle.
- **Versioning**: Constitution follows semantic versioning.
  - MAJOR: Principle removed or redefined in a backward-incompatible way.
  - MINOR: New principle added or existing principle materially expanded.
  - PATCH: Clarifications, wording improvements, non-semantic refinements.
- **Compliance**: All PRs and code reviews MUST verify compliance with the
  current constitution version. Non-compliant code MUST NOT be merged.
- **Complexity Justification**: Any deviation from these principles MUST be
  documented in the plan's Complexity Tracking table with:
  - The specific principle being violated.
  - Why the violation is necessary.
  - What simpler alternative was considered and rejected.

**Version**: 1.1.0 | **Ratified**: 2026-04-05 | **Last Amended**: 2026-04-05
