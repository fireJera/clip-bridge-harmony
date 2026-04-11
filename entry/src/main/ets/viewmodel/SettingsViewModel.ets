import { ISettingsRepository } from '../repository/SettingsRepository';
import { IClipboardRepository } from '../repository/ClipboardRepository';
import { ICategoryRepository } from '../repository/CategoryRepository';
import { CustomCategory } from '../model/CustomCategory';
import { AppConstants } from '../common/constants/AppConstants';
import { AppContext } from '../common/utils/AppContext';

/**
 * ViewModel for the Settings page.
 *
 * Reactive state (@Trace) is used for each setting so the UI updates
 * automatically when values change. The ViewModel loads settings on init
 * and delegates persistence to ISettingsRepository.
 */
@ObservedV2
export class SettingsViewModel {
  private settingsRepo: ISettingsRepository;
  private clipboardRepo: IClipboardRepository;
  private categoryRepo: ICategoryRepository;

  @Trace historyLimit: number = AppConstants.DEFAULT_HISTORY_LIMIT;
  @Trace isPrivacyMode: boolean = false;
  @Trace isBiometricEnabled: boolean = false;
  @Trace categories: CustomCategory[] = [];
  @Trace appVersion: string = '1.0.0';
  @Trace isLoading: boolean = false;

  constructor(
    settingsRepo: ISettingsRepository,
    clipboardRepo: IClipboardRepository,
    categoryRepo: ICategoryRepository
  ) {
    this.settingsRepo = settingsRepo;
    this.clipboardRepo = clipboardRepo;
    this.categoryRepo = categoryRepo;
  }

  /**
   * Loads all settings from persistent storage.
   */
  async loadSettings(): Promise<void> {
    this.isLoading = true;
    try {
      this.historyLimit = await this.settingsRepo.getHistoryLimit();
      this.isPrivacyMode = await this.settingsRepo.isPrivacyMode();
      this.isBiometricEnabled = await this.settingsRepo.isBiometricEnabled();
    } catch (error) {
      console.error('[SettingsViewModel] Failed to load settings: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Updates the history limit. Clamps the value to the allowed range.
   *
   * @param limit - New history limit value.
   */
  async updateHistoryLimit(limit: number): Promise<void> {
    const clamped: number = Math.max(
      AppConstants.MIN_HISTORY_LIMIT,
      Math.min(AppConstants.MAX_HISTORY_LIMIT, limit)
    );
    this.historyLimit = clamped;
    try {
      await this.settingsRepo.setHistoryLimit(clamped);
    } catch (error) {
      console.error('[SettingsViewModel] Failed to update history limit: ' + JSON.stringify(error));
    }
  }

  /**
   * Sets privacy mode to the specified value.
   */
  async setPrivacyMode(enabled: boolean): Promise<void> {
    this.isPrivacyMode = enabled;
    try {
      await this.settingsRepo.setPrivacyMode(enabled);
      // Immediately pause/resume clipboard monitoring to match the setting
      const monitorService = AppContext.getMonitorService();
      if (monitorService) {
        if (enabled) {
          await monitorService.pauseMonitoring();
        } else {
          await monitorService.resumeMonitoring();
        }
      }
    } catch (error) {
      console.error('[SettingsViewModel] Failed to set privacy mode: ' + JSON.stringify(error));
    }
  }

  /**
   * Sets biometric authentication on or off.
   */
  async setBiometricEnabled(enabled: boolean): Promise<void> {
    this.isBiometricEnabled = enabled;
    try {
      await this.settingsRepo.setBiometricEnabled(enabled);
    } catch (error) {
      console.error('[SettingsViewModel] Failed to set biometric: ' + JSON.stringify(error));
    }
  }

  /**
   * Deletes all clipboard data and resets history.
   */
  async clearAllData(): Promise<void> {
    try {
      await this.clipboardRepo.deleteAll();
    } catch (error) {
      console.error('[SettingsViewModel] Failed to clear all data: ' + JSON.stringify(error));
    }
  }

  // ── Category management ─────────────────────────────────────────────

  /**
   * Loads all custom categories from the repository.
   */
  async loadCategories(): Promise<void> {
    try {
      this.categories = await this.categoryRepo.getAll();
    } catch (error) {
      console.error('[SettingsViewModel] Failed to load categories: ' + JSON.stringify(error));
    }
  }

  /**
   * Creates a new custom category. Enforces the 50-category limit.
   *
   * @param name - Display name of the category.
   * @param color - Optional hex color string.
   */
  async createCategory(name: string, color?: string): Promise<void> {
    try {
      const currentCount: number = await this.categoryRepo.count();
      if (currentCount >= AppConstants.MAX_CATEGORIES) {
        console.error('[SettingsViewModel] Maximum categories limit reached');
        return;
      }
      await this.categoryRepo.create(name, color);
      await this.loadCategories();
      AppContext.notifyDataChanged();
    } catch (error) {
      console.error('[SettingsViewModel] Failed to create category: ' + JSON.stringify(error));
    }
  }

  /**
   * Renames an existing custom category.
   *
   * @param id - Category ID to rename.
   * @param name - New display name.
   */
  async renameCategory(id: number, name: string): Promise<void> {
    try {
      const cat: CustomCategory | null = await this.categoryRepo.getById(id);
      if (cat) {
        await this.categoryRepo.update(id, name, cat.color);
        await this.loadCategories();
        AppContext.notifyDataChanged();
      }
    } catch (error) {
      console.error('[SettingsViewModel] Failed to rename category: ' + JSON.stringify(error));
    }
  }

  /**
   * Deletes a custom category.
   *
   * @param id - Category ID to delete.
   */
  async deleteCategory(id: number): Promise<void> {
    try {
      await this.categoryRepo.delete(id);
      await this.loadCategories();
      AppContext.notifyDataChanged();
    } catch (error) {
      console.error('[SettingsViewModel] Failed to delete category: ' + JSON.stringify(error));
    }
  }
}
