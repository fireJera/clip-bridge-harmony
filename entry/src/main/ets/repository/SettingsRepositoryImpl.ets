import { ISettingsRepository } from './SettingsRepository';
import { UserSettings } from '../data/preferences/UserSettings';

const TAG: string = '[SettingsRepositoryImpl]';

export class SettingsRepositoryImpl implements ISettingsRepository {
  private userSettings: UserSettings;

  constructor(userSettings: UserSettings) {
    this.userSettings = userSettings;
  }

  async getHistoryLimit(): Promise<number> {
    try {
      return await this.userSettings.getHistoryLimit();
    } catch (error) {
      throw new Error(`Failed to get history limit: ${error}`);
    }
  }

  async setHistoryLimit(limit: number): Promise<void> {
    try {
      await this.userSettings.setHistoryLimit(limit);
    } catch (error) {
      throw new Error(`Failed to set history limit to ${limit}: ${error}`);
    }
  }

  async isPrivacyMode(): Promise<boolean> {
    try {
      return await this.userSettings.isPrivacyMode();
    } catch (error) {
      throw new Error(`Failed to get privacy mode status: ${error}`);
    }
  }

  async setPrivacyMode(enabled: boolean, until?: string): Promise<void> {
    try {
      await this.userSettings.setPrivacyMode(enabled, until);
    } catch (error) {
      throw new Error(`Failed to set privacy mode to ${enabled}: ${error}`);
    }
  }

  async isBiometricEnabled(): Promise<boolean> {
    try {
      return await this.userSettings.isBiometricEnabled();
    } catch (error) {
      throw new Error(`Failed to get biometric enabled status: ${error}`);
    }
  }

  async setBiometricEnabled(enabled: boolean): Promise<void> {
    try {
      await this.userSettings.setBiometricEnabled(enabled);
    } catch (error) {
      throw new Error(`Failed to set biometric enabled to ${enabled}: ${error}`);
    }
  }
}
