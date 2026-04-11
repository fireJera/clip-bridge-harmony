# Data Model: 剪贴板条目详情页 (Entry Detail Page)

**Branch**: `002-entry-detail-page` | **Date**: 2026-04-08

## Entity: ClipboardEntry (EXISTING — no schema changes)

No new entities or table modifications required. The detail page operates on the existing `ClipboardEntry` model and `clipboard_entry` database table.

### Key Fields Used by Detail Page

| Field | Type | Usage in Detail Page |
|-------|------|---------------------|
| `id` | number | Entry identifier, passed via navigation parameter |
| `contentEncrypted` | Uint8Array | Decrypted for display/edit, re-encrypted on save |
| `contentType` | string | Determines UI mode: text → editable, image → preview-only |
| `contentPreview` | string | Regenerated from new content on save (max 100 chars) |
| `contentSize` | number | Updated on save with new content byte length |
| `contentHash` | string | Recalculated on save for deduplication |
| `sourceApp` | string | Displayed in metadata section |
| `isPinned` | boolean | Toggled via detail page action |
| `isFavorite` | boolean | Toggled via detail page action |
| `createdAt` | string (ISO-8601) | Displayed in metadata section |
| `updatedAt` | string (ISO-8601) | Updated to current time on save |
| `iv` | Uint8Array | Regenerated on save (new encryption IV) |
| `authTag` | Uint8Array | Regenerated on save (new auth tag) |
| `tags` | CustomCategory[] | Displayed in tags section, add/remove via CategoryRepository |

### State Transitions

```
[Load] → Loading → Loaded (read-only)
                  → Loaded (text, editable)
                  → Loaded (image, preview-only)
                  → Not Found (entry deleted externally)

[Edit Flow] → Dirty (text modified) → Save → Saved (re-encrypted, lists refreshed)
                                  → Discard → Confirm → Loaded (reverted)
                                  → Back → Confirm discard → [Navigate back]
```

## ViewModel State: DetailViewModel (MODIFY — add new state)

| Property | Type | Purpose |
|----------|------|---------|
| `editedContent` | string | Current text in the editor (may differ from `decryptedContent`) |
| `isDirty` | boolean | `true` when `editedContent !== decryptedContent` |
| `isSaving` | boolean | `true` while save operation is in progress |
| `isNotFound` | boolean | `true` when entry was deleted externally |

## Repository Method: updateContent (NEW)

### Interface Addition (ClipboardRepository.ets)

```typescript
updateContent(id: number, newContent: string): Promise<void>;
```

### Data Flow on Save

1. ViewModel calls `repo.updateContent(entry.id, editedContent)`
2. Repository:
   a. Hashes new content → `contentHash`
   b. Generates new preview → `contentPreview` (first 100 chars)
   c. Calculates content size → `contentSize` (byte length)
   d. Encrypts new content → `contentEncrypted`, `iv`, `authTag`
   e. Calls `dao.updateContent(id, { contentHash, contentEncrypted, contentPreview, contentSize, iv, authTag, updatedAt })`
3. ViewModel updates local state from fresh `repo.getById()` call
4. ViewModel calls `AppContext.notifyDataChanged()` to refresh lists

## DAO Method: updateContent (NEW)

### Addition (ClipboardDao.ets)

```typescript
async updateContent(id: number, data: ContentUpdateData): Promise<void>
```

Where `ContentUpdateData` contains: contentHash, contentEncrypted, contentPreview, contentSize, iv, authTag, updatedAt.

SQL equivalent: `UPDATE clipboard_entry SET content_hash=?, content_encrypted=?, content_preview=?, content_size=?, iv=?, auth_tag=?, updated_at=? WHERE id=?`
