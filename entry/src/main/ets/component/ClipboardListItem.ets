import { ClipboardEntry } from '../model/ClipboardEntry';
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Reusable list item component for displaying a clipboard entry.
 * Shows content type badge, content preview, timestamp, and pin/favorite indicators.
 * Supports click and long-press gestures.
 */
@Component
export struct ClipboardListItem {
  @Prop entry: ClipboardEntry;
  onItemClick?: (entry: ClipboardEntry) => void;
  onItemLongPress?: (entry: ClipboardEntry) => void;

  build() {
    ListItem() {
      Row() {
        // Content type icon/badge
        this.TypeBadge()

        // Content preview + timestamp
        Column() {
          Text(this.entry.contentPreview)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .width('100%')

          Row() {
            Text(this.formatTime(this.entry.updatedAt))
              .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
              .fontColor(ThemeTokens.TEXT_TERTIARY)

            if (this.entry.isPinned) {
              Text('\uD83D\uDCCC')
                .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                .margin({ left: ThemeTokens.SPACING_SM })
            }
            if (this.entry.isFavorite) {
              Text('\u2B50')
                .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                .margin({ left: ThemeTokens.SPACING_SM })
            }
          }
          .margin({ top: ThemeTokens.SPACING_XS })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(ThemeTokens.LIST_ITEM_HEIGHT)
      .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
      .alignItems(VerticalAlign.Center)
    }
    .onClick(() => {
      if (this.onItemClick) {
        this.onItemClick(this.entry);
      }
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (this.onItemLongPress) {
            this.onItemLongPress(this.entry);
          }
        })
    )
  }

  @Builder
  TypeBadge() {
    Text(this.getTypeLabel())
      .fontSize(10)
      .fontColor(Color.White)
      .backgroundColor(this.getTypeColor())
      .borderRadius(4)
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .margin({ right: ThemeTokens.SPACING_MD })
  }

  private getTypeLabel(): string {
    const labels: Record<string, string> = {
      'text': '文本',
      'url': '链接',
      'email': '邮箱',
      'phone': '电话',
      'image': '图片',
      'address': '地址'
    };
    return labels[this.entry.contentType] || '文本';
  }

  private getTypeColor(): string {
    const colors: Record<string, string> = {
      'text': ThemeTokens.TYPE_TEXT_COLOR,
      'url': ThemeTokens.TYPE_URL_COLOR,
      'email': ThemeTokens.TYPE_EMAIL_COLOR,
      'phone': ThemeTokens.TYPE_PHONE_COLOR,
      'image': ThemeTokens.TYPE_IMAGE_COLOR,
      'address': ThemeTokens.TYPE_ADDRESS_COLOR
    };
    return colors[this.entry.contentType] || ThemeTokens.TYPE_TEXT_COLOR;
  }

  private formatTime(isoString: string): string {
    if (!isoString) {
      return '';
    }
    try {
      const date = new Date(isoString);
      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffMinutes = Math.floor(diffMs / 60000);

      // Just now (within 1 minute)
      if (diffMinutes < 1) {
        return '刚刚';
      }
      // Within 60 minutes
      if (diffMinutes < 60) {
        return `${diffMinutes}分钟前`;
      }

      const diffHours = Math.floor(diffMinutes / 60);
      const isToday = date.getFullYear() === now.getFullYear() &&
        date.getMonth() === now.getMonth() &&
        date.getDate() === now.getDate();

      // Today - show time
      if (isToday) {
        const hours = date.getHours().toString().padStart(2, '0');
        const minutes = date.getMinutes().toString().padStart(2, '0');
        return `今天 ${hours}:${minutes}`;
      }

      // Yesterday
      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      const isYesterday = date.getFullYear() === yesterday.getFullYear() &&
        date.getMonth() === yesterday.getMonth() &&
        date.getDate() === yesterday.getDate();

      if (isYesterday) {
        const hours = date.getHours().toString().padStart(2, '0');
        const minutes = date.getMinutes().toString().padStart(2, '0');
        return `昨天 ${hours}:${minutes}`;
      }

      // Same year
      if (date.getFullYear() === now.getFullYear()) {
        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        const day = date.getDate().toString().padStart(2, '0');
        return `${month}-${day}`;
      }

      // Different year
      const year = date.getFullYear().toString();
      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const day = date.getDate().toString().padStart(2, '0');
      return `${year}-${month}-${day}`;
    } catch (e) {
      return isoString;
    }
  }
}
