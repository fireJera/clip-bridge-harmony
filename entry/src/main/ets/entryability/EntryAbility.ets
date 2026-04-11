import { UIAbility, AbilityConstant, Want, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { AppDatabase } from '../data/database/AppDatabase';
import { ClipboardDao } from '../data/database/ClipboardDao';
import { BlacklistDao } from '../data/database/BlacklistDao';
import { CategoryDao } from '../data/database/CategoryDao';
import { UserSettings } from '../data/preferences/UserSettings';
import { AppContext } from '../common/utils/AppContext';
import { EncryptionService } from '../service/EncryptionService';
import { ClipboardRepositoryImpl } from '../repository/ClipboardRepositoryImpl';
import { CategoryRepositoryImpl } from '../repository/CategoryRepositoryImpl';
import { SettingsRepositoryImpl } from '../repository/SettingsRepositoryImpl';
import { IClipboardRepository } from '../repository/ClipboardRepository';
import { ClipboardMonitorService } from '../service/ClipboardMonitorService';
import { ImageStorageService } from '../service/ImageStorageService';

const TAG: string = '[EntryAbility]';
const DOMAIN: number = 0x0000;

export default class EntryAbility extends UIAbility {
  private db: AppDatabase | null = null;
  private monitorService: ClipboardMonitorService | null = null;
  private settings: UserSettings | null = null;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, 'onCreate START');

    // 1. Store context for later use by services
    AppContext.setContext(this.context);

    // 2. Request runtime permissions (READ_PASTEBOARD is user_grant)
    try {
      await this.requestPermissions();
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Permission request failed: %{public}s', JSON.stringify(error));
    }

    // 3. Initialize database
    try {
      this.db = await AppDatabase.getInstance(this.context);
      hilog.info(DOMAIN, TAG, 'Database initialized OK');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Database init FAILED: %{public}s', JSON.stringify(error));
      return;
    }

    // 4. Initialize preferences
    let userSettings: UserSettings;
    try {
      userSettings = await UserSettings.getInstance(this.context);
      this.settings = userSettings;
      hilog.info(DOMAIN, TAG, 'UserSettings initialized OK');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'UserSettings init FAILED: %{public}s', JSON.stringify(error));
      return;
    }

    // 5. Initialize EncryptionService singleton
    let encryptionService: EncryptionService;
    try {
      encryptionService = await EncryptionService.getInstance(this.context);
      hilog.info(DOMAIN, TAG, 'EncryptionService initialized OK');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'EncryptionService init FAILED: %{public}s', JSON.stringify(error));
      return;
    }

    // 6. Wire up the repository layer: DAO -> RepositoryImpl
    const dao: ClipboardDao = new ClipboardDao(this.db.getStore());
    const blacklistDao: BlacklistDao = new BlacklistDao(this.db.getStore());
    const categoryDao: CategoryDao = new CategoryDao(this.db.getStore());
    const imageStorageService = new ImageStorageService(this.context.filesDir);
    AppContext.setImageStorageService(imageStorageService);
    const repo: IClipboardRepository = new ClipboardRepositoryImpl(dao, encryptionService, userSettings, imageStorageService);
    const categoryRepo = new CategoryRepositoryImpl(categoryDao);

    // Store repos in AppContext for UI access
    AppContext.setClipboardRepo(repo);
    AppContext.setCategoryRepo(categoryRepo);
    const settingsRepo = new SettingsRepositoryImpl(userSettings);
    AppContext.setSettingsRepo(settingsRepo);
    AppContext.setBlacklistDao(blacklistDao);
    AppContext.setEncryptionService(encryptionService);
    hilog.info(DOMAIN, TAG, 'Repository layer created OK');

    // 7. Create and start the clipboard monitor service
    try {
      this.monitorService = new ClipboardMonitorService(repo, encryptionService, blacklistDao, imageStorageService);
      await this.monitorService.start();
      hilog.info(DOMAIN, TAG, 'ClipboardMonitorService started OK');
      // Check current clipboard immediately (onForeground already fired before this)
      await this.monitorService.checkCurrentClipboard();
      hilog.info(DOMAIN, TAG, 'Initial clipboard check done');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'ClipboardMonitorService FAILED: %{public}s', JSON.stringify(error));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');

    // Stop the clipboard monitor before tearing down
    if (this.monitorService) {
      this.monitorService.stop().then((): void => {
        hilog.info(DOMAIN, TAG, 'ClipboardMonitorService stopped');
      }).catch((err: Error): void => {
        hilog.error(DOMAIN, TAG, 'Failed to stop ClipboardMonitorService: %{public}s', JSON.stringify(err));
      });
      this.monitorService = null;
    }

    this.db = null;
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate');

    // Load the main page
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground');
    // Check current clipboard content for copies that happened while app was in background
    if (this.monitorService) {
      this.monitorService.checkCurrentClipboard().then((): void => {
        hilog.info(DOMAIN, TAG, 'Current clipboard checked');
      }).catch((err: Error): void => {
        hilog.error(DOMAIN, TAG, 'Failed to check clipboard: %{public}s', JSON.stringify(err));
      });
    }
    this.promptBiometricAuth();
  }

  /**
   * Requests runtime permissions needed by the app.
   * READ_PASTEBOARD is a user_grant permission that must be approved by the user.
   */
  private async requestPermissions(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const permissions: Permissions[] = [
        'ohos.permission.READ_PASTEBOARD'
      ];
      const result = await atManager.requestPermissionsFromUser(this.context, permissions);
      for (let i = 0; i < result.authResults.length; i++) {
        if (result.authResults[i] === 0) {
          hilog.info(DOMAIN, TAG, 'Permission %{public}s granted', permissions[i]);
        } else {
          hilog.warn(DOMAIN, TAG, 'Permission %{public}s denied', permissions[i]);
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Request permissions failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * Prompts biometric/device credential authentication when the app returns
   * to the foreground, if the user has enabled biometric re-authentication.
   * On failure the dialog is re-shown (no crash, keeps the app locked).
   */
  private async promptBiometricAuth(): Promise<void> {
    if (!this.settings) {
      return;
    }

    try {
      const isBioEnabled: boolean = await this.settings.isBiometricEnabled();
      if (!isBioEnabled) {
        return;
      }

      // Determine available auth types, falling back to PIN if biometric unavailable
      const authTypes: userAuth.UserAuthType[] = [];
      try {
        userAuth.getAvailableStatus(userAuth.UserAuthType.FINGERPRINT, userAuth.AuthTrustLevel.ATL1);
        authTypes.push(userAuth.UserAuthType.FINGERPRINT);
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'Fingerprint not available: %{public}s', JSON.stringify(e));
      }
      try {
        userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL1);
        authTypes.push(userAuth.UserAuthType.FACE);
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'Face not available: %{public}s', JSON.stringify(e));
      }

      // Always include PIN as fallback
      authTypes.push(userAuth.UserAuthType.PIN);

      const authInstance: userAuth.UserAuthInstance = userAuth.getUserAuthInstance(
        {
          challenge: new Uint8Array(32),
          authType: authTypes,
          authTrustLevel: userAuth.AuthTrustLevel.ATL1
        },
        { title: '请验证身份' }
      );

      authInstance.on('result', {
        onResult: (result: userAuth.UserAuthResult) => {
          if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
            hilog.info(DOMAIN, TAG, 'Biometric auth succeeded');
          } else {
            hilog.warn(DOMAIN, TAG, 'Biometric auth failed, retrying');
            this.promptBiometricAuth();
          }
        }
      });

      authInstance.start();
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Biometric auth error: %{public}s', JSON.stringify(error));
    }
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');
  }
}
