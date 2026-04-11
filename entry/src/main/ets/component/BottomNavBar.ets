import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Tab definition for the bottom navigation bar.
 */
interface NavTab {
  label: string;
  icon: string;
  activeIcon: string;
}

/**
 * Custom bottom navigation bar matching Figma HarmonyOS design.
 * Uses Row-based layout with 4 tabs: History, Favorites, Devices, Settings.
 */
@Component
export struct BottomNavBar {
  @Link currentIndex: number;
  private readonly tabs: NavTab[] = [
    { label: '历史', icon: '⏱', activeIcon: '⏱' },
    { label: '收藏', icon: '♡', activeIcon: '♥' },
    { label: '设备', icon: '📱', activeIcon: '📱' },
    { label: '设置', icon: '⚙', activeIcon: '⚙' }
  ];

  build() {
    Row() {
      ForEach(this.tabs, (tab: NavTab, index?: number) => {
        Column() {
          Text(index === this.currentIndex ? tab.activeIcon : tab.icon)
            .fontSize(ThemeTokens.NAV_ICON_SIZE)
            .fontColor(index === this.currentIndex ? ThemeTokens.NAV_ACTIVE_COLOR : ThemeTokens.NAV_INACTIVE_COLOR)

          Text(tab.label)
            .fontSize(ThemeTokens.NAV_LABEL_SIZE)
            .fontColor(index === this.currentIndex ? ThemeTokens.NAV_ACTIVE_COLOR : ThemeTokens.NAV_INACTIVE_COLOR)
            .fontWeight(index === this.currentIndex ? ThemeTokens.FONT_WEIGHT_MEDIUM : ThemeTokens.FONT_WEIGHT_REGULAR)
            .margin({ top: ThemeTokens.SPACING_XS })
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          if (index !== undefined) {
            this.currentIndex = index;
          }
        })
      }, (tab: NavTab, index?: number) => `nav_tab_${index}`)
    }
    .width('100%')
    .height(ThemeTokens.NAV_HEIGHT)
    .backgroundColor(ThemeTokens.SURFACE)
    .border({ width: { top: 0.5 }, color: ThemeTokens.DIVIDER })
    .padding({ bottom: ThemeTokens.SPACING_XS })
  }
}
