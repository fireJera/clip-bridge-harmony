import { HistoryPage } from './HistoryPage';
import { FavoritesPage } from './FavoritesPage';
import { SettingsPage } from './SettingsPage';
import { DevicesPage } from './DevicesPage';
import { DetailPage } from './DetailPage';
import { SplashPage } from './SplashPage';
import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppContext } from '../common/utils/AppContext';

interface DetailPageParams {
  entryId: number;
}

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State showSplash: boolean = true;
  @State authLocked: boolean = false;
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();
  private authLockCallback = (locked: boolean) => {
    this.authLocked = locked;
  };

  aboutToAppear(): void {
    this.authLocked = AppContext.isAuthLocked();
    AppContext.addAuthLockCallback(this.authLockCallback);
  }

  aboutToDisappear(): void {
    AppContext.removeAuthLockCallback(this.authLockCallback);
  }

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
  TabBuilder(title: string, icon: Resource, activeIcon: Resource, tabIndex: number) {
    Column() {
      Image(this.currentIndex === tabIndex ? activeIcon : icon)
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
        .fillColor(this.currentIndex === tabIndex ?
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
          .tabBar(this.TabBuilder('历史', $r('app.media.time'), $r('app.media.time'), 0))

          TabContent() {
            FavoritesPage()
          }
          .tabBar(this.TabBuilder('收藏', $r('app.media.favorite'), $r('app.media.favorite'), 1))

          TabContent() {
            SettingsPage()
          }
          .tabBar(this.TabBuilder('设置', $r('app.media.setting'), $r('app.media.setting'), 2))
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

      // Auth lock overlay — opaque cover while biometric auth is pending
      if (this.authLocked) {
        Column() {
          Text('🔒')
            .fontSize(48)
            .margin({ bottom: ThemeTokens.SPACING_MD })

          Text('应用已锁定')
            .fontSize(ThemeTokens.FONT_SIZE_TITLE)
            .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
            .fontColor(ThemeTokens.TEXT_PRIMARY)

          Text('请验证身份以继续使用')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .margin({ top: ThemeTokens.SPACING_XS, bottom: ThemeTokens.SPACING_XL })

          Button('解锁')
            .width(160)
            .height(44)
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(Color.White)
            .backgroundColor(ThemeTokens.PRIMARY)
            .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
            .onClick(() => {
              AppContext.requestAuthRetry();
            })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeTokens.BACKGROUND)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
