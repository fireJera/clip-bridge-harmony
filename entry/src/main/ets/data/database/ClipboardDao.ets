import { relationalStore } from '@kit.ArkData';
import { ClipboardEntry } from '../../model/ClipboardEntry';

/**
 * Data class for updating content-related fields of a clipboard entry.
 */
export class ContentUpdateData {
  contentHash: string = '';
  contentEncrypted: Uint8Array = new Uint8Array(0);
  contentPreview: string = '';
  contentSize: number = 0;
  iv: Uint8Array = new Uint8Array(0);
  authTag: Uint8Array = new Uint8Array(0);
  updatedAt: string = '';
}

/**
 * Data Access Object for clipboard_entry table.
 * Provides all CRUD operations and query methods for clipboard history management.
 */
export class ClipboardDao {
  private store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  async insert(entry: ClipboardEntry): Promise<number> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'content_hash': entry.contentHash,
        'content_encrypted': entry.contentEncrypted,
        'content_type': entry.contentType,
        'content_preview': entry.contentPreview,
        'image_path': entry.imagePath || null,
        'thumbnail_path': entry.thumbnailPath || null,
        'content_size': entry.contentSize,
        'source_app': entry.sourceApp || null,
        'is_pinned': entry.isPinned ? 1 : 0,
        'is_favorite': entry.isFavorite ? 1 : 0,
        'pinned_at': entry.pinnedAt || null,
        'favorited_at': entry.favoritedAt || null,
        'created_at': entry.createdAt,
        'updated_at': entry.updatedAt,
        'iv': entry.iv,
        'auth_tag': entry.authTag,
        'note': entry.note || null
      };
      const rowId: number = await this.store.insert('clipboard_entry', valueBucket);
      return rowId;
    } catch (error) {
      throw new Error(`Failed to insert clipboard entry: ${error}`);
    }
  }

  async getById(id: number): Promise<ClipboardEntry | null> {
    try {
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.equalTo('id', id);
      const resultSet = await this.store.query(predicates);
      if (resultSet.goToFirstRow()) {
        const entry: ClipboardEntry = this.rowToEntry(resultSet);
        resultSet.close();
        return entry;
      }
      resultSet.close();
      return null;
    } catch (error) {
      throw new Error(`Failed to get clipboard entry by id ${id}: ${error}`);
    }
  }

  async getHistory(offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.orderByDesc('is_pinned');
      predicates.orderByDesc('updated_at');
      predicates.limitAs(limit);
      predicates.offsetAs(offset);
      return await this.queryEntries(predicates);
    } catch (error) {
      throw new Error(`Failed to get clipboard history: ${error}`);
    }
  }

  async getByType(type: string, offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.equalTo('content_type', type);
      predicates.orderByDesc('updated_at');
      predicates.limitAs(limit);
      predicates.offsetAs(offset);
      return await this.queryEntries(predicates);
    } catch (error) {
      throw new Error(`Failed to get clipboard entries by type '${type}': ${error}`);
    }
  }

  async getFavorites(offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.equalTo('is_favorite', 1);
      predicates.orderByDesc('favorited_at');
      predicates.limitAs(limit);
      predicates.offsetAs(offset);
      return await this.queryEntries(predicates);
    } catch (error) {
      throw new Error(`Failed to get favorite clipboard entries: ${error}`);
    }
  }

  async search(keyword: string, offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.like('content_preview', `%${keyword}%`);
      predicates.orderByDesc('updated_at');
      predicates.limitAs(limit);
      predicates.offsetAs(offset);
      return await this.queryEntries(predicates);
    } catch (error) {
      throw new Error(`Failed to search clipboard entries with keyword '${keyword}': ${error}`);
    }
  }

  async count(): Promise<number> {
    try {
      const resultSet = await this.store.querySql(
        'SELECT COUNT(*) AS cnt FROM clipboard_entry'
      );
      let count: number = 0;
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(0);
      }
      resultSet.close();
      return count;
    } catch (error) {
      throw new Error(`Failed to count clipboard entries: ${error}`);
    }
  }

  async findByHash(contentHash: string): Promise<ClipboardEntry | null> {
    try {
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.equalTo('content_hash', contentHash);
      const resultSet = await this.store.query(predicates);
      if (resultSet.goToFirstRow()) {
        const entry: ClipboardEntry = this.rowToEntry(resultSet);
        resultSet.close();
        return entry;
      }
      resultSet.close();
      return null;
    } catch (error) {
      throw new Error(`Failed to find clipboard entry by hash '${contentHash}': ${error}`);
    }
  }

  async touchTimestamp(id: number): Promise<void> {
    try {
      const now: string = new Date().toISOString();
      const valueBucket: relationalStore.ValuesBucket = {
        'updated_at': now
      };
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.equalTo('id', id);
      await this.store.update(valueBucket, predicates);
    } catch (error) {
      throw new Error(`Failed to update timestamp for entry ${id}: ${error}`);
    }
  }

  async updatePin(id: number, pinned: boolean): Promise<void> {
    try {
      const now: string = new Date().toISOString();
      const valueBucket: relationalStore.ValuesBucket = {
        'is_pinned': pinned ? 1 : 0,
        'pinned_at': pinned ? now : null
      };
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.equalTo('id', id);
      await this.store.update(valueBucket, predicates);
    } catch (error) {
      throw new Error(`Failed to update pin status for entry ${id}: ${error}`);
    }
  }

  async updateFavorite(id: number, favorited: boolean): Promise<void> {
    try {
      const now: string = new Date().toISOString();
      const valueBucket: relationalStore.ValuesBucket = {
        'is_favorite': favorited ? 1 : 0,
        'favorited_at': favorited ? now : null
      };
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.equalTo('id', id);
      await this.store.update(valueBucket, predicates);
    } catch (error) {
      throw new Error(`Failed to update favorite status for entry ${id}: ${error}`);
    }
  }

  async updateContent(id: number, data: ContentUpdateData): Promise<void> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'content_hash': data.contentHash,
        'content_encrypted': data.contentEncrypted,
        'content_preview': data.contentPreview,
        'content_size': data.contentSize,
        'iv': data.iv,
        'auth_tag': data.authTag,
        'updated_at': data.updatedAt
      };
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.equalTo('id', id);
      await this.store.update(valueBucket, predicates);
    } catch (error) {
      throw new Error(`Failed to update content for entry ${id}: ${error}`);
    }
  }

  async updateNote(id: number, note: string): Promise<void> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'note': note || null,
        'updated_at': new Date().toISOString()
      };
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.equalTo('id', id);
      await this.store.update(valueBucket, predicates);
    } catch (error) {
      throw new Error(`Failed to update note for entry ${id}: ${error}`);
    }
  }

  async deleteById(id: number): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.equalTo('id', id);
      await this.store.delete(predicates);
    } catch (error) {
      throw new Error(`Failed to delete clipboard entry ${id}: ${error}`);
    }
  }

  async deleteByIds(ids: number[]): Promise<void> {
    if (ids.length === 0) {
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.in('id', ids);
      await this.store.delete(predicates);
    } catch (error) {
      throw new Error(`Failed to delete clipboard entries by ids: ${error}`);
    }
  }

  async deleteAll(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      await this.store.delete(predicates);
    } catch (error) {
      throw new Error(`Failed to delete all clipboard entries: ${error}`);
    }
  }

  async countFavorites(): Promise<number> {
    try {
      const resultSet = await this.store.querySql(
        'SELECT COUNT(*) AS cnt FROM clipboard_entry WHERE is_favorite = 1'
      );
      let count: number = 0;
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(0);
      }
      resultSet.close();
      return count;
    } catch (error) {
      throw new Error(`Failed to count favorite clipboard entries: ${error}`);
    }
  }

  async pruneOldest(count: number): Promise<number> {
    try {
      const resultSet = await this.store.querySql(
        'SELECT id FROM clipboard_entry WHERE is_pinned = 0 AND is_favorite = 0 ORDER BY updated_at ASC LIMIT ?',
        [count]
      );
      const idsToDelete: number[] = [];
      while (resultSet.goToNextRow()) {
        idsToDelete.push(resultSet.getLong(0));
      }
      resultSet.close();

      if (idsToDelete.length === 0) {
        return 0;
      }

      const predicates = new relationalStore.RdbPredicates('clipboard_entry');
      predicates.in('id', idsToDelete);
      const deletedRows: number = await this.store.delete(predicates);
      return deletedRows;
    } catch (error) {
      throw new Error(`Failed to prune oldest clipboard entries: ${error}`);
    }
  }

  private async queryEntries(predicates: relationalStore.RdbPredicates): Promise<ClipboardEntry[]> {
    const resultSet = await this.store.query(predicates);
    const entries: ClipboardEntry[] = [];
    while (resultSet.goToNextRow()) {
      entries.push(this.rowToEntry(resultSet));
    }
    resultSet.close();
    return entries;
  }

  private rowToEntry(resultSet: relationalStore.ResultSet): ClipboardEntry {
    const entry = new ClipboardEntry();

    const idIndex: number = resultSet.getColumnIndex('id');
    const contentHashIndex: number = resultSet.getColumnIndex('content_hash');
    const contentEncryptedIndex: number = resultSet.getColumnIndex('content_encrypted');
    const contentTypeIndex: number = resultSet.getColumnIndex('content_type');
    const contentPreviewIndex: number = resultSet.getColumnIndex('content_preview');
    const imagePathIndex: number = resultSet.getColumnIndex('image_path');
    const thumbnailPathIndex: number = resultSet.getColumnIndex('thumbnail_path');
    const contentSizeIndex: number = resultSet.getColumnIndex('content_size');
    const sourceAppIndex: number = resultSet.getColumnIndex('source_app');
    const isPinnedIndex: number = resultSet.getColumnIndex('is_pinned');
    const isFavoriteIndex: number = resultSet.getColumnIndex('is_favorite');
    const pinnedAtIndex: number = resultSet.getColumnIndex('pinned_at');
    const favoritedAtIndex: number = resultSet.getColumnIndex('favorited_at');
    const createdAtIndex: number = resultSet.getColumnIndex('created_at');
    const updatedAtIndex: number = resultSet.getColumnIndex('updated_at');
    const ivIndex: number = resultSet.getColumnIndex('iv');
    const authTagIndex: number = resultSet.getColumnIndex('auth_tag');

    entry.id = resultSet.getLong(idIndex);
    entry.contentHash = resultSet.getString(contentHashIndex);
    entry.contentEncrypted = resultSet.getBlob(contentEncryptedIndex);
    entry.contentType = resultSet.getString(contentTypeIndex);
    entry.contentPreview = resultSet.getString(contentPreviewIndex);
    entry.imagePath = resultSet.getString(imagePathIndex);
    entry.thumbnailPath = resultSet.getString(thumbnailPathIndex);
    entry.contentSize = resultSet.getLong(contentSizeIndex);
    entry.sourceApp = resultSet.getString(sourceAppIndex);
    entry.isPinned = resultSet.getLong(isPinnedIndex) === 1;
    entry.isFavorite = resultSet.getLong(isFavoriteIndex) === 1;
    entry.pinnedAt = resultSet.getString(pinnedAtIndex);
    entry.favoritedAt = resultSet.getString(favoritedAtIndex);
    entry.createdAt = resultSet.getString(createdAtIndex);
    entry.updatedAt = resultSet.getString(updatedAtIndex);
    entry.iv = resultSet.getBlob(ivIndex);
    entry.authTag = resultSet.getBlob(authTagIndex);

    // note column added via migration — may not exist on older databases
    try {
      const noteIndex: number = resultSet.getColumnIndex('note');
      entry.note = resultSet.getString(noteIndex) ?? '';
    } catch (e) {
      entry.note = '';
    }

    return entry;
  }
}
