import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Empty state placeholder component shown when there is no data to display.
 * Displays a centered icon and descriptive message.
 */
@Component
export struct EmptyState {
  @Prop message: string = '暂无数据';
  @Prop icon?: Resource;

  build() {
    Column() {
      // Placeholder icon area
      Text('\uD83D\uDCCB')
        .fontSize(48)
        .margin({ bottom: ThemeTokens.SPACING_LG })

      Text(this.message)
        .fontSize(ThemeTokens.FONT_SIZE_BODY)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .textAlign(TextAlign.Center)
        .lineHeight(24)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(ThemeTokens.SPACING_XXL)
  }
}
