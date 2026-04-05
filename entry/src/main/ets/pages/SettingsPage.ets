import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import { AppBlacklistEntry } from '../model/AppBlacklistEntry';
import { CustomCategory } from '../model/CustomCategory';
import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppConstants } from '../common/constants/AppConstants';

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

  /**
   * Set the ViewModel from outside (called by parent component).
   */
  setViewModel(vm: SettingsViewModel): void {
    this.viewModel = vm;
  }

  aboutToAppear(): void {
    this.loadSettings();
  }

  private async loadSettings(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.loadSettings();
      await this.viewModel.loadBlacklist();
      await this.viewModel.loadCategories();
      this.historyLimit = this.viewModel.historyLimit;
      this.isPrivacyMode = this.viewModel.isPrivacyMode;
      this.isBiometricEnabled = this.viewModel.isBiometricEnabled;
      this.blacklist = this.viewModel.blacklist;
      this.categories = this.viewModel.categories;
      this.appVersion = this.viewModel.appVersion;
    }
  }

  build() {
    Scroll() {
      Column() {
        // Page title
        Row() {
          Text('设置')
            .fontSize(ThemeTokens.FONT_SIZE_TITLE)
            .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
        }
        .width('100%')
        .height(56)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
        .alignItems(VerticalAlign.Center)

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
          ForEach(this.blacklist, (entry: AppBlacklistEntry) => {
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
          }, (entry: AppBlacklistEntry) => entry.id.toString())
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
        this.SectionHeader('自定义标签管理')
        Row() {
          Text('管理自定义分类标签')
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
            Text('暂无自定义标签')
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

  private showClearDataConfirm(): void {
    AlertDialog.show({
      title: '清除所有数据',
      message: '此操作将删除所有剪贴板历史记录和设置，且不可恢复。确认继续吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        {
          text: '取消',
          color: ThemeTokens.TEXT_SECONDARY,
          action: () => {}
        },
        {
          text: '清除',
          color: ThemeTokens.ERROR,
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
    AlertDialog.show({
      title: '添加黑名单应用',
      message: '请输入应用的 Bundle Name 和显示名称',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        {
          text: '取消',
          color: ThemeTokens.TEXT_SECONDARY,
          action: () => {}
        },
        {
          text: '添加',
          color: ThemeTokens.PRIMARY,
          action: () => {
            // Note: In a full implementation this would use a TextInput dialog.
            // For now, this serves as the entry point for adding to blacklist.
          }
        }
      ]
    });
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

  private showAddCategory(): void {
    AlertDialog.show({
      title: '新建标签',
      message: `请输入标签名称\n（当前 ${this.categories.length}/${AppConstants.MAX_CATEGORIES}）`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        {
          text: '取消',
          color: ThemeTokens.TEXT_SECONDARY,
          action: () => {}
        },
        {
          text: '创建',
          color: ThemeTokens.PRIMARY,
          action: () => {
            this.onCreateCategory();
          }
        }
      ]
    });
  }

  private async onCreateCategory(): Promise<void> {
    if (this.viewModel && this.newCategoryName.trim()) {
      await this.viewModel.createCategory(this.newCategoryName.trim(), this.newCategoryColor);
      this.categories = [...this.viewModel.categories];
      this.newCategoryName = '';
    }
  }

  private showRenameCategory(cat: CustomCategory): void {
    AlertDialog.show({
      title: '重命名标签',
      message: `当前名称: ${cat.name}`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        {
          text: '取消',
          color: ThemeTokens.TEXT_SECONDARY,
          action: () => {}
        },
        {
          text: '确定',
          color: ThemeTokens.PRIMARY,
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
      this.categories = [...this.viewModel.categories];
    }
  }

  private async removeBlacklistEntry(id: number): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.removeFromBlacklist(id);
      this.blacklist = [...this.viewModel.blacklist];
    }
  }
}
