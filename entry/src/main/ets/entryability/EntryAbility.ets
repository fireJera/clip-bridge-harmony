import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppDatabase } from '../data/database/AppDatabase';
import { ClipboardDao } from '../data/database/ClipboardDao';
import { UserSettings } from '../data/preferences/UserSettings';
import { AppContext } from '../common/utils/AppContext';
import { EncryptionService } from '../service/EncryptionService';
import { ClipboardRepositoryImpl } from '../repository/ClipboardRepositoryImpl';
import { IClipboardRepository } from '../repository/ClipboardRepository';
import { ClipboardMonitorService } from '../service/ClipboardMonitorService';

const TAG: string = '[EntryAbility]';
const DOMAIN: number = 0x0000;

export default class EntryAbility extends UIAbility {
  private db: AppDatabase | null = null;
  private monitorService: ClipboardMonitorService | null = null;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, 'onCreate');

    // 1. Store context for later use by services
    AppContext.setContext(this.context);

    // 2. Initialize database
    try {
      this.db = await AppDatabase.getInstance(this.context);
      hilog.info(DOMAIN, TAG, 'Database initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize database: %{public}s', JSON.stringify(error));
      return;
    }

    // 3. Initialize preferences
    let userSettings: UserSettings;
    try {
      userSettings = await UserSettings.getInstance(this.context);
      hilog.info(DOMAIN, TAG, 'UserSettings initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize UserSettings: %{public}s', JSON.stringify(error));
      return;
    }

    // 4. Initialize EncryptionService singleton
    let encryptionService: EncryptionService;
    try {
      encryptionService = await EncryptionService.getInstance(this.context);
      hilog.info(DOMAIN, TAG, 'EncryptionService initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize EncryptionService: %{public}s', JSON.stringify(error));
      return;
    }

    // 5. Wire up the repository layer: DAO -> RepositoryImpl
    const dao: ClipboardDao = new ClipboardDao(this.db.getStore());
    const repo: IClipboardRepository = new ClipboardRepositoryImpl(dao, encryptionService, userSettings);

    // 6. Create and start the clipboard monitor service
    try {
      this.monitorService = new ClipboardMonitorService(repo, encryptionService);
      await this.monitorService.start();
      hilog.info(DOMAIN, TAG, 'ClipboardMonitorService started successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to start ClipboardMonitorService: %{public}s', JSON.stringify(error));
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
    // TODO (Phase 7): Biometric re-authentication will be added here
    hilog.info(DOMAIN, TAG, 'onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');
  }
}
