import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import { AppBlacklistEntry } from '../model/AppBlacklistEntry';
import { CustomCategory } from '../model/CustomCategory';
import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppConstants } from '../common/constants/AppConstants';
import { AppContext } from '../common/utils/AppContext';
import { hilog } from '@kit.PerformanceAnalysisKit';

interface SettingsItem {
  icon: string;
  title: string;
  subtitle: string;
  type: string; // 'toggle' | 'navigate' | 'display'
  isOn: boolean;
  value: string;
  key: string;
}

/**
 * Settings page with five sections:
 *   1. History limit slider
 *   2. Privacy mode toggle
 *   3. App blacklist management
 *   4. Biometric re-authentication toggle
 *   5. About section with version and clear-data
 */
@Component
export struct SettingsPage {
  @State historyLimit: number = AppConstants.DEFAULT_HISTORY_LIMIT;
  @State isPrivacyMode: boolean = false;
  @State isBiometricEnabled: boolean = false;
  @State blacklist: AppBlacklistEntry[] = [];
  @State blacklistInput: string = '';
  @State categories: CustomCategory[] = [];
  @State appVersion: string = '1.0.0';
  @State showAddBlacklistDialog: boolean = false;
  @State showAddCategoryDialog: boolean = false;
  @State newBundleName: string = '';
  @State newAppName: string = '';
  @State newCategoryName: string = '';
  @State newCategoryColor: string = '#007DFF';
  private viewModel: SettingsViewModel | null = null;
  private readonly PRESET_COLORS: string[] = [
    '#007DFF', '#7B61FF', '#00B578', '#FF9800', '#E84026',
    '#FF6B6B', '#2196F3', '#9C27B0', '#FF5722', '#607D8B'
  ];

  aboutToAppear(): void {
    this.tryInitViewModel();
  }

  private tryInitViewModel(): void {
    const settingsRepo = AppContext.getSettingsRepo();
    const clipRepo = AppContext.getClipboardRepo();
    const catRepo = AppContext.getCategoryRepo();
    const blacklistDao = AppContext.getBlacklistDao();
    if (settingsRepo && clipRepo && catRepo && blacklistDao) {
      hilog.info(0x0000, '[SettingsPage]', 'repos ready, creating ViewModel');
      this.viewModel = new SettingsViewModel(settingsRepo, clipRepo, catRepo, blacklistDao);
      this.loadSettings();
    } else {
      hilog.info(0x0000, '[SettingsPage]', 'repos not ready, retrying in 200ms');
      setTimeout(() => {
        this.tryInitViewModel();
      }, 200);
    }
  }

  private async loadSettings(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.loadSettings();
      await this.viewModel.loadBlacklist();
      await this.viewModel.loadCategories();
      this.historyLimit = this.viewModel.historyLimit;
      this.isPrivacyMode = this.viewModel.isPrivacyMode;
      this.isBiometricEnabled = this.viewModel.isBiometricEnabled;
      this.blacklist = [...this.viewModel.blacklist];
      this.categories = [...this.viewModel.categories];
      this.appVersion = this.viewModel.appVersion;
    }
  }

  build() {
    Stack() {
    Scroll() {
      Column() {
        // Hero branding
        this.HeroBranding()

        // Recording section - card group
        Text('Recording')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
          .padding({ left: ThemeTokens.SPACING_MD, top: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_XS })

        Column() {
          this.SettingsCardRow('📋', '自动录制', '监听并记录剪贴板内容', 'toggle', !this.isPrivacyMode, '',
            'recording')
        }
        .backgroundColor(ThemeTokens.SURFACE)
        .borderRadius(ThemeTokens.SETTINGS_GROUP_RADIUS)
        .margin({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })

        // Sync section - card group
        Text('Sync')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
          .padding({ left: ThemeTokens.SPACING_MD, top: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_XS })

        Column() {
          this.SettingsCardRow('☁️', '云同步', '在设备间同步剪贴板历史', 'toggle', false, '', 'sync')
          this.SettingsCardRow('🔄', '自动同步', '仅在 Wi-Fi 下自动同步', 'navigate', false, '', 'autoSync')
        }
        .backgroundColor(ThemeTokens.SURFACE)
        .borderRadius(ThemeTokens.SETTINGS_GROUP_RADIUS)
        .margin({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })

        // About section - card group
        Text('About')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
          .padding({ left: ThemeTokens.SPACING_MD, top: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_XS })

        Column() {
          this.SettingsCardRow('ℹ️', 'Version', '', 'display', false, this.appVersion, 'version')
          this.SettingsCardRow('🔒', '隐私政策', '', 'navigate', false, '', 'privacy')
        }
        .backgroundColor(ThemeTokens.SURFACE)
        .borderRadius(ThemeTokens.SETTINGS_GROUP_RADIUS)
        .margin({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })

        // Footer
        this.SettingsFooter()

        // ── Keep original sections below ──

        // Section 1: History limit
        this.SectionHeader('历史记录上限')
        Row() {
          Text('保留条数')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .layoutWeight(1)

          Text(`${this.historyLimit}`)
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
            .fontColor(ThemeTokens.PRIMARY)
        }
        .width('100%')
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG,
          top: ThemeTokens.SPACING_SM, bottom: ThemeTokens.SPACING_XS })

        Slider({
          value: this.historyLimit,
          min: AppConstants.MIN_HISTORY_LIMIT,
          max: AppConstants.MAX_HISTORY_LIMIT,
          step: 50,
          style: SliderStyle.OutSet
        })
          .width('100%')
          .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
          .blockColor(ThemeTokens.PRIMARY)
          .trackColor(ThemeTokens.DIVIDER)
          .selectedColor(ThemeTokens.PRIMARY)
          .onChange((value: number) => {
            this.historyLimit = Math.round(value);
            if (this.viewModel) {
              this.viewModel.updateHistoryLimit(this.historyLimit);
            }
          })

        this.SectionDivider()

        // Section 2: Privacy mode
        this.SectionHeader('隐私模式')
        Row() {
          Column() {
            Text('暂停监控')
              .fontSize(ThemeTokens.FONT_SIZE_BODY)
              .fontColor(ThemeTokens.TEXT_PRIMARY)
            Text('开启后不会记录剪贴板内容')
              .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
              .fontColor(ThemeTokens.TEXT_TERTIARY)
              .margin({ top: ThemeTokens.SPACING_XS })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.isPrivacyMode })
            .selectedColor(ThemeTokens.PRIMARY)
            .onChange((isOn: boolean) => {
              this.isPrivacyMode = isOn;
              if (this.viewModel) {
                this.viewModel.togglePrivacyMode();
              }
            })
        }
        .width('100%')
        .padding(ThemeTokens.SPACING_LG)
        .alignItems(VerticalAlign.Center)

        this.SectionDivider()

        // Section 3: App blacklist
        this.SectionHeader('应用黑名单')
        Row() {
          Text('黑名单中的应用不会记录剪贴板')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .layoutWeight(1)

          Text('添加')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.PRIMARY)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
            .padding({ left: ThemeTokens.SPACING_SM, right: ThemeTokens.SPACING_SM })
            .onClick(() => {
              this.showAddBlacklist();
            })
        }
        .width('100%')
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG,
          bottom: ThemeTokens.SPACING_SM })

        // Blacklist entries
        if (this.blacklist.length > 0) {
          List({ space: 0 }) {
            ForEach(this.blacklist, (entry: AppBlacklistEntry) => {
              ListItem() {
                Row() {
                  Text(entry.appName || entry.bundleName)
                    .fontSize(ThemeTokens.FONT_SIZE_BODY)
                    .fontColor(ThemeTokens.TEXT_PRIMARY)
                    .layoutWeight(1)

                  Text('移除')
                    .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                    .fontColor(ThemeTokens.ERROR)
                    .padding({ left: ThemeTokens.SPACING_SM, right: ThemeTokens.SPACING_SM })
                    .onClick(() => {
                      this.removeBlacklistEntry(entry.id);
                    })
                }
                .width('100%')
                .height(44)
                .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
                .alignItems(VerticalAlign.Center)
              }
              .swipeAction({ end: this.deleteBlacklistSwipeAction(entry) })
            }, (entry: AppBlacklistEntry) => entry.id.toString())
          }
          .width('100%')
        } else {
          Row() {
            Text('暂无黑名单应用')
              .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
              .fontColor(ThemeTokens.TEXT_TERTIARY)
          }
          .width('100%')
          .padding({ left: ThemeTokens.SPACING_LG, bottom: ThemeTokens.SPACING_SM })
        }

        this.SectionDivider()

        // Section 4: Biometric
        this.SectionHeader('生物识别')
        Row() {
          Column() {
            Text('生物识别验证')
              .fontSize(ThemeTokens.FONT_SIZE_BODY)
              .fontColor(ThemeTokens.TEXT_PRIMARY)
            Text('从后台返回时需要验证身份')
              .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
              .fontColor(ThemeTokens.TEXT_TERTIARY)
              .margin({ top: ThemeTokens.SPACING_XS })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.isBiometricEnabled })
            .selectedColor(ThemeTokens.PRIMARY)
            .onChange((isOn: boolean) => {
              this.isBiometricEnabled = isOn;
              if (this.viewModel) {
                this.viewModel.toggleBiometric();
              }
            })
        }
        .width('100%')
        .padding(ThemeTokens.SPACING_LG)
        .alignItems(VerticalAlign.Center)

        this.SectionDivider()

        // Section 5: Category management
        this.SectionHeader('收藏夹管理')
        Row() {
          Text('管理自定义收藏夹')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .layoutWeight(1)

          Text('添加')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.PRIMARY)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
            .padding({ left: ThemeTokens.SPACING_SM, right: ThemeTokens.SPACING_SM })
            .onClick(() => {
              this.showAddCategory();
            })
        }
        .width('100%')
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG,
          bottom: ThemeTokens.SPACING_SM })

        // Category list
        if (this.categories.length > 0) {
          List({ space: 0 }) {
            ForEach(this.categories, (cat: CustomCategory) => {
              ListItem() {
                Row() {
                  // Color dot
                  Text('')
                    .width(12)
                    .height(12)
                    .borderRadius(6)
                    .backgroundColor(cat.color || ThemeTokens.PRIMARY)
                    .margin({ right: ThemeTokens.SPACING_MD })

                  // Name
                  Text(cat.name)
                    .fontSize(ThemeTokens.FONT_SIZE_BODY)
                    .fontColor(ThemeTokens.TEXT_PRIMARY)
                    .layoutWeight(1)

                  // Rename action
                  Text('重命名')
                    .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                    .fontColor(ThemeTokens.PRIMARY)
                    .margin({ right: ThemeTokens.SPACING_MD })
                    .onClick(() => {
                      this.showRenameCategory(cat);
                    })

                  // Entry count
                  Text(`${cat.entryCount}`)
                    .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                    .fontColor(ThemeTokens.TEXT_TERTIARY)
                    .margin({ right: ThemeTokens.SPACING_MD })
                }
                .width('100%')
                .height(48)
                .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
                .alignItems(VerticalAlign.Center)
              }
              .swipeAction({ end: this.deleteCategorySwipeAction(cat) })
            }, (cat: CustomCategory) => `settings_cat_${cat.id}`)
          }
          .width('100%')
        } else {
          Row() {
            Text('暂无收藏夹')
              .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
              .fontColor(ThemeTokens.TEXT_TERTIARY)
          }
          .width('100%')
          .padding({ left: ThemeTokens.SPACING_LG, bottom: ThemeTokens.SPACING_SM })
        }

        this.SectionDivider()

        // Section 6: About
        this.SectionHeader('关于')
        Row() {
          Text('应用版本')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .layoutWeight(1)
          Text(this.appVersion)
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
        }
        .width('100%')
        .height(48)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
        .alignItems(VerticalAlign.Center)

        Row() {
          Text('清除所有数据')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.ERROR)
            .layoutWeight(1)
        }
        .width('100%')
        .height(48)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.showClearDataConfirm();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.BACKGROUND)

    // Add-category dialog overlay
    if (this.showAddCategoryDialog) {
      Column() {
        Column() {
          Text('新建收藏夹')
            .fontSize(ThemeTokens.FONT_SIZE_TITLE)
            .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .margin({ bottom: ThemeTokens.SPACING_SM })

          Text(`当前 ${this.categories.length}/${AppConstants.MAX_CATEGORIES}`)
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .margin({ bottom: ThemeTokens.SPACING_MD })

          TextInput({ placeholder: '收藏夹名称', text: this.newCategoryName })
            .width('100%')
            .height(40)
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .defaultFocus(true)
            .onChange((value: string) => {
              this.newCategoryName = value;
            })

          // Color picker
          Text('选择颜色')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_SECONDARY)
            .margin({ top: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_XS })

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.PRESET_COLORS, (color: string) => {
              Text('')
                .width(32)
                .height(32)
                .borderRadius(16)
                .backgroundColor(color)
                .margin(4)
                .border({
                  width: this.newCategoryColor === color ? 3 : 0,
                  color: ThemeTokens.TEXT_PRIMARY
                })
                .onClick(() => {
                  this.newCategoryColor = color;
                })
            }, (color: string) => color)
          }
          .width('100%')
          .margin({ bottom: ThemeTokens.SPACING_MD })

          Row() {
            Text('取消')
              .fontSize(ThemeTokens.FONT_SIZE_BODY)
              .fontColor(ThemeTokens.TEXT_SECONDARY)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.showAddCategoryDialog = false;
              })

            Text('创建')
              .fontSize(ThemeTokens.FONT_SIZE_BODY)
              .fontColor(ThemeTokens.PRIMARY)
              .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.onCreateCategory();
              })
          }
          .width('100%')
        }
        .width('85%')
        .padding(ThemeTokens.SPACING_LG)
        .backgroundColor(ThemeTokens.SURFACE)
        .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
        .onClick(() => {})
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(0x80000000)
      .onClick(() => {
        this.showAddCategoryDialog = false;
      })
    }

    // Add-blacklist dialog overlay
    if (this.showAddBlacklistDialog) {
      Column() {
        Column() {
          Text('添加黑名单应用')
            .fontSize(ThemeTokens.FONT_SIZE_TITLE)
            .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .margin({ bottom: ThemeTokens.SPACING_MD })

          TextInput({ placeholder: 'Bundle Name (如 com.example.app)', text: this.newBundleName })
            .width('100%')
            .height(40)
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .defaultFocus(true)
            .onChange((value: string) => {
              this.newBundleName = value;
            })

          TextInput({ placeholder: '应用名称 (可选)', text: this.newAppName })
            .width('100%')
            .height(40)
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .margin({ top: ThemeTokens.SPACING_SM })
            .onChange((value: string) => {
              this.newAppName = value;
            })

          Row() {
            Text('取消')
              .fontSize(ThemeTokens.FONT_SIZE_BODY)
              .fontColor(ThemeTokens.TEXT_SECONDARY)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.showAddBlacklistDialog = false;
              })

            Text('添加')
              .fontSize(ThemeTokens.FONT_SIZE_BODY)
              .fontColor(ThemeTokens.PRIMARY)
              .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.confirmAddBlacklist();
              })
          }
          .width('100%')
          .margin({ top: ThemeTokens.SPACING_MD })
        }
        .width('85%')
        .padding(ThemeTokens.SPACING_LG)
        .backgroundColor(ThemeTokens.SURFACE)
        .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
        .onClick(() => {})
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(0x80000000)
      .onClick(() => {
        this.showAddBlacklistDialog = false;
      })
    }
    } // Stack
  }

  @Builder
  SectionHeader(title: string) {
    Row() {
      Text(title)
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
    }
    .width('100%')
    .padding({ left: ThemeTokens.SPACING_LG, top: ThemeTokens.SPACING_MD,
      bottom: ThemeTokens.SPACING_XS })
  }

  @Builder
  SectionDivider() {
    Row() {}
      .width('100%')
      .height(ThemeTokens.SPACING_SM)
      .margin({ top: ThemeTokens.SPACING_SM })
  }

  @Builder
  HeroBranding() {
    Column() {
      Text('ClipBridge Pro')
        .fontSize(28)
        .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
        .fontColor(ThemeTokens.TEXT_PRIMARY)

      Text('智能剪贴板管理，让复制更高效')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .margin({ top: ThemeTokens.SPACING_XS })
    }
    .width('100%')
    .padding({ left: ThemeTokens.SPACING_LG, top: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_MD })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SettingsCardRow(icon: string, title: string, subtitle: string, type: string, isOn: boolean, value: string,
    key: string) {
    Row() {
      // Icon
      Row() {
        Text(icon)
          .fontSize(18)
      }
        .width(ThemeTokens.SETTINGS_ICON_BG_SIZE)
        .height(ThemeTokens.SETTINGS_ICON_BG_SIZE)
        .borderRadius(ThemeTokens.SETTINGS_ICON_BG_RADIUS)
        .backgroundColor(ThemeTokens.BACKGROUND)
        .justifyContent(FlexAlign.Center)

      // Text
      Column() {
        Text(title)
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontColor(ThemeTokens.TEXT_PRIMARY)

        if (subtitle) {
          Text(subtitle)
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: ThemeTokens.SPACING_MD })
      .layoutWeight(1)

      // Right control
      if (type === 'toggle') {
        Toggle({ type: ToggleType.Switch, isOn: isOn })
          .selectedColor(ThemeTokens.PRIMARY)
          .onChange((checked: boolean) => {
            if (key === 'recording' && this.viewModel) {
              this.isPrivacyMode = !checked;
              this.viewModel.togglePrivacyMode();
            }
          })
      } else if (type === 'navigate') {
        Text('>')
          .fontSize(14)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
      } else if (type === 'display') {
        Text(value)
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
      }
    }
    .width('100%')
    .padding(ThemeTokens.SPACING_MD)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SettingsFooter() {
    Column() {
      Text('📋')
        .fontSize(32)
        .margin({ bottom: ThemeTokens.SPACING_XS })

      Text('ClipBridge v1.0.0')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
    }
    .width('100%')
    .padding({ top: ThemeTokens.SPACING_XL, bottom: ThemeTokens.SPACING_XL })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private showClearDataConfirm(): void {
    AlertDialog.show({
      title: '清除所有数据',
      message: '此操作将删除所有剪贴板历史记录和设置，且不可恢复。确认继续吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        {
          value: '取消',
          action: () => {}
        },
        {
          value: '清除',
          action: () => {
            if (this.viewModel) {
              this.viewModel.clearAllData();
            }
          }
        }
      ]
    });
  }

  private showAddBlacklist(): void {
    this.newBundleName = '';
    this.newAppName = '';
    this.showAddBlacklistDialog = true;
  }

  private async confirmAddBlacklist(): Promise<void> {
    const bundleName: string = this.newBundleName.trim();
    if (!bundleName) {
      return;
    }
    const appName: string = this.newAppName.trim() || bundleName;
    if (this.viewModel) {
      await this.viewModel.addToBlacklist(bundleName, appName);
    }
    this.showAddBlacklistDialog = false;
    this.newBundleName = '';
    this.newAppName = '';
    await this.loadSettings();
  }

  /**
   * Swipe-to-delete builder for category list items.
   */
  @Builder
  deleteCategorySwipeAction(cat: CustomCategory) {
    Row() {
      Text('删除')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(Color.White)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
    }
    .height('100%')
    .backgroundColor(ThemeTokens.ERROR)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onDeleteCategory(cat.id);
    })
  }

  /**
   * Swipe-to-delete builder for blacklist list items.
   */
  @Builder
  deleteBlacklistSwipeAction(entry: AppBlacklistEntry) {
    Row() {
      Text('删除')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(Color.White)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
    }
    .height('100%')
    .backgroundColor(ThemeTokens.ERROR)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.removeBlacklistEntry(entry.id);
    })
  }

  private showAddCategory(): void {
    this.newCategoryName = '';
    this.newCategoryColor = '#007DFF';
    this.showAddCategoryDialog = true;
  }

  private async onCreateCategory(): Promise<void> {
    if (this.viewModel && this.newCategoryName.trim()) {
      await this.viewModel.createCategory(this.newCategoryName.trim(), this.newCategoryColor);
      this.showAddCategoryDialog = false;
      this.newCategoryName = '';
      await this.loadSettings();
    }
  }

  private showRenameCategory(cat: CustomCategory): void {
    AlertDialog.show({
      title: '重命名收藏夹',
      message: `当前名称: ${cat.name}`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        {
          value: '取消',
          action: () => {}
        },
        {
          value: '确定',
          action: () => {
            // In a full implementation, a TextInput would provide the new name.
            // For now, this shows the rename flow is wired up.
          }
        }
      ]
    });
  }

  private async onDeleteCategory(id: number): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.deleteCategory(id);
      await this.loadSettings();
    }
  }

  private async removeBlacklistEntry(id: number): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.removeFromBlacklist(id);
      await this.loadSettings();
    }
  }
}
