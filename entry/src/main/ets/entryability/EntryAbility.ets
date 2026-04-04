import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppDatabase } from '../data/database/AppDatabase';
import { UserSettings } from '../data/preferences/UserSettings';
import { AppContext } from '../common/utils/AppContext';

const TAG: string = '[EntryAbility]';
const DOMAIN: number = 0x0000;

export default class EntryAbility extends UIAbility {
  private db: AppDatabase | null = null;

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
    }

    // 3. Initialize preferences
    try {
      await UserSettings.getInstance(this.context);
      hilog.info(DOMAIN, TAG, 'UserSettings initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize UserSettings: %{public}s', JSON.stringify(error));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
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
