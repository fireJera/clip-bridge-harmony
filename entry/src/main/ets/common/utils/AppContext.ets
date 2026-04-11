import { IClipboardRepository } from '../../repository/ClipboardRepository';
import { ICategoryRepository } from '../../repository/CategoryRepository';
import { ISettingsRepository } from '../../repository/SettingsRepository';
import { EncryptionService } from '../../service/EncryptionService';
import { ImageStorageService } from '../../service/ImageStorageService';
import { ClipboardMonitorService } from '../../service/ClipboardMonitorService';

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
  private static encryptionService: EncryptionService | null = null;
  private static imageStorageService: ImageStorageService | null = null;
  private static monitorService: ClipboardMonitorService | null = null;

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

  static setEncryptionService(service: EncryptionService): void {
    AppContext.encryptionService = service;
  }

  static getEncryptionService(): EncryptionService | null {
    return AppContext.encryptionService;
  }

  static setImageStorageService(service: ImageStorageService): void {
    AppContext.imageStorageService = service;
  }

  static getImageStorageService(): ImageStorageService | null {
    return AppContext.imageStorageService;
  }

  static setMonitorService(service: ClipboardMonitorService): void {
    AppContext.monitorService = service;
  }

  static getMonitorService(): ClipboardMonitorService | null {
    return AppContext.monitorService;
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

  // ── Auth lock (biometric gate) ────────────────────────────────

  private static authLocked: boolean = false;
  private static authLockCallbacks: ((locked: boolean) => void)[] = [];

  static isAuthLocked(): boolean {
    return AppContext.authLocked;
  }

  static setAuthLocked(locked: boolean): void {
    AppContext.authLocked = locked;
    AppContext.authLockCallbacks.forEach((cb: (locked: boolean) => void) => {
      cb(locked);
    });
  }

  static addAuthLockCallback(cb: (locked: boolean) => void): void {
    if (AppContext.authLockCallbacks.indexOf(cb) < 0) {
      AppContext.authLockCallbacks.push(cb);
    }
  }

  static removeAuthLockCallback(cb: (locked: boolean) => void): void {
    const index: number = AppContext.authLockCallbacks.indexOf(cb);
    if (index >= 0) {
      AppContext.authLockCallbacks.splice(index, 1);
    }
  }

  // ── Auth retry (re-trigger biometric prompt from UI) ──────────

  private static authRetryAction: (() => void) | null = null;

  static setAuthRetryAction(action: (() => void) | null): void {
    AppContext.authRetryAction = action;
  }

  static requestAuthRetry(): void {
    if (AppContext.authRetryAction) {
      AppContext.authRetryAction();
    }
  }
}
