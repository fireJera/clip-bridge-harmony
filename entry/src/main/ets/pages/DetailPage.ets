import { DetailViewModel } from '../viewmodel/DetailViewModel';
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Detail page for viewing the full content of a clipboard entry.
 * Shows content, metadata, and provides action buttons for pin, favorite, and copy.
 *
 * The viewModel should be constructed externally with the required
 * IClipboardRepository and EncryptionService dependencies and set
 * before the page appears.
 */
@Component
export struct DetailPage {
  @State isCopied: boolean = false;
  private viewModel: DetailViewModel | null = null;
  entryId: number = 0;

  /**
   * Set the ViewModel from outside (called by parent or navigation).
   */
  setViewModel(vm: DetailViewModel): void {
    this.viewModel = vm;
  }

  aboutToAppear(): void {
    if (this.viewModel && this.entryId > 0) {
      this.viewModel.loadEntry(this.entryId);
    }
  }

  build() {
    Column() {
      // Top bar with back + actions
      Row() {
        // Back button
        Text('<')
          .fontSize(20)
          .fontColor(ThemeTokens.PRIMARY)
          .width(ThemeTokens.TOUCH_TARGET_MIN)
          .height(ThemeTokens.TOUCH_TARGET_MIN)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            // Navigate back - will be implemented with NavRouter
            console.info('Back pressed');
          })

        // Title
        Text('详情')
          .fontSize(ThemeTokens.FONT_SIZE_TITLE)
          .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
          .fontColor(ThemeTokens.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Action icons: pin
        Text('\uD83D\uDCCC')
          .fontSize(18)
          .opacity(this.viewModel?.entry?.isPinned ? 1.0 : 0.4)
          .width(ThemeTokens.TOUCH_TARGET_MIN)
          .height(ThemeTokens.TOUCH_TARGET_MIN)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.viewModel) {
              this.viewModel.togglePin();
            }
          })

        // Action icons: favorite
        Text('\u2B50')
          .fontSize(18)
          .opacity(this.viewModel?.entry?.isFavorite ? 1.0 : 0.4)
          .width(ThemeTokens.TOUCH_TARGET_MIN)
          .height(ThemeTokens.TOUCH_TARGET_MIN)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.viewModel) {
              this.viewModel.toggleFavorite();
            }
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeTokens.SPACING_SM, right: ThemeTokens.SPACING_SM })
      .alignItems(VerticalAlign.Center)

      // Content area
      Scroll() {
        Column() {
          // Content type badge
          if (this.viewModel?.entry) {
            Text(this.viewModel.getTypeLabel())
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor(this.getTypeColor())
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ bottom: ThemeTokens.SPACING_MD })
          }

          // Full content (text selectable)
          Text(this.viewModel?.decryptedContent ?? '')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .copyOption(CopyOptions.LocalDevice)
            .width('100%')
            .padding(ThemeTokens.SPACING_LG)
            .backgroundColor(ThemeTokens.SURFACE)
            .borderRadius(ThemeTokens.BORDER_RADIUS_MD)

          // Metadata section
          if (this.viewModel?.entry) {
            Column() {
              Row() {
                Text('类型: ')
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_TERTIARY)
                Text(this.viewModel.getTypeLabel())
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_SECONDARY)
              }
              .margin({ bottom: ThemeTokens.SPACING_SM })

              Row() {
                Text('来源: ')
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_TERTIARY)
                Text(this.viewModel.entry.sourceApp || '未知')
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_SECONDARY)
              }
              .margin({ bottom: ThemeTokens.SPACING_SM })

              Row() {
                Text('时间: ')
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_TERTIARY)
                Text(this.viewModel.formatTime(this.viewModel.entry.updatedAt))
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_SECONDARY)
              }
            }
            .width('100%')
            .padding(ThemeTokens.SPACING_LG)
            .margin({ top: ThemeTokens.SPACING_MD })
          }
        }
        .padding(ThemeTokens.SPACING_LG)
      }
      .layoutWeight(1)

      // Bottom action bar
      Row() {
        Button(this.viewModel?.isCopied ? '已复制' : '复制到剪贴板')
          .width('100%')
          .height(44)
          .backgroundColor(this.viewModel?.isCopied ? ThemeTokens.SUCCESS : ThemeTokens.PRIMARY)
          .fontColor(Color.White)
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
          .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
          .onClick(() => {
            if (this.viewModel) {
              this.viewModel.copyToClipboard();
            }
          })
      }
      .width('100%')
      .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG, top: ThemeTokens.SPACING_SM, bottom: ThemeTokens.SPACING_SM })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.BACKGROUND)
  }

  private getTypeColor(): string {
    const entry = this.viewModel?.entry;
    if (!entry) {
      return ThemeTokens.TYPE_TEXT_COLOR;
    }
    const colors: Record<string, string> = {
      'text': ThemeTokens.TYPE_TEXT_COLOR,
      'url': ThemeTokens.TYPE_URL_COLOR,
      'email': ThemeTokens.TYPE_EMAIL_COLOR,
      'phone': ThemeTokens.TYPE_PHONE_COLOR,
      'image': ThemeTokens.TYPE_IMAGE_COLOR,
      'address': ThemeTokens.TYPE_ADDRESS_COLOR
    };
    return colors[entry.contentType] || ThemeTokens.TYPE_TEXT_COLOR;
  }
}
