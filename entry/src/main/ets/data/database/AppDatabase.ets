import { relationalStore } from '@kit.ArkData';

/**
 * Singleton database manager for Clip Bridge.
 * Initializes an encrypted SQLite database and creates all tables on first run.
 */
export class AppDatabase {
  private static instance: AppDatabase | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private static readonly DB_NAME: string = 'clipbridge.db';
  private static readonly DB_CONFIG: relationalStore.StoreConfig = {
    name: AppDatabase.DB_NAME,
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  };

  private constructor() {}

  static async getInstance(context: Context): Promise<AppDatabase> {
    if (!AppDatabase.instance) {
      AppDatabase.instance = new AppDatabase();
      await AppDatabase.instance.init(context);
    }
    return AppDatabase.instance;
  }

  private async init(context: Context): Promise<void> {
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, AppDatabase.DB_CONFIG);
      await this.createTables();
    } catch (error) {
      throw new Error(`Failed to initialize database: ${error}`);
    }
  }

  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('Database store is not initialized');
    }

    const createClipboardEntry: string = `
      CREATE TABLE IF NOT EXISTS clipboard_entry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_hash TEXT NOT NULL UNIQUE,
        content_encrypted BLOB NOT NULL,
        content_type TEXT NOT NULL,
        content_preview TEXT NOT NULL,
        image_path TEXT,
        thumbnail_path TEXT,
        content_size INTEGER NOT NULL,
        source_app TEXT,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        pinned_at TEXT,
        favorited_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        iv BLOB NOT NULL,
        auth_tag BLOB NOT NULL,
        note TEXT
      )`;

    const createCustomCategory: string = `
      CREATE TABLE IF NOT EXISTS custom_category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )`;

    const createEntryCategoryRelation: string = `
      CREATE TABLE IF NOT EXISTS entry_category_relation (
        entry_id INTEGER NOT NULL REFERENCES clipboard_entry(id) ON DELETE CASCADE,
        category_id INTEGER NOT NULL REFERENCES custom_category(id) ON DELETE CASCADE,
        created_at TEXT NOT NULL,
        PRIMARY KEY (entry_id, category_id)
      )`;

    await this.rdbStore.executeSql(createClipboardEntry);
    await this.rdbStore.executeSql(createCustomCategory);
    await this.rdbStore.executeSql(createEntryCategoryRelation);

    await this.createIndexes();
    await this.runMigrations();
  }

  private async runMigrations(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    // Migration: add note column (idempotent — ignore error if column exists)
    try {
      await this.rdbStore.executeSql('ALTER TABLE clipboard_entry ADD COLUMN note TEXT');
    } catch (e) {
      // Column already exists, ignore
    }
  }

  private async createIndexes(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('Database store is not initialized');
    }

    const indexes: string[] = [
      'CREATE INDEX IF NOT EXISTS idx_entry_hash ON clipboard_entry(content_hash)',
      'CREATE INDEX IF NOT EXISTS idx_entry_updated ON clipboard_entry(updated_at DESC)',
      'CREATE INDEX IF NOT EXISTS idx_entry_type ON clipboard_entry(content_type)',
      'CREATE INDEX IF NOT EXISTS idx_entry_favorite ON clipboard_entry(is_favorite, favorited_at DESC)',
      'CREATE INDEX IF NOT EXISTS idx_entry_pinned ON clipboard_entry(is_pinned, pinned_at DESC)'
    ];

    for (const indexSql of indexes) {
      await this.rdbStore.executeSql(indexSql);
    }
  }

  getStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('Database not initialized. Call getInstance() first.');
    }
    return this.rdbStore;
  }
}
