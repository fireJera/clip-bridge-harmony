import { HistoryPage } from './HistoryPage';
import { FavoritesPage } from './FavoritesPage';
import { ThemeTokens } from '../common/theme/ThemeTokens';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State favoriteCount: number = 0;

  build() {
    Tabs({ index: this.currentIndex }) {
      TabContent() {
        HistoryPage()
      }
      .tabBar('\u5386\u53F2')

      TabContent() {
        FavoritesPage()
      }
      .tabBar(this.FavoritesTabBar())

      TabContent() {
        // SettingsPage placeholder
        Column() {
          Text('\u8BBE\u7F6E')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('\u8BBE\u7F6E')
    }
    .width('100%')
    .height('100%')
    .barPosition(BarPosition.End)
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }

  @Builder
  FavoritesTabBar() {
    Column() {
      Badge({ count: this.favoriteCount, maxCount: 99 }) {
        Text('\u6536\u85CF')
          .fontSize(14)
          .fontColor(this.currentIndex === 1 ? ThemeTokens.PRIMARY : ThemeTokens.TEXT_TERTIARY)
      }
    }
  }
}
