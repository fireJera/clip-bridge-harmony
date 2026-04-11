# Research: Clip Bridge v1

**Date**: 2026-04-05
**Feature**: 001-clipboard-sync-app

## 1. Clipboard Monitoring on HarmonyOS NEXT

**Decision**: Use `@ohos.pasteboard` Pasteboard service with `on('update')` change listener
running inside a Background Task.

**Rationale**:
- HarmonyOS NEXT provides `pasteboard.getSystemPasteboard()` with an `on('update')` event
  that fires on any clipboard change system-wide.
- Background monitoring requires `BackgroundTaskManager.startContinuousTask()` with the
  `dataTransfer` task type. This keeps the app's UIAbility alive when not in foreground.
- The service runs inside `EntryAbility` or a dedicated `ServiceExtension` (API 12+ supports
  `TaskDispatcher` for background work).

**Alternatives considered**:
- Polling clipboard at intervals → rejected: wastes battery, violates Constitution VI
  (<1% battery/hour)
- Using Accessibility service → rejected: over-complicated, requires additional permissions

## 2. Background Task Lifecycle

**Decision**: Use `ContinuousTask` with `dataTransfer` type, started from `EntryAbility.onCreate()`
and stopped in `onDestroy()`.

**Rationale**:
- `ContinuousTask` is the only mechanism that allows long-running background work on
  HarmonyOS NEXT without the system killing the process.
- Must show a persistent notification to the user (system requirement).
- If system kills the task, the app must re-register on next launch.

**Alternatives considered**:
- `TransientTask` (short duration) → rejected: only for brief operations (<3 min)
- WorkScheduler (deferred) → rejected: not suitable for real-time monitoring

## 3. Local Data Encryption

**Decision**: Use `@ohos.security.cryptoFramework` with AES-256-GCM for clipboard content
encryption at rest. Key derived from device credential via `@ohos.security.huks`.

**Rationale**:
- HUKS (Hardware Universal Key Store) provides hardware-backed key storage.
- AES-256-GCM provides authenticated encryption (confidentiality + integrity).
- Key never leaves secure hardware; only ciphertext touches the database.
- Metadata (type, timestamp, etc.) stored in plaintext for query performance.

**Alternatives considered**:
- SQLite SEE (encrypted extension) → rejected: not standard in HarmonyOS SDK
- No encryption → rejected: violates Constitution VII

## 4. SQLite Schema Design

**Decision**: Use `@ohos.data.relationalStore` (RDB) with indexed tables for entries,
categories, and relations. Full-text search via LIKE queries with a dedicated content
search column.

**Rationale**:
- `relationalStore` is the standard HarmonyOS SQLite wrapper, supports encryption via
  `encrypt: true` option on database creation.
- LIKE-based search is sufficient for 500 records (<500ms target). FTS5 is not available
  in HarmonyOS RDB.
- Indexes on `timestamp DESC`, `content_type`, `is_pinned`, `is_favorite` for fast
  filtering.

**Alternatives considered**:
- `@ohos.data.distributedData` (KV store) → rejected: no query support, v1 is local-only
- `@ohos.data.preferences` → rejected: not suitable for structured data with relations

## 5. Content Type Detection (Auto-categorization)

**Decision**: Regex-based pattern matching applied at capture time. Six types with priority
cascade: email > phone > url > address > image > text (fallback).

**Rationale**:
- Regex is fast, offline, and sufficient for 95% accuracy target.
- Priority cascade handles ambiguity (e.g., `user@example.com` matches both email and url;
  email wins because it's more specific).
- Detection runs synchronously at capture time (no async needed for regex).

**Patterns**:
| Type | Pattern | Priority |
|------|---------|----------|
| email | RFC 5322 simplified: `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}` | 1 (highest) |
| phone | International/national: `(\+?\d{1,4}[-.\s]?)?\(?\d{1,4}\)?[-.\s]?\d{1,4}[-.\s]?\d{1,9}` with min 7 digits | 2 |
| url | Common URL: `https?://[^\s]+` or `www\.[^\s]+\.[a-zA-Z]{2,}` | 3 |
| address | Chinese address heuristic: starts with province/city names or contains road/street keywords | 4 |
| image | Pasteboard `MimeType`=image/* | 5 |
| text | Fallback for all other content | 6 (lowest) |

**Alternatives considered**:
- ML-based classification → rejected: overkill for v1, adds latency
- User-defined rules → deferred to v2

## 6. Image Storage Strategy

**Decision**: Save image data to app sandbox files, store only file path in database.
Load thumbnails lazily via ArkUI `Image` component with `objectFit: ImageFit.Cover`.

**Rationale**:
- Images can be large (up to 10MB); storing blobs in SQLite degrades query performance.
- File-based storage allows lazy loading and OS-level caching.
- Thumbnail generation via `@ohos.multimedia.image` `ImagePacker` at capture time
  (scaled to 200x200 for list preview).

**Alternatives considered**:
- Store as SQLite BLOB → rejected: memory pressure, slow queries
- Store original only (no thumbnail) → rejected: list scrolling would decode full images

## 7. Deduplication Strategy

**Decision**: Hash-based global dedup using SHA-256 content hash stored as indexed column.
On duplicate hit, update `updated_at` timestamp and move to top.

**Rationale**:
- SHA-256 hash provides O(1) lookup for duplicates regardless of content size.
- Hash column indexed for fast lookups during capture (<1ms expected).
- Only hashes text content; images compared by file size + pixel hash (simplified).

**Alternatives considered**:
- Full content comparison → rejected: slow for large text/images
- Fuzzy matching (similar content) → deferred to v2

## 8. Biometric Re-authentication

**Decision**: Use `@ohos.userIAM.userAuth` to prompt for biometric/device credential when
app returns from background (detected via `onForeground` lifecycle callback).

**Rationale**:
- `userAuth` API supports fingerprint, face, and device PIN as fallback.
- Only triggers when app transitions from background to foreground (not on every page
  navigation within the app).
- Constitution VII requires this for clipboard data protection.

**Alternatives considered**:
- Custom PIN → rejected: worse UX, reinventing the wheel
- No re-auth → rejected: violates Constitution VII

## 9. Dark Mode

**Decision**: Use HarmonyOS resource qualifiers (`dark/` folder) with color tokens defined
in `base/element/color.json` and overridden in `dark/element/color.json`.

**Rationale**:
- Standard HarmonyOS mechanism, no code-level theme switching needed.
- Constitution V requires dark mode from day one.

**Alternatives considered**:
- Programmatic theme switching → rejected: more complex, not needed

## 10. MVVM + Clean Architecture on HarmonyOS

**Decision**:
- View: `@Component` structs in `pages/`
- ViewModel: `@ObservedV2` classes in `viewmodel/`, injected into pages
- Model: Plain data classes in `model/`
- Repository: Interfaces in `repository/`, implementations in `data/`
- Service: Stateless business logic in `service/`
- DI: Constructor injection via factory functions

**Rationale**:
- `@ObservedV2` + `@Trace` is the modern HarmonyOS state observation mechanism (API 12+).
- Repository pattern abstracts data sources, essential for v2 sync integration.
- Constructor injection keeps ViewModels testable (pass mock repositories).

**Alternatives considered**:
- `@State`-only approach → rejected: untestable, no separation of concerns
- Global singleton services → rejected: violates Constitution III (no service locator)
