export interface ISettingsRepository {
  getHistoryLimit(): Promise<number>;
  setHistoryLimit(limit: number): Promise<void>;
  isPrivacyMode(): Promise<boolean>;
  setPrivacyMode(enabled: boolean, until?: string): Promise<void>;
  isBiometricEnabled(): Promise<boolean>;
  setBiometricEnabled(enabled: boolean): Promise<void>;
}
