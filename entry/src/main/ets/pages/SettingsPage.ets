import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import { CustomCategory } from '../model/CustomCategory';
import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppConstants } from '../common/constants/AppConstants';
import { AppContext } from '../common/utils/AppContext';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { common } from '@kit.AbilityKit';

/**
 * Settings page with card-group sections:
 *   1. 录制管理 — auto recording toggle + history limit slider
 *   2. 同步 — cloud sync + auto sync
 *   3. 安全 — biometric toggle
 *   4. 收藏夹管理 — category management
 *   5. 关于 — version, privacy, clear data
 */
@Preview
@Component
export struct SettingsPage {
  @State historyLimit: number = AppConstants.DEFAULT_HISTORY_LIMIT;
  @State isPrivacyMode: boolean = false;
  @State isBiometricEnabled: boolean = false;
  @State categories: CustomCategory[] = [];
  @State appVersion: string = '1.0.0';
  @State showAddCategoryDialog: boolean = false;
  @State newCategoryName: string = '';
  @State newCategoryColor: string = '#007DFF';
  private viewModel: SettingsViewModel | null = null;
  private readonly PRESET_COLORS: string[] = [
    '#007DFF', '#7B61FF', '#00B578', '#FF9800', '#E84026',
    '#FF6B6B', '#2196F3', '#9C27B0', '#FF5722', '#607D8B'
  ];

  private refreshCallback: () => void = () => {
    this.loadCategories();
  };

  aboutToAppear(): void {
    this.tryInitViewModel();
    AppContext.addRefreshCallback(this.refreshCallback);
  }

  aboutToDisappear(): void {
    AppContext.removeRefreshCallback(this.refreshCallback);
  }

  private tryInitViewModel(): void {
    const settingsRepo = AppContext.getSettingsRepo();
    const clipRepo = AppContext.getClipboardRepo();
    const catRepo = AppContext.getCategoryRepo();
    if (settingsRepo && clipRepo && catRepo) {
      hilog.info(0x0000, '[SettingsPage]', 'repos ready, creating ViewModel');
      this.viewModel = new SettingsViewModel(settingsRepo, clipRepo, catRepo);
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
      await this.viewModel.loadCategories();
      this.historyLimit = this.viewModel.historyLimit;
      this.isPrivacyMode = this.viewModel.isPrivacyMode;
      this.isBiometricEnabled = this.viewModel.isBiometricEnabled;
      this.categories = [...this.viewModel.categories];
      this.appVersion = this.viewModel.appVersion;
    }
  }

  private async loadCategories(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.loadCategories();
      this.categories = [...this.viewModel.categories];
    }
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          // Hero branding
          this.HeroBranding()

          // ── 录制管理 ──
          this.SectionLabel('录制管理')
          Column() {
            // 自动记录 — Toggle 内联绑定 @State，避免 @Builder 值参数导致响应式丢失
            Row() {
              Row() {
                Image($r('app.media.card'))
                  .width(20)
                  .height(20)
                  .objectFit(ImageFit.Contain)
              }
              .width(ThemeTokens.SETTINGS_ICON_BG_SIZE)
              .height(ThemeTokens.SETTINGS_ICON_BG_SIZE)
              .borderRadius(ThemeTokens.SETTINGS_ICON_BG_RADIUS)
              .backgroundColor(ThemeTokens.BACKGROUND)
              .justifyContent(FlexAlign.Center)

              Column() {
                Text('自动记录')
                  .fontSize(ThemeTokens.FONT_SIZE_BODY)
                  .fontColor(ThemeTokens.TEXT_PRIMARY)
                Text('监听并记录剪贴板内容')
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_TERTIARY)
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: ThemeTokens.SPACING_MD })
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: !this.isPrivacyMode })
                .selectedColor(ThemeTokens.PRIMARY)
                .onChange((checked: boolean) => {
                  if (this.viewModel) {
                    this.isPrivacyMode = !checked;
                    this.viewModel.setPrivacyMode(!checked);
                  }
                })
            }
            .width('100%')
            .padding(ThemeTokens.SPACING_MD)
            .alignItems(VerticalAlign.Center)

            this.CardDivider()

            Column() {
              Row() {
                Text('历史记录上限')
                  .fontSize(ThemeTokens.FONT_SIZE_BODY)
                  .fontColor(ThemeTokens.TEXT_PRIMARY)
                  .layoutWeight(1)

                Text(`${this.historyLimit}`)
                  .fontSize(ThemeTokens.FONT_SIZE_BODY)
                  .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
                  .fontColor(ThemeTokens.PRIMARY)
              }
              .width('100%')

              Slider({
                value: this.historyLimit,
                min: AppConstants.MIN_HISTORY_LIMIT,
                max: AppConstants.MAX_HISTORY_LIMIT,
                step: 50,
                style: SliderStyle.OutSet
              })
                .width('100%')
                .blockColor(ThemeTokens.PRIMARY)
                .trackColor(ThemeTokens.DIVIDER)
                .selectedColor(ThemeTokens.PRIMARY)
                .onChange((value: number) => {
                  this.historyLimit = Math.round(value);
                  if (this.viewModel) {
                    this.viewModel.updateHistoryLimit(this.historyLimit);
                  }
                })
            }
            .width('100%')
            .padding(ThemeTokens.SPACING_MD)
          }
          .backgroundColor(ThemeTokens.SURFACE)
          .borderRadius(ThemeTokens.SETTINGS_GROUP_RADIUS)
          .margin({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })

          // ── 安全 ──
          this.SectionLabel('安全')
          Column() {
            // 生物识别 — Toggle 内联绑定 @State
            Row() {
              Row() {
                Text('🔒')
                  .fontSize(18)
              }
              .width(ThemeTokens.SETTINGS_ICON_BG_SIZE)
              .height(ThemeTokens.SETTINGS_ICON_BG_SIZE)
              .borderRadius(ThemeTokens.SETTINGS_ICON_BG_RADIUS)
              .backgroundColor(ThemeTokens.BACKGROUND)
              .justifyContent(FlexAlign.Center)

              Column() {
                Text('生物识别验证')
                  .fontSize(ThemeTokens.FONT_SIZE_BODY)
                  .fontColor(ThemeTokens.TEXT_PRIMARY)
                Text('从后台返回时需要验证身份')
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_TERTIARY)
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: ThemeTokens.SPACING_MD })
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.isBiometricEnabled })
                .selectedColor(ThemeTokens.PRIMARY)
                .hitTestBehavior(HitTestMode.None)
            }
            .width('100%')
            .padding(ThemeTokens.SPACING_MD)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.onBiometricToggleClicked();
            })
          }
          .backgroundColor(ThemeTokens.SURFACE)
          .borderRadius(ThemeTokens.SETTINGS_GROUP_RADIUS)
          .margin({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })

          // ── 收藏夹管理 ──
          this.SectionLabel('收藏夹管理')
          Column() {
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
            .padding(ThemeTokens.SPACING_MD)
            .alignItems(VerticalAlign.Center)

            if (this.categories.length > 0) {
              ForEach(this.categories, (cat: CustomCategory) => {
                Column() {
                  this.CardDivider()
                  Row() {
                    Text('')
                      .width(12)
                      .height(12)
                      .borderRadius(6)
                      .backgroundColor(cat.color || ThemeTokens.PRIMARY)
                      .margin({ right: ThemeTokens.SPACING_MD })

                    Text(cat.name)
                      .fontSize(ThemeTokens.FONT_SIZE_BODY)
                      .fontColor(ThemeTokens.TEXT_PRIMARY)
                      .layoutWeight(1)

                    Text('重命名')
                      .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                      .fontColor(ThemeTokens.PRIMARY)
                      .margin({ right: ThemeTokens.SPACING_MD })
                      .onClick(() => {
                        this.showRenameCategory(cat);
                      })

                    Text(`${cat.entryCount} 条`)
                      .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                      .fontColor(ThemeTokens.TEXT_TERTIARY)
                      .margin({ right: ThemeTokens.SPACING_SM })

                    Text('删除')
                      .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                      .fontColor(ThemeTokens.ERROR)
                      .onClick(() => {
                        this.onDeleteCategoryConfirm(cat);
                      })
                  }
                  .width('100%')
                  .padding(ThemeTokens.SPACING_MD)
                  .alignItems(VerticalAlign.Center)
                }
              }, (cat: CustomCategory) => `settings_cat_${cat.id}_${cat.entryCount}`)
            } else {
              this.CardDivider()
              Row() {
                Text('暂无收藏夹')
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_TERTIARY)
              }
              .width('100%')
              .padding({ left: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_SM,
                top: ThemeTokens.SPACING_XS })
            }
          }
          .backgroundColor(ThemeTokens.SURFACE)
          .borderRadius(ThemeTokens.SETTINGS_GROUP_RADIUS)
          .margin({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })

          // ── 关于 ──
          this.SectionLabel('关于')
          Column() {
            this.SettingsCardRow('ℹ️', '版本', '', 'display', false, this.appVersion, 'version')

            this.CardDivider()

            Row() {
              Text('清除所有数据')
                .fontSize(ThemeTokens.FONT_SIZE_BODY)
                .fontColor(ThemeTokens.ERROR)
                .layoutWeight(1)
            }
            .width('100%')
            .padding(ThemeTokens.SPACING_MD)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.showClearDataConfirm();
            })
          }
          .backgroundColor(ThemeTokens.SURFACE)
          .borderRadius(ThemeTokens.SETTINGS_GROUP_RADIUS)
          .margin({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })

          // Footer
          this.SettingsFooter()
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
              .placeholderColor(ThemeTokens.TEXT_TERTIARY)
              .backgroundColor(ThemeTokens.BACKGROUND)
              .borderRadius(8)
              .defaultFocus(true)
              .onChange((value: string) => {
                this.newCategoryName = value;
              })

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
              Row() {
                Text('取消')
                  .fontSize(ThemeTokens.FONT_SIZE_BODY)
                  .fontColor(ThemeTokens.TEXT_SECONDARY)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .padding(ThemeTokens.SPACING_SM)
              .onClick(() => {
                this.showAddCategoryDialog = false;
              })

              Row() {
                Text('创建')
                  .fontSize(ThemeTokens.FONT_SIZE_BODY)
                  .fontColor(ThemeTokens.PRIMARY)
                  .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .padding(ThemeTokens.SPACING_SM)
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
    } // Stack
  }

  // ── Builders ──

  @Builder
  SectionLabel(title: string) {
    Text(title)
      .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
      .fontColor(ThemeTokens.TEXT_TERTIARY)
      .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
      .padding({ left: ThemeTokens.SPACING_MD, top: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_XS })
  }

  @Builder
  CardDivider() {
    Row()
      .width('100%')
      .height(0.5)
      .backgroundColor(ThemeTokens.DIVIDER)
      .margin({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })
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
  SettingsCardRow(icon: ResourceStr, title: string, subtitle: string, type: string, isOn: boolean, value: string,
    key: string) {
    Row() {
      // Icon
      Row() {
        if (typeof icon === 'string') {
          Text(icon)
            .fontSize(18)
        } else {
          Image(icon as Resource)
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
        }
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
              const newValue = !checked;
              this.isPrivacyMode = newValue;
              this.viewModel.setPrivacyMode(newValue);
            } else if (key === 'biometric' && this.viewModel) {
              if (checked) {
                let hasBio = false;
                try {
                  userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL1);
                  hasBio = true;
                } catch (e) {
                  // face not available
                }
                if (!hasBio) {
                  try {
                    userAuth.getAvailableStatus(userAuth.UserAuthType.FINGERPRINT, userAuth.AuthTrustLevel.ATL1);
                    hasBio = true;
                  } catch (e) {
                    // fingerprint not available
                  }
                }
                if (!hasBio) {
                  this.isBiometricEnabled = false;
                  AlertDialog.show({
                    title: '无法开启',
                    message: '未检测到人脸或指纹，请先在系统设置中录入。',
                    autoCancel: true,
                    alignment: DialogAlignment.Center,
                    buttons: [{ value: '知道了', action: () => {} }]
                  });
                  return;
                }
              }
              this.isBiometricEnabled = checked;
              this.viewModel.setBiometricEnabled(checked);
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
      Image($r('app.media.card'))
        .width(32)
        .height(32)
        .objectFit(ImageFit.Contain)
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

  // ── Private methods ──

  private onBiometricToggleClicked(): void {
    if (!this.viewModel) {
      return;
    }
    if (this.isBiometricEnabled) {
      // Currently ON → turn OFF
      this.isBiometricEnabled = false;
      this.viewModel.setBiometricEnabled(false);
      return;
    }
    // Currently OFF → check biometric before turning ON
    let hasBiometric = false;
    try {
      userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL1);
      hasBiometric = true;
    } catch (e) {
      hilog.info(0x0000, '[SettingsPage]', 'Face auth not available');
    }
    if (!hasBiometric) {
      try {
        userAuth.getAvailableStatus(userAuth.UserAuthType.FINGERPRINT, userAuth.AuthTrustLevel.ATL1);
        hasBiometric = true;
      } catch (e) {
        hilog.info(0x0000, '[SettingsPage]', 'Fingerprint auth not available');
      }
    }
    if (!hasBiometric) {
      AlertDialog.show({
        title: '无法开启',
        message: '未检测到人脸或指纹，请先在系统设置中录入。',
        autoCancel: true,
        alignment: DialogAlignment.Center,
        buttons: [
          { value: '取消', action: () => {} },
          {
            value: '去设置',
            action: () => {
              const context = AppContext.getContext() as common.UIAbilityContext;
              context.startAbility({
                bundleName: 'com.huawei.hmos.settings',
                abilityName: 'com.huawei.hmos.settings.MainAbility',
                uri: 'biometrics_and_password_settings'
              }).catch(() => {});
            }
          }
        ]
      });
      return;
    }
    this.isBiometricEnabled = true;
    this.viewModel.setBiometricEnabled(true);
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

  private onDeleteCategoryConfirm(cat: CustomCategory): void {
    AlertDialog.show({
      title: '删除收藏夹',
      message: `确定要删除「${cat.name}」吗？该收藏夹下的条目不会被删除。`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        { value: '取消', action: () => {} },
        {
          value: '删除',
          action: async () => {
            if (this.viewModel) {
              await this.viewModel.deleteCategory(cat.id);
              await this.loadSettings();
            }
          }
        }
      ]
    });
  }

}
