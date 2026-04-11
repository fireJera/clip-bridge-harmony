import { DetailViewModel } from '../viewmodel/DetailViewModel';
import { CustomCategory } from '../model/CustomCategory';
import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppContext } from '../common/utils/AppContext';
import { promptAction, LengthMetrics } from '@kit.ArkUI';

/**
 * Detail page for viewing, editing, and managing a clipboard entry.
 * Matches Figma HarmonyOS design with:
 *   - TopBar: back + title + delete + favorite + edit
 *   - CONTENT: content card with source info
 *   - CONTEXTUAL NOTES: note input
 *   - LABELS & TAGS: tag pills with add/remove
 *   - Sync info (v2 placeholder)
 *   - Bottom: Copy to Clipboard button
 */
@Component
export struct DetailPage {
  // Reactive state synced from viewModel
  @State isLoading: boolean = true;
  @State isNotFound: boolean = false;
  @State hasEntry: boolean = false;
  @State isDirty: boolean = false;
  @State isSaving: boolean = false;
  @State isCopied: boolean = false;
  @State editedContent: string = '';
  @State decryptedContent: string = '';
  @State contentPreview: string = '';
  @State entryTags: CustomCategory[] = [];
  @State isFavorite: boolean = false;
  @State isPinned: boolean = false;
  @State contentType: string = 'text';
  @State sourceApp: string = '';
  @State createdAt: string = '';
  @State updatedAt: string = '';
  @State typeLabel: string = '';
  @State isEditing: boolean = false;
  @State imagePath: string = '';
  @State thumbnailPath: string = '';
  @State note: string = '';
  @State isEditingNote: boolean = false;

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
      this.viewModel.loadEntry(this.entryId).then(() => {
        this.syncState();
      });
    }
  }

  private syncState(): void {
    if (this.viewModel) {
      this.isLoading = this.viewModel.isLoading;
      this.isNotFound = this.viewModel.isNotFound;
      this.hasEntry = this.viewModel.entry !== null;
      this.isDirty = this.viewModel.isDirty;
      this.isSaving = this.viewModel.isSaving;
      this.isCopied = this.viewModel.isCopied;
      this.editedContent = this.viewModel.editedContent;
      this.decryptedContent = this.viewModel.decryptedContent;
      this.entryTags = [...this.viewModel.entryTags];
      this.typeLabel = this.viewModel.getTypeLabel();
      this.note = this.viewModel.note;
      if (this.viewModel.entry) {
        this.isFavorite = this.viewModel.entry.isFavorite;
        this.isPinned = this.viewModel.entry.isPinned;
        this.contentType = this.viewModel.entry.contentType;
        this.sourceApp = this.viewModel.entry.sourceApp;
        this.createdAt = this.viewModel.entry.createdAt;
        this.updatedAt = this.viewModel.entry.updatedAt;
        this.contentPreview = this.viewModel.entry.contentPreview;
        this.imagePath = this.viewModel.entry.imagePath;
        this.thumbnailPath = this.viewModel.entry.thumbnailPath;
      }
    } else {
      this.isLoading = false;
      this.hasEntry = false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  private isImageType(): boolean {
    return this.contentType === 'image';
  }

  private canEdit(): boolean {
    return !this.isImageType();
  }

  private getTypeIcon(): string {
    const icons: Record<string, string> = {
      'text': '📝', 'url': '🔗', 'email': '✉️',
      'phone': '📱', 'image': '🖼️', 'address': '📍'
    };
    return icons[this.contentType] || '📝';
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
    return colors[this.contentType] || ThemeTokens.TYPE_TEXT_COLOR;
  }

  private formatTime(isoString: string): string {
    if (!isoString) return '';
    if (this.viewModel) {
      return this.viewModel.formatTime(isoString);
    }
    return isoString;
  }

  private handleBack(): void {
    if (this.isDirty) {
      AlertDialog.show({
        title: '未保存的修改',
        message: '是否放弃修改？',
        autoCancel: true,
        alignment: DialogAlignment.Center,
        buttons: [
          { value: '继续编辑', action: () => {} },
          { value: '放弃', action: () => { this.onBack(); } }
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
        { value: '取消', action: () => {} },
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
    if (!this.viewModel) return;
    await this.viewModel.saveContent();
    this.syncState();
    this.isEditing = false;
    if (!this.isDirty) {
      promptAction.showToast({ message: '保存成功', duration: 1500 });
    }
  }

  private async handleCopy(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.copyToClipboard();
      this.syncState();
    }
  }

  private showTagPicker(): void {
    if (!this.viewModel || !this.viewModel.entry) return;
    const allCategories: CustomCategory[] = this.viewModel.categories;
    if (allCategories.length === 0) {
      AlertDialog.show({
        title: '选择收藏夹',
        message: '还没有收藏夹\n请在设置中先创建收藏夹',
        autoCancel: true,
        alignment: DialogAlignment.Center,
        buttons: [{ value: '知道了', action: () => {} }]
      });
      return;
    }

    const appliedIds: number[] = this.entryTags.map((t: CustomCategory): number => t.id);
    const sheets: Array<SheetInfo> = allCategories.map((c: CustomCategory): SheetInfo => {
      const isApplied: boolean = appliedIds.indexOf(c.id) >= 0;
      return {
        title: isApplied ? `✓ ${c.name}` : c.name,
        action: async () => {
          if (this.viewModel && this.entryId > 0) {
            if (isApplied) {
              await this.viewModel.removeTagFromEntry(this.entryId, c.id);
            } else {
              await this.viewModel.addTagToEntry(this.entryId, c.id);
            }
            this.syncState();
            AppContext.notifyDataChanged();
          }
        }
      };
    });

    ActionSheet.show({
      title: '选择收藏夹',
      message: '点击以添加或移出收藏夹',
      confirm: {
        value: '取消',
        action: () => {}
      },
      sheets: sheets
    });
  }

  private async onRemoveTag(categoryId: number): Promise<void> {
    if (this.viewModel && this.entryId > 0) {
      await this.viewModel.removeTagFromEntry(this.entryId, categoryId);
      this.syncState();
      AppContext.notifyDataChanged();
    }
  }

  private isEditedContentEmpty(): boolean {
    return this.editedContent.trim().length === 0;
  }

  @State showImageDialog: boolean = false;

  private showImagePreview(): void {
    AlertDialog.show({
      title: '图片预览',
      message: '暂不支持大图预览',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [{ value: '关闭', action: () => {} }]
    });
  }

  // ── Build ────────────────────────────────────────────────────────────

  build() {
    Column() {
      // TopBar - always visible
      this.TopBar()

      if (this.isNotFound) {
        Column() {
          Text('该条目已被删除')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .margin({ bottom: ThemeTokens.SPACING_LG })
          Button('返回')
            .height(ThemeTokens.TOUCH_TARGET_MIN)
            .backgroundColor(ThemeTokens.PRIMARY)
            .fontColor(Color.White)
            .onClick(() => { this.onBack(); })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.isLoading || !this.hasEntry) {
        Column() {
          LoadingProgress().width(48).height(48).color(ThemeTokens.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            this.ContentSection()
            this.NotesSection()
            this.TagsSection()
          }
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
          .constraintSize({ minHeight: '100%' })
          .onClick(() => {
            this.isEditing = false;
            this.isEditingNote = false;
          })
        }
        .id('detailScroll')
        .focusable(true)
        .width('100%')
        .layoutWeight(1)
      }

      // BottomBar - always visible
      Column() {
        this.BottomBar()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
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
        .onClick(() => { this.onBack(); })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ── Top Bar ─────────────────────────────────────────────────────────

  @Builder
  TopBar() {
    Row() {
      Row() {
        Text('‹')
          .fontSize(24)
          .fontColor('#999999')
      }
      .width(40)
      .height(40)
      .justifyContent(FlexAlign.Center)
      .onClick(() => { this.handleBack(); })

      Text('剪贴板详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // Delete
      Text('🗑')
        .fontSize(18)
        .fontColor('#999999')
        .margin({ right: 16 })
        .onClick(() => { this.handleDelete(); })

      // Pin
      Text(this.isPinned ? '📌' : '📍')
        .fontSize(18)
        .margin({ right: 12 })
        .onClick(() => {
          if (this.viewModel) {
            this.viewModel.togglePin().then(() => { this.syncState(); });
          }
        })

      // Edit / Cancel / Save button
      if (this.canEdit()) {
        Button(this.isDirty ? '保存' : (this.isEditing ? '取消' : '编辑'))
          .height(32)
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.isEditing && !this.isDirty ? '#999999' : '#007DFF')
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            if (this.isDirty) {
              this.handleSave();
            } else if (this.isEditing) {
              // Cancel: revert content and exit editing
              this.isEditing = false;
              if (this.viewModel) {
                this.viewModel.revertContent();
                this.editedContent = this.viewModel.editedContent;
              }
            } else {
              // Start editing
              this.isEditing = true;
              setTimeout(() => {
                focusControl.requestFocus('editTextArea');
              }, 150);
            }
          })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  // ── CONTENT Section ─────────────────────────────────────────────────

  @Builder
  ContentSection() {
    Column() {
      // Section header
      Text('内容')
        .fontSize(12)
        .fontColor('#999999')
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      // Content card with light blue background
      if (this.isEditing && this.canEdit()) {
        TextArea({ text: this.editedContent })
          .id('editTextArea')
          .fontSize(16)
          .fontColor('#1A1A1A')
          .backgroundColor('#E6F0FF')
          .borderRadius(12)
          .width('100%')
          .constraintSize({ minHeight: 100 })
          .padding(16)
          .defaultFocus(true)
          .onChange((value: string) => {
            if (this.viewModel) {
              this.viewModel.onContentEdited(value);
              this.isDirty = this.viewModel.isDirty;
            }
            this.editedContent = value;
          })
      } else if (this.isImageType()) {
        Column() {
          if (this.imagePath || this.thumbnailPath) {
            Image(`file://${this.imagePath || this.thumbnailPath}`)
              .width('100%')
              .objectFit(ImageFit.Contain)
              .borderRadius(12)
              .constraintSize({ maxHeight: 400 })
              .onClick(() => {
                this.showImagePreview();
              })
          } else {
            Text('🖼')
              .fontSize(48)
              .margin({ bottom: 8 })
            Text('图片不可用')
              .fontSize(12)
              .fontColor('#999999')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .borderRadius(12)
        .backgroundColor('#E6F0FF')
        .padding(12)
      } else {
        Scroll() {
          Column() {
            Text(this.decryptedContent || this.contentPreview || this.editedContent)
              .fontSize(16)
              .fontColor('#1A1A1A')
              .lineHeight(24)
              .width('100%')
              .textAlign(TextAlign.Center)
              .copyOption(CopyOptions.LocalDevice)
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .height(240)
        .borderRadius(12)
        .backgroundColor('#E6F0FF')
        .scrollBar(BarState.Auto)
      }

      // Source info line
      Row() {
        Text('🕐')
          .fontSize(14)
          .margin({ right: 6 })

        Text(`${this.formatTime(this.updatedAt)} ${this.sourceApp ? '来自 ' + this.sourceApp : ''}`)
          .fontSize(12)
          .fontColor('#999999')

        Blank()

        Text(this.isImageType() ? this.typeLabel : `${this.typeLabel} · ${(this.decryptedContent || this.contentPreview || this.editedContent).length} 字符`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // ── CONTEXTUAL NOTES Section ────────────────────────────────────────

  @Builder
  NotesSection() {
    Column() {
      Text('备注')
        .fontSize(12)
        .fontColor('#999999')
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      if (this.isEditingNote) {
        TextInput({ placeholder: '为这条记录添加备注...', text: $$this.note })
          .id('noteInput')
          .fontSize(16)
          .fontColor('#1A1A1A')
          .placeholderColor('#CCCCCC')
          .backgroundColor(Color.White)
          .borderRadius(12)
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            if (this.viewModel) {
              this.viewModel.saveNote(value);
            }
          })
          .onBlur(() => {
            this.isEditingNote = false;
          })
      } else {
        Row() {
          Text(this.note || '为这条记录添加备注...')
            .fontSize(16)
            .fontColor(this.note ? '#1A1A1A' : '#CCCCCC')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height(52)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.isEditingNote = true;
          setTimeout(() => {
            focusControl.requestFocus('noteInput');
          }, 100);
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // ── LABELS & TAGS Section ───────────────────────────────────────────

  @Builder
  TagsSection() {
    Column() {
      // Header row
      Row() {
        Text('收藏夹')
          .fontSize(12)
          .fontColor('#999999')
          .fontWeight(FontWeight.Bold)

        Blank()

        Text('+ 添加到收藏夹')
          .fontSize(14)
          .fontColor('#007DFF')
          .onClick(() => { this.showTagPicker(); })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // Tags
      if (this.entryTags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) } }) {
          ForEach(this.entryTags, (tag: CustomCategory) => {
            Row() {
              Text(tag.name)
                .fontSize(12)
                .fontColor('#007DFF')
                .margin({ right: 4 })

              Text('×')
                .fontSize(14)
                .fontColor('#999999')
                .onClick(() => { this.onRemoveTag(tag.id); })
            }
            .padding({ left: 12, right: 10, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor('#E6F0FF')
          }, (tag: CustomCategory) => `tag_${tag.id}`)
        }
      } else {
        Text('暂未加入收藏夹')
          .fontSize(12)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // ── Bottom Bar ──────────────────────────────────────────────────────

  @Builder
  BottomBar() {
    Row() {
      Text('📋')
        .fontSize(20)
        .fontColor(Color.White)
        .margin({ right: 8 })

      Text(this.isCopied ? '已复制到剪贴板' : '复制到剪贴板')
        .fontSize(18)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(28)
    .backgroundColor(this.isCopied ? '#64BB5C' : '#007DFF')
    .onClick(() => { this.handleCopy(); })
  }
}
