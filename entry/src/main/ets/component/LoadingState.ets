import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Loading state component with a centered spinner.
 * Displayed while data is being fetched.
 */
@Component
export struct LoadingState {
  build() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(ThemeTokens.PRIMARY)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
