import { preferences } from '@kit.ArkData';
import { AppConstants } from '../../common/constants/AppConstants';

/**
 * User settings stored as key-value pairs via @ohos.data.preferences.
 * Singleton pattern ensures a single preferences instance throughout the app.
 */
export class UserSettings {
  private static readonly PREF_NAME: string = 'clipbridge_settings';

  // Preference keys
  private static readonly KEY_HISTORY_LIMIT: string = 'history_limit';
  private static readonly KEY_PRIVACY_MODE: string = 'privacy_mode';
  private static readonly KEY_PRIVACY_MODE_UNTIL: string = 'privacy_mode_until';
  private static readonly KEY_BIOMETRIC_ENABLED: string = 'biometric_enabled';
  private static readonly KEY_TEXT_SIZE_LIMIT: string = 'text_size_limit';
  private static readonly KEY_IMAGE_SIZE_LIMIT: string = 'image_size_limit';

  private static instance: UserSettings | null = null;
  private prefs: preferences.Preferences | null = null;

  private constructor() {}

  static async getInstance(context: Context): Promise<UserSettings> {
    if (!UserSettings.instance) {
      UserSettings.instance = new UserSettings();
      await UserSettings.instance.init(context);
    }
    return UserSettings.instance;
  }

  async init(context: Context): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(context, UserSettings.PREF_NAME);
    } catch (error) {
      throw new Error(`Failed to initialize user settings: ${error}`);
    }
  }

  private getPrefs(): preferences.Preferences {
    if (!this.prefs) {
      throw new Error('UserSettings not initialized. Call getInstance() first.');
    }
    return this.prefs;
  }

  async getHistoryLimit(): Promise<number> {
    const p = this.getPrefs();
    return await p.get(UserSettings.KEY_HISTORY_LIMIT, AppConstants.DEFAULT_HISTORY_LIMIT) as number;
  }

  async setHistoryLimit(limit: number): Promise<void> {
    const p = this.getPrefs();
    await p.put(UserSettings.KEY_HISTORY_LIMIT, limit);
    await p.flush();
  }

  async isPrivacyMode(): Promise<boolean> {
    const p = this.getPrefs();
    const enabled = await p.get(UserSettings.KEY_PRIVACY_MODE, false) as boolean;
    if (!enabled) {
      return false;
    }
    const until: string = await p.get(UserSettings.KEY_PRIVACY_MODE_UNTIL, '') as string;
    if (until && until.length > 0) {
      const expiry: Date = new Date(until);
      if (expiry.getTime() < Date.now()) {
        await this.setPrivacyMode(false);
        return false;
      }
    }
    return true;
  }

  async setPrivacyMode(enabled: boolean, until: string | null = null): Promise<void> {
    const p = this.getPrefs();
    await p.put(UserSettings.KEY_PRIVACY_MODE, enabled);
    if (until !== null && until !== undefined) {
      await p.put(UserSettings.KEY_PRIVACY_MODE_UNTIL, until);
    } else if (!enabled) {
      await p.put(UserSettings.KEY_PRIVACY_MODE_UNTIL, '');
    }
    await p.flush();
  }

  async isBiometricEnabled(): Promise<boolean> {
    const p = this.getPrefs();
    return await p.get(UserSettings.KEY_BIOMETRIC_ENABLED, false) as boolean;
  }

  async setBiometricEnabled(enabled: boolean): Promise<void> {
    const p = this.getPrefs();
    await p.put(UserSettings.KEY_BIOMETRIC_ENABLED, enabled);
    await p.flush();
  }

  async getTextSizeLimit(): Promise<number> {
    const p = this.getPrefs();
    return await p.get(UserSettings.KEY_TEXT_SIZE_LIMIT, AppConstants.TEXT_SIZE_LIMIT) as number;
  }

  async setTextSizeLimit(limit: number): Promise<void> {
    const p = this.getPrefs();
    await p.put(UserSettings.KEY_TEXT_SIZE_LIMIT, limit);
    await p.flush();
  }

  async getImageSizeLimit(): Promise<number> {
    const p = this.getPrefs();
    return await p.get(UserSettings.KEY_IMAGE_SIZE_LIMIT, AppConstants.IMAGE_SIZE_LIMIT) as number;
  }

  async setImageSizeLimit(limit: number): Promise<void> {
    const p = this.getPrefs();
    await p.put(UserSettings.KEY_IMAGE_SIZE_LIMIT, limit);
    await p.flush();
  }
}
