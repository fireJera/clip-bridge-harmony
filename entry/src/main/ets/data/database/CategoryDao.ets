import { relationalStore } from '@kit.ArkData';
import { CustomCategory } from '../../model/CustomCategory';
import { ClipboardEntry } from '../../model/ClipboardEntry';

/**
 * Data Access Object for custom_category and entry_category_relation tables.
 * Manages user-defined tag categories and their associations with clipboard entries.
 */
export class CategoryDao {
  private store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  async create(name: string, color: string, sortOrder: number): Promise<number> {
    try {
      const now: string = new Date().toISOString();
      const valueBucket: relationalStore.ValuesBucket = {
        'name': name,
        'color': color || null,
        'sort_order': sortOrder,
        'created_at': now,
        'updated_at': now
      };
      const rowId: number = await this.store.insert('custom_category', valueBucket);
      return rowId;
    } catch (error) {
      throw new Error(`Failed to create category '${name}': ${error}`);
    }
  }

  async getAll(): Promise<CustomCategory[]> {
    try {
      const sql: string =
        'SELECT c.*, COUNT(r.entry_id) AS entry_count ' +
        'FROM custom_category c ' +
        'LEFT JOIN entry_category_relation r ON c.id = r.category_id ' +
        'GROUP BY c.id ' +
        'ORDER BY c.sort_order ASC, c.name ASC';
      const resultSet = await this.store.querySql(sql);
      const categories: CustomCategory[] = [];
      while (resultSet.goToNextRow()) {
        categories.push(this.rowToCategory(resultSet));
      }
      resultSet.close();
      return categories;
    } catch (error) {
      throw new Error(`Failed to get all categories: ${error}`);
    }
  }

  async getById(id: number): Promise<CustomCategory | null> {
    try {
      const predicates = new relationalStore.RdbPredicates('custom_category');
      predicates.equalTo('id', id);
      const resultSet = await this.store.query(predicates);
      if (resultSet.goToFirstRow()) {
        const category: CustomCategory = this.rowToCategory(resultSet);
        resultSet.close();
        return category;
      }
      resultSet.close();
      return null;
    } catch (error) {
      throw new Error(`Failed to get category by id ${id}: ${error}`);
    }
  }

  async update(id: number, name: string, color: string): Promise<void> {
    try {
      const now: string = new Date().toISOString();
      const valueBucket: relationalStore.ValuesBucket = {
        'name': name,
        'color': color || null,
        'updated_at': now
      };
      const predicates = new relationalStore.RdbPredicates('custom_category');
      predicates.equalTo('id', id);
      await this.store.update(valueBucket, predicates);
    } catch (error) {
      throw new Error(`Failed to update category ${id}: ${error}`);
    }
  }

  async delete(id: number): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates('custom_category');
      predicates.equalTo('id', id);
      await this.store.delete(predicates);
    } catch (error) {
      throw new Error(`Failed to delete category ${id}: ${error}`);
    }
  }

  async count(): Promise<number> {
    try {
      const resultSet = await this.store.querySql(
        'SELECT COUNT(*) AS cnt FROM custom_category'
      );
      let count: number = 0;
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(0);
      }
      resultSet.close();
      return count;
    } catch (error) {
      throw new Error(`Failed to count categories: ${error}`);
    }
  }

  async addTag(entryId: number, categoryId: number): Promise<void> {
    try {
      const now: string = new Date().toISOString();
      const valueBucket: relationalStore.ValuesBucket = {
        'entry_id': entryId,
        'category_id': categoryId,
        'created_at': now
      };
      await this.store.insert('entry_category_relation', valueBucket);
    } catch (error) {
      throw new Error(`Failed to add tag (entry=${entryId}, category=${categoryId}): ${error}`);
    }
  }

  async removeTag(entryId: number, categoryId: number): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates('entry_category_relation');
      predicates.equalTo('entry_id', entryId);
      predicates.equalTo('category_id', categoryId);
      await this.store.delete(predicates);
    } catch (error) {
      throw new Error(`Failed to remove tag (entry=${entryId}, category=${categoryId}): ${error}`);
    }
  }

  async getEntriesByCategory(categoryId: number, offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      const sql: string =
        'SELECT e.* FROM clipboard_entry e ' +
        'INNER JOIN entry_category_relation r ON e.id = r.entry_id ' +
        'WHERE r.category_id = ? ' +
        'ORDER BY e.updated_at DESC LIMIT ? OFFSET ?';
      const resultSet = await this.store.querySql(sql, [categoryId, limit, offset]);
      const entries: ClipboardEntry[] = [];
      while (resultSet.goToNextRow()) {
        entries.push(this.rowToEntry(resultSet));
      }
      resultSet.close();
      return entries;
    } catch (error) {
      throw new Error(`Failed to get entries for category ${categoryId}: ${error}`);
    }
  }

  async getEntryIdsInAnyFolder(offset: number, limit: number): Promise<number[]> {
    try {
      const sql: string =
        'SELECT DISTINCT ecr.entry_id FROM entry_category_relation ecr ' +
        'INNER JOIN clipboard_entry ce ON ce.id = ecr.entry_id ' +
        'ORDER BY ce.updated_at DESC LIMIT ? OFFSET ?';
      const resultSet = await this.store.querySql(sql, [limit, offset]);
      const ids: number[] = [];
      while (resultSet.goToNextRow()) {
        ids.push(resultSet.getLong(0));
      }
      resultSet.close();
      return ids;
    } catch (error) {
      throw new Error(`Failed to get entry ids in any folder: ${error}`);
    }
  }

  async getEntriesInAnyFolder(offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      const sql: string =
        'SELECT DISTINCT e.* FROM clipboard_entry e ' +
        'INNER JOIN entry_category_relation r ON e.id = r.entry_id ' +
        'ORDER BY e.updated_at DESC LIMIT ? OFFSET ?';
      const resultSet = await this.store.querySql(sql, [limit, offset]);
      const entries: ClipboardEntry[] = [];
      while (resultSet.goToNextRow()) {
        entries.push(this.rowToEntry(resultSet));
      }
      resultSet.close();
      return entries;
    } catch (error) {
      throw new Error(`Failed to get entries in any folder: ${error}`);
    }
  }

  async countEntriesInAnyFolder(): Promise<number> {
    try {
      const resultSet = await this.store.querySql(
        'SELECT COUNT(DISTINCT entry_id) AS cnt FROM entry_category_relation'
      );
      let count: number = 0;
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(0);
      }
      resultSet.close();
      return count;
    } catch (error) {
      throw new Error(`Failed to count entries in any folder: ${error}`);
    }
  }

  async deleteAllRelations(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates('entry_category_relation');
      await this.store.delete(predicates);
    } catch (error) {
      throw new Error(`Failed to delete all relations: ${error}`);
    }
  }

  async getTagsForEntry(entryId: number): Promise<CustomCategory[]> {
    try {
      const sql: string =
        'SELECT c.* FROM custom_category c ' +
        'INNER JOIN entry_category_relation r ON c.id = r.category_id ' +
        'WHERE r.entry_id = ? ' +
        'ORDER BY c.sort_order, c.name';
      const resultSet = await this.store.querySql(sql, [entryId]);
      const categories: CustomCategory[] = [];
      while (resultSet.goToNextRow()) {
        categories.push(this.rowToCategory(resultSet));
      }
      resultSet.close();
      return categories;
    } catch (error) {
      throw new Error(`Failed to get tags for entry ${entryId}: ${error}`);
    }
  }

  private rowToCategory(resultSet: relationalStore.ResultSet): CustomCategory {
    const category = new CustomCategory();

    const idIndex: number = resultSet.getColumnIndex('id');
    const nameIndex: number = resultSet.getColumnIndex('name');
    const colorIndex: number = resultSet.getColumnIndex('color');
    const sortOrderIndex: number = resultSet.getColumnIndex('sort_order');
    const createdAtIndex: number = resultSet.getColumnIndex('created_at');
    const updatedAtIndex: number = resultSet.getColumnIndex('updated_at');
    const entryCountIndex: number = resultSet.getColumnIndex('entry_count');

    category.id = resultSet.getLong(idIndex);
    category.name = resultSet.getString(nameIndex);
    category.color = resultSet.getString(colorIndex);
    category.sortOrder = resultSet.getLong(sortOrderIndex);
    category.createdAt = resultSet.getString(createdAtIndex);
    category.updatedAt = resultSet.getString(updatedAtIndex);
    category.entryCount = entryCountIndex >= 0 ? resultSet.getLong(entryCountIndex) : 0;

    return category;
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

    return entry;
  }
}
