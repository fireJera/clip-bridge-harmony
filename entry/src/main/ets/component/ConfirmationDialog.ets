import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Reusable confirmation dialog for destructive actions (delete, clear all, etc.).
 * Uses @CustomDialog decorator for integration with the ArkUI dialog system.
 */
@CustomDialog
export struct ConfirmationDialog {
  controller: CustomDialogController;
  @Prop title: string = '确认操作';
  @Prop message: string = '此操作不可撤销，确认继续吗？';
  @Prop confirmText: string = '确认';
  @Prop cancelText: string = '取消';
  onConfirm?: () => void;
  onCancel?: () => void;

  build() {
    Column() {
      // Title
      Text(this.title)
        .fontSize(ThemeTokens.FONT_SIZE_TITLE)
        .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
        .fontColor(ThemeTokens.TEXT_PRIMARY)
        .width('100%')
        .margin({ bottom: ThemeTokens.SPACING_MD })

      // Message
      Text(this.message)
        .fontSize(ThemeTokens.FONT_SIZE_BODY)
        .fontColor(ThemeTokens.TEXT_SECONDARY)
        .width('100%')
        .lineHeight(24)
        .margin({ bottom: ThemeTokens.SPACING_XL })

      // Action buttons
      Row() {
        // Cancel button (neutral)
        Button(this.cancelText)
          .layoutWeight(1)
          .height(40)
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
          .fontColor(ThemeTokens.TEXT_SECONDARY)
          .backgroundColor(ThemeTokens.BACKGROUND)
          .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
          .onClick(() => {
            if (this.onCancel) {
              this.onCancel();
            }
            this.controller.close();
          })

        // Spacer
        Blank().width(ThemeTokens.SPACING_MD)

        // Confirm button (destructive)
        Button(this.confirmText)
          .layoutWeight(1)
          .height(40)
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
          .fontColor(Color.White)
          .backgroundColor(ThemeTokens.ERROR)
          .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
          .onClick(() => {
            if (this.onConfirm) {
              this.onConfirm();
            }
            this.controller.close();
          })
      }
      .width('100%')
    }
    .padding(ThemeTokens.SPACING_XL)
    .backgroundColor(ThemeTokens.SURFACE)
    .borderRadius(ThemeTokens.BORDER_RADIUS_LG)
  }
}
