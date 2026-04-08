import { IClipboardRepository } from '../../repository/ClipboardRepository';
import { ICategoryRepository } from '../../repository/CategoryRepository';
import { ISettingsRepository } from '../../repository/SettingsRepository';
import { BlacklistDao } from '../../data/database/BlacklistDao';
import { EncryptionService } from '../../service/EncryptionService';

/**
 * Application-wide context holder.
 * Initialized in EntryAbility.onCreate() so that downstream services
 * and UI components can access shared instances.
 */
export class AppContext {
  private static context: Context | null = null;
  private static clipboardRepo: IClipboardRepository | null = null;
  private static categoryRepo: ICategoryRepository | null = null;
  private static settingsRepo: ISettingsRepository | null = null;
  private static blacklistDao: BlacklistDao | null = null;
  private static encryptionService: EncryptionService | null = null;

  static setContext(context: Context): void {
    AppContext.context = context;
  }

  static getContext(): Context {
    if (!AppContext.context) {
      throw new Error('AppContext not initialized. Call AppContext.setContext() in EntryAbility.onCreate() first.');
    }
    return AppContext.context;
  }

  static setClipboardRepo(repo: IClipboardRepository): void {
    AppContext.clipboardRepo = repo;
  }

  static getClipboardRepo(): IClipboardRepository | null {
    return AppContext.clipboardRepo;
  }

  static setCategoryRepo(repo: ICategoryRepository): void {
    AppContext.categoryRepo = repo;
  }

  static getCategoryRepo(): ICategoryRepository | null {
    return AppContext.categoryRepo;
  }

  static setSettingsRepo(repo: ISettingsRepository): void {
    AppContext.settingsRepo = repo;
  }

  static getSettingsRepo(): ISettingsRepository | null {
    return AppContext.settingsRepo;
  }

  static setBlacklistDao(dao: BlacklistDao): void {
    AppContext.blacklistDao = dao;
  }

  static getBlacklistDao(): BlacklistDao | null {
    return AppContext.blacklistDao;
  }

  static setEncryptionService(service: EncryptionService): void {
    AppContext.encryptionService = service;
  }

  static getEncryptionService(): EncryptionService | null {
    return AppContext.encryptionService;
  }

  // ── UI refresh callbacks ──────────────────────────────────────

  private static refreshCallbacks: (() => void)[] = [];

  static addRefreshCallback(cb: () => void): void {
    if (AppContext.refreshCallbacks.indexOf(cb) < 0) {
      AppContext.refreshCallbacks.push(cb);
    }
  }

  static removeRefreshCallback(cb: () => void): void {
    const index: number = AppContext.refreshCallbacks.indexOf(cb);
    if (index >= 0) {
      AppContext.refreshCallbacks.splice(index, 1);
    }
  }

  /**
   * Called after a new clipboard entry is saved, so the UI can reload.
   */
  static notifyDataChanged(): void {
    AppContext.refreshCallbacks.forEach((cb: () => void) => {
      cb();
    });
  }
}
