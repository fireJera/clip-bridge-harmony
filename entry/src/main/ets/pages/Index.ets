import { HistoryPage } from './HistoryPage';
import { FavoritesPage } from './FavoritesPage';
import { SettingsPage } from './SettingsPage';
import { DevicesPage } from './DevicesPage';
import { DetailPage } from './DetailPage';
import { SplashPage } from './SplashPage';
import { ThemeTokens } from '../common/theme/ThemeTokens';

interface DetailPageParams {
  entryId: number;
}

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State showSplash: boolean = true;
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string, param: Object) {
    if (name === 'DetailPage') {
      NavDestination() {
        DetailPage({
          entryId: (param as DetailPageParams).entryId,
          onBack: () => {
            this.navPathStack.pop();
          }
        })
      }
      .hideTitleBar(true)
      .backgroundColor(ThemeTokens.BACKGROUND)
    }
  }

  @Builder
  TabBuilder(title: string, icon: string, activeIcon: string, tabIndex: number) {
    Column() {
      Text(this.currentIndex === tabIndex ? activeIcon : icon)
        .fontSize(24)
        .fontColor(this.currentIndex === tabIndex ?
          ThemeTokens.NAV_ACTIVE_COLOR : ThemeTokens.NAV_INACTIVE_COLOR)

      Text(title)
        .fontSize(ThemeTokens.NAV_LABEL_SIZE)
        .fontColor(this.currentIndex === tabIndex ?
          ThemeTokens.NAV_ACTIVE_COLOR : ThemeTokens.NAV_INACTIVE_COLOR)
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Stack() {
      if (this.showSplash) {
        SplashPage({
          onFinished: () => {
            animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
              this.showSplash = false;
            });
          }
        })
      }

      Navigation(this.navPathStack) {
        Tabs({ index: this.currentIndex }) {
          TabContent() {
            HistoryPage()
          }
          .tabBar(this.TabBuilder('历史', '⏱', '⏱', 0))

          TabContent() {
            FavoritesPage()
          }
          .tabBar(this.TabBuilder('收藏', '♡', '♥', 1))

          TabContent() {
            DevicesPage()
          }
          .tabBar(this.TabBuilder('设备', '📱', '📱', 2))

          TabContent() {
            SettingsPage()
          }
          .tabBar(this.TabBuilder('设置', '⚙', '⚙', 3))
        }
        .width('100%')
        .height('100%')
        .barPosition(BarPosition.End)
        .barMode(BarMode.Fixed)
        .barHeight(56)
        .barBackgroundColor(ThemeTokens.SURFACE)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
      }
      .navDestination(this.PageMap)
      .mode(NavigationMode.Stack)
      .titleMode(NavigationTitleMode.Mini)
      .hideTitleBar(true)
      .hideToolBar(true)
      .backgroundColor(ThemeTokens.BACKGROUND)
      .opacity(this.showSplash ? 0 : 1)
    }
    .width('100%')
    .height('100%')
  }
}
