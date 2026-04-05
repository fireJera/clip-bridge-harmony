import { HistoryPage } from './HistoryPage';
import { ThemeTokens } from '../common/theme/ThemeTokens';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  build() {
    Tabs({ index: this.currentIndex }) {
      TabContent() {
        HistoryPage()
      }
      .tabBar('历史')

      TabContent() {
        // FavoritesPage placeholder
        Column() {
          Text('收藏')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('收藏')

      TabContent() {
        // SettingsPage placeholder
        Column() {
          Text('设置')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
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
}
