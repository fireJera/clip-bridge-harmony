import { DetailViewModel } from '../viewmodel/DetailViewModel';
import { CustomCategory } from '../model/CustomCategory';
import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppContext } from '../common/utils/AppContext';
import { promptAction } from '@kit.ArkUI';

/**
 * Detail page for viewing, editing, and managing a clipboard entry.
 *
 * Features:
 * - Text editing with dirty-state tracking and save/revert (US1)
 * - Non-text preview (image placeholder, read-only for url/email/phone/address) (US2)
 * - Management actions: delete, favorite toggle, copy to clipboard (US3)
 * - Unsaved-changes detection on back navigation
 * - isNotFound state for deleted entries
 *
 * The ViewModel is self-initialized from AppContext in aboutToAppear().
 */
@Component
export struct DetailPage {
  @State entryTags: CustomCategory[] = [];
  private viewModel: DetailViewModel | null = null;
  entryId: number = 0;
  onBack: () => void = () => {};

  aboutToAppear(): void {
    const clipRepo = AppContext.getClipboardRepo();
    const catRepo = AppContext.getCategoryRepo();
    const encryptionService = AppContext.getEncryptionService();

    if (clipRepo && catRepo && encryptionService) {
      this.viewModel = new DetailViewModel(clipRepo, catRepo, encryptionService);
    }

    if (this.viewModel && this.entryId > 0) {
      this.viewModel.loadEntry(this.entryId);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  private isTextEditable(): boolean {
    const type = this.viewModel?.entry?.contentType;
    return type === 'text';
  }

  private isReadOnlyTextType(): boolean {
    const type = this.viewModel?.entry?.contentType;
    return type === 'url' || type === 'email' || type === 'phone' || type === 'address';
  }

  private isImageType(): boolean {
    return this.viewModel?.entry?.contentType === 'image';
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

  private handleBack(): void {
    if (this.viewModel && this.viewModel.isDirty) {
      AlertDialog.show({
        title: '未保存的修改',
        message: '是否放弃修改？',
        autoCancel: true,
        alignment: DialogAlignment.Center,
        buttons: [
          {
            value: '继续编辑',
            action: () => {}
          },
          {
            value: '放弃',
            action: () => {
              this.onBack();
            }
          }
        ]
      });
    } else {
      this.onBack();
    }
  }

  private handleDelete(): void {
    AlertDialog.show({
      title: '删除条目',
      message: '确定要删除该条目吗？此操作不可恢复。',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        {
          value: '取消',
          action: () => {}
        },
        {
          value: '删除',
          action: async () => {
            if (this.viewModel) {
              const deleted = await this.viewModel.deleteEntry();
              if (deleted) {
                this.onBack();
              }
            }
          }
        }
      ]
    });
  }

  private async handleSave(): Promise<void> {
    if (!this.viewModel) {
      return;
    }
    await this.viewModel.saveContent();
    if (!this.viewModel.isDirty) {
      // Save succeeded — show toast
      promptAction.showToast({
        message: '保存成功',
        duration: 1500
      });
    }
  }

  private async handleCopy(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.copyToClipboard();
    }
  }

  private showTagPicker(): void {
    if (!this.viewModel) {
      return;
    }
    const allCategories: CustomCategory[] = this.viewModel.categories;
    const appliedIds: number[] = this.entryTags.map((t: CustomCategory): number => t.id);

    const tagNames: string = allCategories.map((c: CustomCategory): string => {
      const isApplied: boolean = appliedIds.indexOf(c.id) >= 0;
      return `${isApplied ? '[x] ' : '[ ] '}${c.name}`;
    }).join('\n');

    AlertDialog.show({
      title: '选择标签',
      message: tagNames || '还没有自定义标签\n请在设置中先创建标签',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        { value: '关闭', action: () => {} }
      ]
    });
  }

  private async onRemoveTag(categoryId: number): Promise<void> {
    if (this.viewModel && this.entryId > 0) {
      await this.viewModel.removeTagFromEntry(this.entryId, categoryId);
      this.entryTags = this.viewModel.entryTags;
    }
  }

  private isEditedContentEmpty(): boolean {
    const content = this.viewModel?.editedContent ?? '';
    return content.trim().length === 0;
  }

  // ── Build ────────────────────────────────────────────────────────────

  build() {
    Column() {
      // ── isNotFound state ──
      if (this.viewModel && this.viewModel.isNotFound) {
        this.NotFoundView()
      } else if (this.viewModel && this.viewModel.isLoading) {
        this.LoadingView()
      } else if (this.viewModel && this.viewModel.entry) {
        this.ContentLayout()
      } else {
        this.LoadingView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.BACKGROUND)
  }

  // ── Sub-views ────────────────────────────────────────────────────────

  @Builder
  NotFoundView() {
    Column() {
      Text('该条目已被删除')
        .fontSize(ThemeTokens.FONT_SIZE_BODY)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .margin({ bottom: ThemeTokens.SPACING_LG })

      Button('返回')
        .height(ThemeTokens.TOUCH_TARGET_MIN)
        .backgroundColor(ThemeTokens.PRIMARY)
        .fontColor(Color.White)
        .fontSize(ThemeTokens.FONT_SIZE_BODY)
        .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
        .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
        .padding({ left: ThemeTokens.SPACING_XL, right: ThemeTokens.SPACING_XL })
        .accessibilityText('返回')
        .accessibilityDescription('点击返回上一页')
        .onClick(() => {
          this.onBack();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(ThemeTokens.PRIMARY)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ContentLayout() {
    // Top bar
    this.TopBar()

    // Scrollable content area
    Scroll() {
      Column() {
        // Content type badge
        Text(this.viewModel!.getTypeLabel())
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor(this.getTypeColor())
          .borderRadius(4)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .margin({ bottom: ThemeTokens.SPACING_MD })

        // Content display — varies by type
        if (this.isImageType()) {
          this.ImagePlaceholder()
        } else if (this.isTextEditable()) {
          this.EditableTextArea()
        } else if (this.isReadOnlyTextType()) {
          this.ReadOnlyTextArea()
        } else {
          // Fallback: editable for unknown types
          this.EditableTextArea()
        }

        // Metadata section — for ALL content types
        this.MetadataSection()

        // Tags section
        this.TagsSection()
      }
      .padding(ThemeTokens.SPACING_LG)
    }
    .layoutWeight(1)

    // Bottom action bar
    this.BottomBar()
  }

  @Builder
  TopBar() {
    Row() {
      // Back button
      Text('<')
        .fontSize(20)
        .fontColor(ThemeTokens.PRIMARY)
        .width(ThemeTokens.TOUCH_TARGET_MIN)
        .height(ThemeTokens.TOUCH_TARGET_MIN)
        .textAlign(TextAlign.Center)
        .accessibilityText('返回')
        .accessibilityDescription('点击返回上一页')
        .onClick(() => {
          this.handleBack();
        })

      // Title
      Text('详情')
        .fontSize(ThemeTokens.FONT_SIZE_TITLE)
        .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
        .fontColor(ThemeTokens.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // Pin toggle
      Text('\uD83D\uDCCC')
        .fontSize(18)
        .opacity(this.viewModel?.entry?.isPinned ? 1.0 : 0.4)
        .width(ThemeTokens.TOUCH_TARGET_MIN)
        .height(ThemeTokens.TOUCH_TARGET_MIN)
        .textAlign(TextAlign.Center)
        .accessibilityText(this.viewModel?.entry?.isPinned ? '取消固定' : '固定')
        .accessibilityDescription('切换固定状态')
        .onClick(() => {
          if (this.viewModel) {
            this.viewModel.togglePin();
          }
        })

      // Favorite toggle
      Text('\u2B50')
        .fontSize(18)
        .opacity(this.viewModel?.entry?.isFavorite ? 1.0 : 0.4)
        .width(ThemeTokens.TOUCH_TARGET_MIN)
        .height(ThemeTokens.TOUCH_TARGET_MIN)
        .textAlign(TextAlign.Center)
        .accessibilityText(this.viewModel?.entry?.isFavorite ? '取消收藏' : '收藏')
        .accessibilityDescription('切换收藏状态')
        .onClick(() => {
          if (this.viewModel) {
            this.viewModel.toggleFavorite();
          }
        })

      // Delete button
      Text('\uD83D\uDDD1')
        .fontSize(18)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .width(ThemeTokens.TOUCH_TARGET_MIN)
        .height(ThemeTokens.TOUCH_TARGET_MIN)
        .textAlign(TextAlign.Center)
        .accessibilityText('删除')
        .accessibilityDescription('删除该条目')
        .onClick(() => {
          this.handleDelete();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: ThemeTokens.SPACING_SM, right: ThemeTokens.SPACING_SM })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  EditableTextArea() {
    TextArea({ text: this.viewModel!.editedContent })
      .fontSize(ThemeTokens.FONT_SIZE_BODY)
      .fontColor(ThemeTokens.TEXT_PRIMARY)
      .backgroundColor(ThemeTokens.SURFACE)
      .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
      .width('100%')
      .constraintSize({ minHeight: 200 })
      .padding(ThemeTokens.SPACING_LG)
      .copyOption(CopyOptions.LocalDevice)
      .onChange((value: string) => {
        if (this.viewModel) {
          this.viewModel.onContentEdited(value);
        }
      })
  }

  @Builder
  ReadOnlyTextArea() {
    TextArea({ text: this.viewModel!.decryptedContent })
      .fontSize(ThemeTokens.FONT_SIZE_BODY)
      .fontColor(ThemeTokens.TEXT_PRIMARY)
      .backgroundColor(ThemeTokens.SURFACE)
      .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
      .width('100%')
      .constraintSize({ minHeight: 200 })
      .padding(ThemeTokens.SPACING_LG)
      .copyOption(CopyOptions.LocalDevice)
      .enabled(false)
  }

  @Builder
  ImagePlaceholder() {
    Column() {
      Text('\uD83D\uDDBC')
        .fontSize(48)
        .margin({ bottom: ThemeTokens.SPACING_SM })

      Text('[Image]')
        .fontSize(ThemeTokens.FONT_SIZE_BODY)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ThemeTokens.SURFACE)
    .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
    .border({ width: 1, color: ThemeTokens.DIVIDER, style: BorderStyle.Dashed })
  }

  @Builder
  MetadataSection() {
    Column() {
      Row() {
        Text('类型: ')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
        Text(this.viewModel!.getTypeLabel())
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_SECONDARY)
      }
      .margin({ bottom: ThemeTokens.SPACING_SM })

      Row() {
        Text('来源: ')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
        Text(this.viewModel!.entry!.sourceApp || '未知')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_SECONDARY)
      }
      .margin({ bottom: ThemeTokens.SPACING_SM })

      Row() {
        Text('创建时间: ')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
        Text(this.viewModel!.formatTime(this.viewModel!.entry!.createdAt))
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_SECONDARY)
      }
      .margin({ bottom: ThemeTokens.SPACING_SM })

      Row() {
        Text('更新时间: ')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
        Text(this.viewModel!.formatTime(this.viewModel!.entry!.updatedAt))
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_SECONDARY)
      }
    }
    .width('100%')
    .padding(ThemeTokens.SPACING_LG)
    .margin({ top: ThemeTokens.SPACING_MD })
  }

  @Builder
  TagsSection() {
    Column() {
      Row() {
        Text('标签')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)

        Blank()

        Text('+ 添加')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.PRIMARY)
          .onClick(() => {
            this.showTagPicker();
          })
      }
      .width('100%')
      .margin({ bottom: ThemeTokens.SPACING_SM })

      if (this.viewModel!.entryTags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, space: { main: `${ThemeTokens.SPACING_XS}vp`, cross: `${ThemeTokens.SPACING_XS}vp` } }) {
          ForEach(this.viewModel!.entryTags, (tag: CustomCategory) => {
            Row() {
              Text('')
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(tag.color || ThemeTokens.PRIMARY)
                .margin({ right: ThemeTokens.SPACING_XS })

              Text(tag.name)
                .fontSize(11)
                .fontColor(ThemeTokens.TEXT_PRIMARY)
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
            .backgroundColor(ThemeTokens.BACKGROUND)
            .border({ width: 1, color: ThemeTokens.DIVIDER })
            .gesture(
              LongPressGesture()
                .onAction(() => {
                  this.onRemoveTag(tag.id);
                })
            )
          }, (tag: CustomCategory) => `tag_${tag.id}`)
        }
      } else {
        Text('暂无标签')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
      }
    }
    .width('100%')
    .padding(ThemeTokens.SPACING_LG)
    .margin({ top: ThemeTokens.SPACING_MD })
    .backgroundColor(ThemeTokens.SURFACE)
    .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
  }

  @Builder
  BottomBar() {
    Row() {
      if (this.viewModel && this.viewModel.isDirty) {
        // Save button (shown when dirty)
        Button(this.viewModel.isSaving ? '保存中...' : '保存')
          .width('100%')
          .height(44)
          .backgroundColor(
            this.isEditedContentEmpty() || this.viewModel.isSaving
              ? ThemeTokens.TEXT_TERTIARY
              : ThemeTokens.PRIMARY
          )
          .fontColor(Color.White)
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
          .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
          .enabled(!this.viewModel.isSaving && !this.isEditedContentEmpty())
          .accessibilityText('保存')
          .accessibilityDescription('保存修改后的内容')
          .onClick(() => {
            this.handleSave();
          })
      } else {
        // Copy button (shown when not dirty)
        Button(this.viewModel?.isCopied ? '已复制' : '复制到剪贴板')
          .width('100%')
          .height(44)
          .backgroundColor(this.viewModel?.isCopied ? ThemeTokens.SUCCESS : ThemeTokens.PRIMARY)
          .fontColor(Color.White)
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
          .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
          .accessibilityText('复制到剪贴板')
          .accessibilityDescription('将内容复制到系统剪贴板')
          .onClick(() => {
            this.handleCopy();
          })
      }
    }
    .width('100%')
    .padding({
      left: ThemeTokens.SPACING_LG,
      right: ThemeTokens.SPACING_LG,
      top: ThemeTokens.SPACING_SM,
      bottom: ThemeTokens.SPACING_SM
    })
  }
}
