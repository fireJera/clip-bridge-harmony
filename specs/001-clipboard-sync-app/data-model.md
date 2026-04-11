# Data Model: Clip Bridge v1

**Date**: 2026-04-05
**Feature**: 001-clipboard-sync-app

## Entity Relationship

```text
┌──────────────────┐     ┌──────────────────────────────┐     ┌──────────────────┐
│  ClipboardEntry   │────<│  EntryCategoryRelation       │>────│  CustomCategory  │
│                   │     │  (many-to-many junction)     │     │                  │
└──────────────────┘     └──────────────────────────────┘     └──────────────────┘

┌──────────────────┐
│ AppBlacklistEntry│
└──────────────────┘
```

## Tables

### clipboard_entry

Stores all captured clipboard content. Text content is encrypted; metadata is plaintext
for query performance.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PK, AUTOINCREMENT | Unique entry identifier |
| content_hash | TEXT | NOT NULL, UNIQUE | SHA-256 hash of content (for dedup) |
| content_encrypted | BLOB | NOT NULL | AES-256-GCM encrypted content |
| content_type | TEXT | NOT NULL | Auto-detected type: text/url/email/phone/image/address |
| content_preview | TEXT | NOT NULL | Plaintext preview (first 100 chars, for list display) |
| image_path | TEXT | NULLABLE | Sandbox file path for image content |
| thumbnail_path | TEXT | NULLABLE | Sandbox file path for image thumbnail (200x200) |
| content_size | INTEGER | NOT NULL | Content size in bytes |
| source_app | TEXT | NULLABLE | Source application bundle name |
| is_pinned | INTEGER | NOT NULL, DEFAULT 0 | 1 = pinned to top |
| is_favorite | INTEGER | NOT NULL, DEFAULT 0 | 1 = in favorites |
| pinned_at | TEXT | NULLABLE | ISO timestamp when pinned |
| favorited_at | TEXT | NULLABLE | ISO timestamp when favorited |
| created_at | TEXT | NOT NULL | ISO timestamp of capture |
| updated_at | TEXT | NOT NULL | ISO timestamp of last duplicate hit |
| iv | BLOB | NOT NULL | AES-GCM initialization vector |
| auth_tag | BLOB | NOT NULL | AES-GCM authentication tag |

**Indexes**:
- `idx_entry_hash` ON (content_hash) — dedup lookup
- `idx_entry_updated` ON (updated_at DESC) — history list sort
- `idx_entry_type` ON (content_type) — type filter
- `idx_entry_favorite` ON (is_favorite, favorited_at DESC) — favorites view
- `idx_entry_pinned` ON (is_pinned, pinned_at DESC) — pinned sort

**State transitions**:
```text
[captured] → [active] (in history list)
[active] → [pinned] (user pins)
[active] → [favorited] (user favorites)
[active/pinned/favorited] → [deleted] (user deletes or auto-pruned)
```
- Pinned + favorited can coexist
- Auto-prune only deletes [active] entries (not pinned, not favorited)

### custom_category

User-defined tag categories.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PK, AUTOINCREMENT | Unique category identifier |
| name | TEXT | NOT NULL, UNIQUE | Display name (1-50 chars) |
| color | TEXT | NULLABLE | Hex color code for UI badge |
| sort_order | INTEGER | NOT NULL, DEFAULT 0 | Display order |
| created_at | TEXT | NOT NULL | ISO timestamp |
| updated_at | TEXT | NOT NULL | ISO timestamp |

**Constraints**:
- Maximum 50 rows enforced at application level (checked before insert)
- `name` uniqueness is case-insensitive (normalized on insert)

### entry_category_relation

Many-to-many junction between entries and custom categories.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| entry_id | INTEGER | FK → clipboard_entry.id, ON DELETE CASCADE | Referenced entry |
| category_id | INTEGER | FK → custom_category.id, ON DELETE CASCADE | Referenced category |
| created_at | TEXT | NOT NULL | ISO timestamp when tag was applied |

**Constraints**:
- PK (entry_id, category_id) — prevents duplicate associations
- CASCADE delete: removing a category auto-removes all its relations

### app_blacklist_entry

Apps excluded from clipboard monitoring.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PK, AUTOINCREMENT | Unique identifier |
| bundle_name | TEXT | NOT NULL, UNIQUE | App bundle identifier |
| app_name | TEXT | NOT NULL | Display name |
| created_at | TEXT | NOT NULL | ISO timestamp |

### user_settings (Preferences, not SQLite)

Stored via `@ohos.data.preferences` as key-value pairs.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| history_limit | number | 500 | Maximum clipboard entries |
| privacy_mode | boolean | false | Monitoring paused |
| privacy_mode_until | string | null | ISO timestamp when privacy mode auto-expires |
| biometric_enabled | boolean | true | Require biometric on foreground |
| text_size_limit | number | 1048576 | Max text size in bytes (1MB) |
| image_size_limit | number | 10485760 | Max image size in bytes (10MB) |

## Encryption Model

```text
[Clipboard Content]
       │
       ▼
SHA-256 hash ──→ content_hash (indexed, plaintext for dedup)
       │
       ▼
AES-256-GCM encrypt (key from HUKS)
       │
       ├──→ content_encrypted (BLOB)
       ├──→ iv (BLOB, random per entry)
       └──→ auth_tag (BLOB)

[Metadata: type, timestamps, flags] → stored in plaintext (query performance)
[Preview: first 100 chars] → stored in plaintext (list display)
```

## Query Patterns

| Use Case | Query | Performance Target |
|----------|-------|--------------------|
| History list | SELECT ... ORDER BY is_pinned DESC, updated_at DESC LIMIT/OFFSET | <50ms |
| Type filter | SELECT ... WHERE content_type = ? ORDER BY updated_at DESC | <50ms |
| Custom category filter | SELECT e.* FROM clipboard_entry e JOIN entry_category_relation r ON e.id = r.entry_id WHERE r.category_id = ? | <100ms |
| Full-text search | SELECT ... WHERE content_preview LIKE '%keyword%' | <500ms |
| Dedup check | SELECT id FROM clipboard_entry WHERE content_hash = ? | <5ms |
| Favorites view | SELECT ... WHERE is_favorite = 1 ORDER BY favorited_at DESC | <50ms |
| Auto-prune | DELETE FROM clipboard_entry WHERE is_pinned = 0 AND is_favorite = 0 ORDER BY updated_at ASC LIMIT ? | <100ms |
