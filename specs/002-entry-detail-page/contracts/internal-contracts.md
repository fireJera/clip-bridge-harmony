# Internal Contracts: Entry Detail Page

**Branch**: `002-entry-detail-page` | **Date**: 2026-04-08

This feature has no external API contracts. All contracts are internal — method signatures within the existing codebase.

## Repository Contract

### IClipboardRepository — New Method

```typescript
/**
 * Updates the content of an existing clipboard entry.
 * Re-encrypts the new content and updates all related fields:
 * contentHash, contentEncrypted, contentPreview, contentSize, iv, authTag, updatedAt.
 *
 * @param id - The database ID of the entry to update.
 * @param newContent - The new plain-text content.
 * @throws Error if entry not found or encryption fails.
 */
updateContent(id: number, newContent: string): Promise<void>;
```

### ICategoryRepository — Existing Methods Used

```typescript
getTagsForEntry(entryId: number): Promise<CustomCategory[]>;
addTag(entryId: number, categoryId: number): Promise<void>;
removeTag(entryId: number, categoryId: number): Promise<void>;
getAll(): Promise<CustomCategory[]>;
```

## ViewModel Contract

### DetailViewModel — New/Modified Methods

```typescript
/**
 * Saves the edited content. Re-encrypts and persists to database.
 * Resets isDirty flag and refreshes local entry state.
 * Calls AppContext.notifyDataChanged() to refresh other pages.
 *
 * @throws Error if no entry loaded or save fails.
 */
async saveContent(): Promise<void>;

/**
 * Reverts edited content back to the last saved state.
 */
revertContent(): void;

/**
 * Returns true if the edited content differs from the saved content.
 */
isEntryDirty(): boolean;

/**
 * Updates editedContent and recalculates isDirty.
 * Called on every TextArea text change.
 */
onContentEdited(newText: string): void;

/**
 * Deletes the entry and notifies other pages.
 * @returns true if deletion succeeded.
 */
async deleteEntry(): Promise<boolean>;
```

### DetailViewModel — New State Properties

```typescript
@Trace editedContent: string = '';      // Current editor text
@Trace isDirty: boolean = false;        // editedContent !== decryptedContent
@Trace isSaving: boolean = false;       // Save in progress
@Trace isNotFound: boolean = false;     // Entry was deleted externally
```

## Navigation Contract

### Navigation Parameter

When navigating to DetailPage, pass:

```typescript
// Via Navigation.pushPath or similar
{ entryId: number }
```

### Back Navigation

- Clean exit (no unsaved changes): Pop nav stack normally.
- Dirty exit (unsaved changes): Show confirmation dialog → pop on confirm, stay on cancel.
- After delete: Pop nav stack (entry removed from lists automatically via AppContext.notifyDataChanged).

## Event Contract

### AppContext.notifyDataChanged()

Called after:
- `saveContent()` succeeds
- `deleteEntry()` succeeds
- `toggleFavorite()` succeeds
- `togglePin()` succeeds

This triggers refresh callbacks in HistoryPage and FavoritesPage to update their lists.
