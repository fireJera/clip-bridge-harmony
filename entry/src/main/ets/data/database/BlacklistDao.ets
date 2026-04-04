import { relationalStore } from '@kit.ArkData';
import { AppBlacklistEntry } from '../../model/AppBlacklistEntry';

/**
 * Data Access Object for app_blacklist_entry table.
 * Manages apps excluded from clipboard monitoring.
 */
export class BlacklistDao {
  private store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  async insert(bundleName: string, appName: string): Promise<number> {
    try {
      const now: string = new Date().toISOString();
      const valueBucket: relationalStore.ValuesBucket = {
        'bundle_name': bundleName,
        'app_name': appName,
        'created_at': now
      };
      const rowId: number = await this.store.insert('app_blacklist_entry', valueBucket);
      return rowId;
    } catch (error) {
      throw new Error(`Failed to insert blacklist entry for '${bundleName}': ${error}`);
    }
  }

  async getAll(): Promise<AppBlacklistEntry[]> {
    try {
      const predicates = new relationalStore.RdbPredicates('app_blacklist_entry');
      predicates.orderByAsc('app_name');
      const resultSet = await this.store.query(predicates);
      const entries: AppBlacklistEntry[] = [];
      while (resultSet.goToNextRow()) {
        entries.push(this.rowToEntry(resultSet));
      }
      resultSet.close();
      return entries;
    } catch (error) {
      throw new Error(`Failed to get all blacklist entries: ${error}`);
    }
  }

  async deleteById(id: number): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates('app_blacklist_entry');
      predicates.equalTo('id', id);
      await this.store.delete(predicates);
    } catch (error) {
      throw new Error(`Failed to delete blacklist entry ${id}: ${error}`);
    }
  }

  async isBlacklisted(bundleName: string): Promise<boolean> {
    try {
      const predicates = new relationalStore.RdbPredicates('app_blacklist_entry');
      predicates.equalTo('bundle_name', bundleName);
      const resultSet = await this.store.query(predicates, ['id']);
      const exists: boolean = resultSet.goToFirstRow();
      resultSet.close();
      return exists;
    } catch (error) {
      throw new Error(`Failed to check blacklist status for '${bundleName}': ${error}`);
    }
  }

  private rowToEntry(resultSet: relationalStore.ResultSet): AppBlacklistEntry {
    const entry = new AppBlacklistEntry();

    const idIndex: number = resultSet.getColumnIndex('id');
    const bundleNameIndex: number = resultSet.getColumnIndex('bundle_name');
    const appNameIndex: number = resultSet.getColumnIndex('app_name');
    const createdAtIndex: number = resultSet.getColumnIndex('created_at');

    entry.id = resultSet.getLong(idIndex);
    entry.bundleName = resultSet.getString(bundleNameIndex);
    entry.appName = resultSet.getString(appNameIndex);
    entry.createdAt = resultSet.getString(createdAtIndex);

    return entry;
  }
}
