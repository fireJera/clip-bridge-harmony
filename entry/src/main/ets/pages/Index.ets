import { HistoryPage } from './HistoryPage';
import { FavoritesPage } from './FavoritesPage';
import { SettingsPage } from './SettingsPage';
import { DetailPage } from './DetailPage';
import { DetailViewModel } from '../viewmodel/DetailViewModel';
import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppContext } from '../common/utils/AppContext';

/**
 * Navigation parameter interface for DetailPage.
 * Passed via navPathStack.pushPath().
 */
interface DetailPageParams {
  entryId: number;
}

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string, param: Object) {
    if (name === 'DetailPage') {
      DetailPage({
        entryId: (param as DetailPageParams).entryId,
        onBack: () => {
          this.navPathStack.pop();
        }
      })
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Tabs({ index: this.currentIndex }) {
        TabContent() {
          HistoryPage()
        }
        .tabBar('历史')

        TabContent() {
          FavoritesPage()
        }
        .tabBar('收藏')

        TabContent() {
          SettingsPage()
        }
        .tabBar('设置')
      }
      .width('100%')
      .height('100%')
      .barPosition(BarPosition.End)
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .navDestination(this.PageMap)
    .mode(NavigationMode.Stack)
  }
}
