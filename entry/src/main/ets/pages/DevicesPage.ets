import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Placeholder Devices page for v1.
 * Shows "coming soon" message. Full device sync management planned for v2.
 */
@Preview
@Component
export struct DevicesPage {
  build() {
    Column() {
      // Title
      Row() {
        Text('设备')
          .fontSize(ThemeTokens.FONT_SIZE_TITLE)
          .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
          .fontColor(ThemeTokens.TEXT_PRIMARY)
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
      .alignItems(VerticalAlign.Center)

      // Placeholder content
      Column() {
        Text('设备同步功能即将上线')
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)

        Text('v2 将支持多设备间剪贴板历史同步')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .margin({ top: ThemeTokens.SPACING_SM })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(ThemeTokens.SPACING_XL)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.BACKGROUND)
  }
}
