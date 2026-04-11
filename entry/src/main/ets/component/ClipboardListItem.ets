import { ClipboardEntry } from '../model/ClipboardEntry';
import { CustomCategory } from '../model/CustomCategory';
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Card-style list item for displaying a clipboard entry.
 * Matches Figma HarmonyOS design with:
 *   - Header: type icon + type name + relative time + more button
 *   - Content: type-specific preview (text, link, email, phone, address, image)
 *   - Footer: auto-type tag
 */
@Component
export struct ClipboardListItem {
  @Prop entry: ClipboardEntry;
  onItemClick?: (entry: ClipboardEntry) => void;
  onItemLongPress?: (entry: ClipboardEntry) => void;
  onItemPin?: (entry: ClipboardEntry) => void;

  build() {
    Column() {
      Column() {
      // Card header: icon + type label + time + more
      Row() {
        Row() {
          Text(this.getTypeIcon())
            .fontSize(16)
            .fontColor(Color.White)
        }
        .width(32)
        .height(32)
        .borderRadius(8)
        .backgroundColor(this.getTypeColor())
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Column() {
          Text(this.getTypeLabel())
            .fontSize(10)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)

          Text(this.formatTime(this.entry.updatedAt))
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: ThemeTokens.SPACING_SM })

        Blank()

        Text('···')
          .fontSize(16)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .borderRadius(14)
          .onClick(() => {
            if (this.onItemPin) {
              this.onItemPin(this.entry);
            }
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12 })

      // Content preview — type-specific
      this.ContentPreview()

      // Footer: folders + note preview
      Column() {
        Row() {
          // Folder tags
          if (this.entry.tags && this.entry.tags.length > 0) {
            ForEach(this.entry.tags, (tag: CustomCategory) => {
              Text(tag.name)
                .fontSize(11)
                .fontColor(ThemeTokens.PRIMARY)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(10)
                .backgroundColor('#E6F0FF')
                .margin({ right: 4 })
            }, (tag: CustomCategory) => `list_tag_${tag.id}`)
          }

          Blank()

          // Note preview
          if (this.entry.note && this.entry.note.length > 0) {
            Text(this.entry.note.length > 20 ? this.entry.note.substring(0, 20) + '...' : this.entry.note)
              .fontSize(11)
              .fontColor(ThemeTokens.TEXT_TERTIARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 10, top: 6 })
    }
    .width('100%')
    .backgroundColor(ThemeTokens.SURFACE)
    .borderRadius(12)
    .shadow({ radius: 2, color: '#0A000000', offsetY: 1 })
    }
    .width('100%')
    .padding({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_SM })
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
  ContentPreview() {
    if (this.entry.contentType === 'url') {
      this.LinkPreview()
    } else if (this.entry.contentType === 'image') {
      this.ImagePreview()
    } else {
      this.TextPreview()
    }
  }

  @Builder
  TextPreview() {
    Row() {
      Text(this.entry.contentPreview)
        .fontSize(14)
        .fontColor(ThemeTokens.TEXT_PRIMARY)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6 })
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  LinkPreview() {
    Row() {
      Column() {
        Text('🔗')
          .fontSize(14)
      }
      .width(28)
      .height(28)
      .borderRadius(6)
      .backgroundColor(ThemeTokens.BACKGROUND)
      .justifyContent(FlexAlign.Center)
      .margin({ right: ThemeTokens.SPACING_SM })

      Column() {
        Text(this.getLinkDomain())
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)

        Text(this.entry.contentPreview)
          .fontSize(13)
          .fontColor(ThemeTokens.TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .padding(10)
    .margin({ left: 12, right: 12, top: 6 })
    .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
    .backgroundColor(ThemeTokens.BACKGROUND)
    .alignItems(VerticalAlign.Center)
  }

  private getImageSrc(): string {
    const path = this.entry.thumbnailPath || this.entry.imagePath;
    if (!path) return '';
    return path.startsWith('file://') ? path : `file://${path}`;
  }

  @Builder
  ImagePreview() {
    Column() {
      if (this.entry.thumbnailPath || this.entry.imagePath) {
        Image(this.getImageSrc())
          .width('100%')
          .height(160)
          .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('🖼')
            .fontSize(24)
            .opacity(0.6)
        }
        .width('100%')
        .height(160)
        .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
        .backgroundColor(ThemeTokens.BACKGROUND)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6 })
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

  private getTypeIcon(): string {
    const icons: Record<string, string> = {
      'text': 'T',
      'url': '🔗',
      'email': '✉',
      'phone': '☎',
      'image': '🖼',
      'address': '📍'
    };
    return icons[this.entry.contentType] || 'T';
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

  private getLinkDomain(): string {
    if (this.entry.contentType !== 'url' || !this.entry.contentPreview) {
      return '';
    }
    try {
      const match = this.entry.contentPreview.match(/https?:\/\/([^/]+)/);
      return match ? match[1] : '';
    } catch (e) {
      return '';
    }
  }

  private formatTime(isoString: string): string {
    if (!isoString) return '';
    try {
      const date = new Date(isoString);
      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffMinutes = Math.floor(diffMs / 60000);

      if (diffMinutes < 1) return '刚刚';
      if (diffMinutes < 60) return `${diffMinutes}分钟前`;

      const isToday = date.getFullYear() === now.getFullYear() &&
        date.getMonth() === now.getMonth() &&
        date.getDate() === now.getDate();

      if (isToday) {
        return `今天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
      }

      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      const isYesterday = date.getFullYear() === yesterday.getFullYear() &&
        date.getMonth() === yesterday.getMonth() &&
        date.getDate() === yesterday.getDate();

      if (isYesterday) {
        return `昨天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
      }

      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const day = date.getDate().toString().padStart(2, '0');

      if (date.getFullYear() === now.getFullYear()) {
        return `${month}-${day}`;
      }
      return `${date.getFullYear()}-${month}-${day}`;
    } catch (e) {
      return isoString;
    }
  }
}
