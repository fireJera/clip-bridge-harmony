import { HistoryViewModel } from '../viewmodel/HistoryViewModel';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { ClipboardListItem } from '../component/ClipboardListItem';
import { CategoryFilter } from '../component/CategoryFilter';
import { EmptyState } from '../component/EmptyState';
import { LoadingState } from '../component/LoadingState';
import { SearchBar } from '../component/SearchBar';
import { ConfirmationDialog } from '../component/ConfirmationDialog';
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Main history page showing the list of clipboard entries.
 * Uses LazyForEach with IDataSource for performant rendering.
 *
 * Supports:
 *   - Search bar with debounced keyword filtering
 *   - Long-press to enter multi-select mode
 *   - Swipe-to-delete on individual items
 *   - Batch delete in selection mode
 *   - Clear all with confirmation dialog
 */
@Component
export struct HistoryPage {
  @State isLoading: boolean = true;
  @State isEmpty: boolean = true;
  @State dataSource: HistoryDataSource = new HistoryDataSource([]);
  @State isSelectionMode: boolean = false;
  @State selectedIds: Set<number> = new Set();
  private viewModel: HistoryViewModel | null = null;
  private clearAllDialogController: CustomDialogController | null = null;

  /**
   * Set the ViewModel from outside (called by parent component).
   */
  setViewModel(vm: HistoryViewModel): void {
    this.viewModel = vm;
  }

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.loadCategories();
      await this.viewModel.loadHistory();
      this.syncState();
    } else {
      // No repository wired yet - show empty state
      this.isLoading = false;
      this.isEmpty = true;
    }
  }

  /**
   * Syncs local state from the ViewModel to trigger UI re-render.
   */
  private syncState(): void {
    if (this.viewModel) {
      this.isLoading = this.viewModel.isLoading;
      this.isEmpty = this.viewModel.isEmpty;
      this.dataSource = new HistoryDataSource(this.viewModel.entries);
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

        // Clear all button (only when not empty and not in selection mode)
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

      // Category filter bar (between title and search bar)
      CategoryFilter({
        categories: this.viewModel?.categories ?? [],
        onFilterChange: (types: string[], categoryIds: number[]) => {
          this.onFilterChange(types, categoryIds);
        }
      })

      // Search bar (below filter, above list)
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
        // History list with LazyForEach
        List({ space: 0 }) {
          LazyForEach(
            this.dataSource,
            (entry: ClipboardEntry) => {
              ListItem() {
                Row() {
                  // Checkbox in selection mode
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
                    onItemLongPress: (e: ClipboardEntry) => this.onItemLongPress(e)
                  })
                }
                .width('100%')
              }
              .swipeAction({ end: this.deleteSwipeAction(entry) })
            },
            (entry: ClipboardEntry) => entry.id.toString()
          )
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

  /**
   * Swipe-to-delete builder for individual list items.
   */
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
    // Navigate to detail page - will be implemented with NavRouter
    console.info('Item clicked: ' + entry.id);
  }

  private onItemLongPress(entry: ClipboardEntry): void {
    if (!this.isSelectionMode) {
      this.isSelectionMode = true;
      this.selectedIds = new Set<number>();
      this.selectedIds.add(entry.id);
    }
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
      this.isEmpty = this.viewModel.isEmpty;
      this.dataSource = new HistoryDataSource(this.viewModel.entries);
      this.exitSelectionMode();
    }
  }

  private async onSwipeDelete(entry: ClipboardEntry): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.deleteEntry(entry.id);
      this.isEmpty = this.viewModel.isEmpty;
      this.dataSource = new HistoryDataSource(this.viewModel.entries);
    }
  }

  private async onSearch(keyword: string): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.search(keyword);
      this.isEmpty = this.viewModel.isEmpty;
      this.dataSource = new HistoryDataSource(this.viewModel.entries);
    }
  }

  private async onSearchClear(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.clearSearch();
      this.isEmpty = this.viewModel.isEmpty;
      this.dataSource = new HistoryDataSource(this.viewModel.entries);
    }
  }

  /**
   * Shows the clear-all confirmation dialog.
   */
  private showClearAllDialog(): void {
    // The dialog controller is created inline since @Link to a @State dialogController
    // cannot be dynamically instantiated. We use a simple alert pattern.
    AlertDialog.show({
      title: '清空所有记录',
      message: '此操作将删除所有剪贴板历史记录，且不可恢复。确认继续吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        {
          text: '取消',
          color: ThemeTokens.TEXT_SECONDARY,
          action: () => {}
        },
        {
          text: '清空',
          color: ThemeTokens.ERROR,
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
      this.isEmpty = true;
      this.dataSource = new HistoryDataSource([]);
    }
  }
}

/**
 * IDataSource implementation for LazyForEach.
 * Wraps a ClipboardEntry array and notifies listeners on data changes.
 */
class HistoryDataSource implements IDataSource {
  private entries: ClipboardEntry[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(entries: ClipboardEntry[]) {
    this.entries = entries;
  }

  totalCount(): number {
    return this.entries.length;
  }

  getData(index: number): ClipboardEntry {
    return this.entries[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * Replace the entire data set and notify listeners to reload.
   */
  updateEntries(entries: ClipboardEntry[]): void {
    this.entries = entries;
    this.notifyReload();
  }

  /**
   * Notify all registered listeners that data has been reloaded.
   */
  notifyReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    });
  }
}
