# Internal Contracts: Clip Bridge v1

**Date**: 2026-04-05
**Note**: v1 is a local-only app with no external API. These contracts define internal
layer boundaries for testability and v2 extensibility.

## Repository Contracts

### ClipboardRepository

```typescript
interface ClipboardRepository {
  // Create
  insert(entry: ClipboardEntry): Promise<number>;          // Returns inserted ID

  // Read
  getById(id: number): Promise<ClipboardEntry | null>;
  getHistory(offset: number, limit: number): Promise<ClipboardEntry[]>;
  getByType(type: ContentType, offset: number, limit: number): Promise<ClipboardEntry[]>;
  getFavorites(offset: number, limit: number): Promise<ClipboardEntry[]>;
  search(keyword: string, offset: number, limit: number): Promise<ClipboardEntry[]>;
  count(): Promise<number>;

  // Dedup
  findByHash(contentHash: string): Promise<ClipboardEntry | null>;
  touchTimestamp(id: number): Promise<void>;               // Update updated_at to now

  // Update
  updatePin(id: number, pinned: boolean): Promise<void>;
  updateFavorite(id: number, favorited: boolean): Promise<void>;

  // Delete
  deleteById(id: number): Promise<void>;
  deleteByIds(ids: number[]): Promise<void>;
  deleteAll(): Promise<void>;
  pruneOldest(count: number): Promise<number>;             // Returns deleted count
}
```

### CategoryRepository

```typescript
interface CategoryRepository {
  create(name: string, color?: string): Promise<number>;
  getAll(): Promise<CustomCategory[]>;
  getById(id: number): Promise<CustomCategory | null>;
  update(id: number, name: string, color?: string): Promise<void>;
  delete(id: number): Promise<void>;                       // Cascades to relations
  count(): Promise<number>;

  // Entry-Category relations
  addTag(entryId: number, categoryId: number): Promise<void>;
  removeTag(entryId: number, categoryId: number): Promise<void>;
  getEntriesByCategory(categoryId: number, offset: number, limit: number): Promise<ClipboardEntry[]>;
  getTagsForEntry(entryId: number): Promise<CustomCategory[]>;
}
```

### SettingsRepository

```typescript
interface SettingsRepository {
  getHistoryLimit(): Promise<number>;
  setHistoryLimit(limit: number): Promise<void>;
  isPrivacyMode(): Promise<boolean>;
  setPrivacyMode(enabled: boolean, until?: string): Promise<void>;
  isBiometricEnabled(): Promise<boolean>;
  setBiometricEnabled(enabled: boolean): Promise<void>;
}
```

## Service Contracts

### ClipboardMonitorService

```typescript
interface ClipboardMonitorService {
  start(): void;               // Register pasteboard listener + continuous task
  stop(): void;                // Unregister + stop continuous task
  isRunning(): boolean;
  onCapture: Callback<ClipboardEntry>;  // Emitted on new capture
}
```

### ContentTypeDetector

```typescript
type ContentType = 'text' | 'url' | 'email' | 'phone' | 'image' | 'address';

interface ContentTypeDetector {
  detect(content: string, mimeType: string): ContentType;
}
```

### DeduplicationService

```typescript
interface DeduplicationService {
  // Returns existing entry if duplicate found, null otherwise
  checkDuplicate(contentHash: string): Promise<ClipboardEntry | null>;
  // Promote existing entry to top (update timestamp)
  promoteToTop(id: number): Promise<void>;
}
```

### EncryptionService

```typescript
interface EncryptionService {
  encrypt(plaintext: string): Promise<EncryptedData>;
  decrypt(encrypted: EncryptedData): Promise<string>;
  hash(content: string): string;              // SHA-256, synchronous
}

interface EncryptedData {
  ciphertext: Uint8Array;
  iv: Uint8Array;
  authTag: Uint8Array;
}
```

## v2 Extension Points

These interfaces are reserved for v2 but NOT implemented:

```typescript
// v2: User authentication
interface AuthService {
  login(phone: string, code: string): Promise<UserProfile>;
  logout(): Promise<void>;
  isLoggedIn(): boolean;
}

// v2: Unified sync engine
interface SyncEngine {
  start(): void;
  stop(): void;
  getSyncStatus(entryId: number): SyncStatus;
}
```
