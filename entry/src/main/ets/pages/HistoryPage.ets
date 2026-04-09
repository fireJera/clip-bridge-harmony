import { HistoryViewModel } from '../viewmodel/HistoryViewModel';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { ClipboardListItem } from '../component/ClipboardListItem';
import { CategoryFilter } from '../component/CategoryFilter';
import { EmptyState } from '../component/EmptyState';
import { LoadingState } from '../component/LoadingState';
import { SearchBar } from '../component/SearchBar';
import { ConfirmationDialog } from '../component/ConfirmationDialog';
import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppContext } from '../common/utils/AppContext';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';

/**
 * Main history page showing the list of clipboard entries.
 * Uses ForEach for reliable UI refresh on state changes.
 *
 * Supports:
 *   - Search bar with debounced keyword filtering
 *   - Long-press to enter multi-select mode
 *   - Swipe-to-delete on individual items
 *   - Batch delete in selection mode
 *   - Clear all with confirmation dialog
 *   - Toggle favorite on items
 */
@Component
export struct HistoryPage {
  @State isLoading: boolean = true;
  @State isEmpty: boolean = true;
  @State entries: ClipboardEntry[] = [];
  @State isSelectionMode: boolean = false;
  @State selectedIds: Set<number> = new Set();
  private viewModel: HistoryViewModel | null = null;
  private skipNextRefresh: boolean = false;
  @Consume('navPathStack') navPathStack: NavPathStack;

  private refreshHandler: () => void = () => {
    if (this.skipNextRefresh) {
      this.skipNextRefresh = false;
      hilog.info(0x0000, '[HistoryPage]', 'skip refresh (self-triggered)');
      return;
    }
    hilog.info(0x0000, '[HistoryPage]', 'refresh triggered by data change');
    this.loadData();
  };

  aboutToAppear(): void {
    hilog.info(0x0000, '[HistoryPage]', 'aboutToAppear');
    AppContext.addRefreshCallback(this.refreshHandler);
    this.tryInitViewModel();
  }

  aboutToDisappear(): void {
    AppContext.removeRefreshCallback(this.refreshHandler);
  }

  private tryInitViewModel(): void {
    const clipRepo = AppContext.getClipboardRepo();
    const catRepo = AppContext.getCategoryRepo();
    if (clipRepo && catRepo) {
      hilog.info(0x0000, '[HistoryPage]', 'repos ready, creating ViewModel');
      this.viewModel = new HistoryViewModel(clipRepo, catRepo);
      this.loadData();
    } else {
      hilog.info(0x0000, '[HistoryPage]', 'repos not ready, retrying in 200ms');
      setTimeout(() => {
        this.tryInitViewModel();
      }, 200);
    }
  }

  private async loadData(): Promise<void> {
    if (this.viewModel) {
      hilog.info(0x0000, '[HistoryPage]', 'loadData: start loading');
      try {
        await this.viewModel.loadCategories();
        hilog.info(0x0000, '[HistoryPage]', 'loadData: categories loaded OK');
      } catch (error) {
        hilog.error(0x0000, '[HistoryPage]', 'loadCategories FAILED: %{public}s', JSON.stringify(error));
      }

      try {
        await this.viewModel.loadHistory();
        hilog.info(0x0000, '[HistoryPage]', 'loadData: entries=%{public}d, isEmpty=%{public}s',
          this.viewModel.entries.length, String(this.viewModel.isEmpty));
        this.syncState();
      } catch (error) {
        hilog.error(0x0000, '[HistoryPage]', 'loadHistory FAILED: %{public}s', JSON.stringify(error));
        this.isLoading = false;
        this.isEmpty = true;
      }
    } else {
      hilog.warn(0x0000, '[HistoryPage]', 'loadData: viewModel is NULL');
      this.isLoading = false;
      this.isEmpty = true;
    }
  }

  private syncState(): void {
    if (this.viewModel) {
      this.isLoading = this.viewModel.isLoading;
      this.isEmpty = this.viewModel.isEmpty;
      this.entries = [...this.viewModel.entries];
      hilog.info(0x0000, '[HistoryPage]', 'syncState: loading=%{public}s, empty=%{public}s, count=%{public}d',
        String(this.isLoading), String(this.isEmpty), this.entries.length);
    }
  }

  build() {
    Column() {
      // Title bar
      Row() {
        Text('剪贴板历史')
          .fontSize(ThemeTokens.FONT_SIZE_TITLE)
          .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
          .fontColor(ThemeTokens.TEXT_PRIMARY)
          .layoutWeight(1)

        if (!this.isEmpty && !this.isSelectionMode) {
          Text('清空')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.ERROR)
            .padding({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD,
              top: ThemeTokens.SPACING_XS, bottom: ThemeTokens.SPACING_XS })
            .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
            .backgroundColor('#1AE84026')
            .onClick(() => {
              this.showClearAllDialog();
            })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
      .alignItems(VerticalAlign.Center)

      CategoryFilter({
        categories: this.viewModel?.categories ?? [],
        onFilterChange: (types: string[], categoryIds: number[]) => {
          this.onFilterChange(types, categoryIds);
        }
      })

      if (!this.isSelectionMode) {
        Row() {
          SearchBar({
            onSearch: (keyword: string) => this.onSearch(keyword),
            onClear: () => this.onSearchClear()
          })
        }
        .width('100%')
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG,
          bottom: ThemeTokens.SPACING_SM })
      }

      // Content area
      if (this.isLoading) {
        LoadingState()
      } else if (this.isEmpty) {
        EmptyState({ message: '还没有剪贴板记录\n复制内容后会自动出现在这里' })
      } else {
        List({ space: 0 }) {
          ForEach(this.entries, (entry: ClipboardEntry) => {
            ListItem() {
              Row() {
                if (this.isSelectionMode) {
                  Checkbox()
                    .select(this.selectedIds.has(entry.id))
                    .onChange((isChecked: boolean) => {
                      this.toggleSelection(entry.id);
                    })
                    .margin({ right: ThemeTokens.SPACING_MD })
                }

                ClipboardListItem({
                  entry: entry,
                  onItemClick: (e: ClipboardEntry) => {
                    if (this.isSelectionMode) {
                      this.toggleSelection(e.id);
                    } else {
                      this.onItemClick(e);
                    }
                  },
                  onItemLongPress: (e: ClipboardEntry) => this.onItemLongPress(e),
                  onItemFavorite: (e: ClipboardEntry) => this.onItemFavorite(e)
                })
              }
              .width('100%')
            }
            .swipeAction({ end: this.deleteSwipeAction(entry) })
          }, (entry: ClipboardEntry) => `${entry.id}_${entry.isFavorite}`)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: ThemeTokens.DIVIDER })
        .edgeEffect(EdgeEffect.Spring)
      }

      // Selection mode bottom action bar
      if (this.isSelectionMode) {
        Row() {
          Text(`已选择 ${this.selectedIds.size} 项`)
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_SECONDARY)
            .layoutWeight(1)

          Button('取消')
            .height(36)
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
            .fontColor(ThemeTokens.TEXT_SECONDARY)
            .backgroundColor(ThemeTokens.BACKGROUND)
            .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
            .padding({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })
            .onClick(() => {
              this.exitSelectionMode();
            })

          Blank().width(ThemeTokens.SPACING_SM)

          Button('删除所选')
            .height(36)
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
            .fontColor(Color.White)
            .backgroundColor(ThemeTokens.ERROR)
            .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
            .padding({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })
            .enabled(this.selectedIds.size > 0)
            .opacity(this.selectedIds.size > 0 ? 1.0 : 0.5)
            .onClick(() => {
              this.deleteSelected();
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
        .backgroundColor(ThemeTokens.SURFACE)
        .alignItems(VerticalAlign.Center)
        .shadow({ radius: 8, color: '#1A000000', offsetY: -2 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.BACKGROUND)
  }

  @Builder
  deleteSwipeAction(entry: ClipboardEntry) {
    Row() {
      Text('删除')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(Color.White)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
    }
    .height('100%')
    .backgroundColor(ThemeTokens.ERROR)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onSwipeDelete(entry);
    })
  }

  private async onFilterChange(types: string[], categoryIds: number[]): Promise<void> {
    if (!this.viewModel) {
      return;
    }
    if (types.length > 0 || categoryIds.length > 0) {
      this.viewModel.activeTypeFilters = types;
      this.viewModel.activeCategoryFilters = categoryIds;
      await this.viewModel.applyFilters();
    } else {
      await this.viewModel.loadHistory();
    }
    this.syncState();
  }

  private onItemClick(entry: ClipboardEntry): void {
    const params: Record<string, Object> = { 'entryId': entry.id };
    this.navPathStack.pushPath({
      name: 'DetailPage',
      param: params
    });
  }

  private onItemLongPress(entry: ClipboardEntry): void {
    if (!this.isSelectionMode) {
      this.isSelectionMode = true;
      this.selectedIds = new Set<number>();
      this.selectedIds.add(entry.id);
    }
  }

  private onItemFavorite(entry: ClipboardEntry): void {
    if (!this.viewModel) return;
    const newFav: boolean = !entry.isFavorite;

    // Show toast
    promptAction.showToast({
      message: newFav ? '已收藏并置顶' : '已取消收藏',
      duration: 1500
    });

    // Persist to DB
    this.viewModel.updateFavorite(entry.id, newFav).then(async () => {
      if (newFav) {
        // 收藏：乐观置顶，跳过下次刷新避免覆盖本地状态
        this.skipNextRefresh = true;
        const updated: ClipboardEntry = new ClipboardEntry();
        updated.id = entry.id;
        updated.contentHash = entry.contentHash;
        updated.contentEncrypted = entry.contentEncrypted;
        updated.contentType = entry.contentType;
        updated.contentPreview = entry.contentPreview;
        updated.imagePath = entry.imagePath;
        updated.thumbnailPath = entry.thumbnailPath;
        updated.contentSize = entry.contentSize;
        updated.sourceApp = entry.sourceApp;
        updated.isPinned = entry.isPinned;
        updated.isFavorite = true;
        updated.pinnedAt = entry.pinnedAt;
        updated.favoritedAt = new Date().toISOString();
        updated.createdAt = entry.createdAt;
        updated.updatedAt = new Date().toISOString();
        updated.iv = entry.iv;
        updated.authTag = entry.authTag;
        updated.tags = entry.tags;
        updated.rawContent = entry.rawContent;
        this.entries = [updated, ...this.entries.filter(e => e.id !== entry.id)];
        if (this.viewModel) {
          this.viewModel.entries = this.entries;
        }
      } else {
        // 取消收藏：reload 恢复正确排序
        if (this.viewModel) {
          await this.viewModel.loadHistory();
        }
        this.syncState();
      }
      // 通知其他页面刷新（如收藏页面）
      AppContext.notifyDataChanged();
    });
  }

  private toggleSelection(id: number): void {
    const newSet: Set<number> = new Set(this.selectedIds);
    if (newSet.has(id)) {
      newSet.delete(id);
    } else {
      newSet.add(id);
    }
    this.selectedIds = newSet;
  }

  private exitSelectionMode(): void {
    this.isSelectionMode = false;
    this.selectedIds = new Set<number>();
  }

  private async deleteSelected(): Promise<void> {
    if (this.viewModel && this.selectedIds.size > 0) {
      const idsToDelete: number[] = Array.from(this.selectedIds);
      await this.viewModel.deleteBatch(idsToDelete);
      this.syncState();
      this.exitSelectionMode();
      AppContext.notifyDataChanged();
    }
  }

  private async onSwipeDelete(entry: ClipboardEntry): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.deleteEntry(entry.id);
      this.syncState();
      AppContext.notifyDataChanged();
    }
  }

  private async onSearch(keyword: string): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.search(keyword);
      this.syncState();
    }
  }

  private async onSearchClear(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.clearSearch();
      this.syncState();
    }
  }

  private showClearAllDialog(): void {
    AlertDialog.show({
      title: '清空所有记录',
      message: '此操作将删除所有剪贴板历史记录，且不可恢复。确认继续吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        {
          value: '取消',
          action: () => {}
        },
        {
          value: '清空',
          action: () => {
            this.performClearAll();
          }
        }
      ]
    });
  }

  private async performClearAll(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.clearAll();
      this.syncState();
      AppContext.notifyDataChanged();
    }
  }
}
