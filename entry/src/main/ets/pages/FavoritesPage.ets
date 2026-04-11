import { FavoritesViewModel } from '../viewmodel/FavoritesViewModel';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { ClipboardListItem } from '../component/ClipboardListItem';
import { CustomCategory } from '../model/CustomCategory';
import { EmptyState } from '../component/EmptyState';
import { LoadingState } from '../component/LoadingState';
import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppContext } from '../common/utils/AppContext';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * Favorites page showing entries that belong to at least one folder (收藏夹).
 * Features a horizontal folder filter bar (single-select).
 * Uses flat ForEach for reliable re-rendering (no nested ForEach).
 */
@Component
export struct FavoritesPage {
  @State isLoading: boolean = true;
  @State isEmpty: boolean = true;
  @State entries: ClipboardEntry[] = [];
  @State folders: CustomCategory[] = [];
  @State activeFolderId: number | null = null;
  private viewModel: FavoritesViewModel | null = null;
  @Consume('navPathStack') navPathStack: NavPathStack;

  private refreshHandler: () => void = () => {
    hilog.info(0x0000, '[FavoritesPage]', 'refresh triggered by data change');
    this.loadData();
  };

  aboutToAppear(): void {
    AppContext.addRefreshCallback(this.refreshHandler);
    this.tryInitViewModel();
  }

  aboutToDisappear(): void {
    AppContext.removeRefreshCallback(this.refreshHandler);
  }

  private tryInitViewModel(): void {
    const categoryRepo = AppContext.getCategoryRepo();
    if (categoryRepo) {
      hilog.info(0x0000, '[FavoritesPage]', 'repo ready, creating ViewModel');
      this.viewModel = new FavoritesViewModel(categoryRepo);
      this.loadData();
    } else {
      hilog.info(0x0000, '[FavoritesPage]', 'repo not ready, retrying in 200ms');
      setTimeout(() => {
        this.tryInitViewModel();
      }, 200);
    }
  }

  private async loadData(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.loadEntries();
      this.syncState();
    } else {
      this.isLoading = false;
      this.isEmpty = true;
    }
  }

  private syncState(): void {
    if (this.viewModel) {
      this.isLoading = this.viewModel.isLoading;
      this.isEmpty = this.viewModel.isEmpty;
      this.entries = [...this.viewModel.entries];
      this.folders = [...this.viewModel.folders];
      this.activeFolderId = this.viewModel.activeFolderId;
    }
  }

  build() {
    Column() {
      // Title bar
      Row() {
        Text('收藏')
          .fontSize(ThemeTokens.FONT_SIZE_TITLE)
          .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
          .fontColor(ThemeTokens.TEXT_PRIMARY)
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
      .alignItems(VerticalAlign.Center)

      // Folder filter bar
      if (this.folders.length > 0) {
        this.FolderFilterBar()
      }

      // Content area
      if (this.isLoading) {
        LoadingState()
      } else if (this.isEmpty) {
        EmptyState({ message: '还没有条目加入收藏夹\n在详情页中将条目添加到收藏夹' })
      } else {
        List({ space: 0 }) {
          ForEach(this.entries, (entry: ClipboardEntry) => {
            ListItem() {
              ClipboardListItem({
                entry: entry,
                onItemClick: (e: ClipboardEntry) => this.onItemClick(e),
                onItemLongPress: (e: ClipboardEntry) => this.onItemLongPress(e),
                onItemPin: (e: ClipboardEntry) => this.onItemPin(e)
              })
            }
            .swipeAction({ end: this.SwipeToRemoveBuilder(entry) })
          }, (entry: ClipboardEntry) => `${entry.id}_${entry.isPinned}`)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: ThemeTokens.DIVIDER })
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.BACKGROUND)
  }

  // ── Folder filter bar ──────────────────────────────────────────────────

  @Builder
  FolderFilterBar() {
    Scroll() {
      Row({ space: ThemeTokens.SPACING_SM }) {
        ForEach(this.folders, (folder: CustomCategory) => {
          Row() {
            Text(folder.name)
              .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
              .fontColor(this.activeFolderId === folder.id ? Color.White : ThemeTokens.TEXT_PRIMARY)
              .fontWeight(this.activeFolderId === folder.id ? ThemeTokens.FONT_WEIGHT_MEDIUM : ThemeTokens.FONT_WEIGHT_REGULAR)
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
          .backgroundColor(this.activeFolderId === folder.id ? ThemeTokens.PRIMARY : ThemeTokens.SURFACE)
          .border({
            width: this.activeFolderId === folder.id ? 0 : 1,
            color: this.activeFolderId === folder.id ? Color.Transparent : ThemeTokens.DIVIDER
          })
          .onClick(() => {
            this.onFolderFilter(folder.id);
          })
        }, (folder: CustomCategory) => `folder_${folder.id}`)
      }
      .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(44)
  }

  // ── Swipe action ──────────────────────────────────────────────────────

  @Builder
  SwipeToRemoveBuilder(entry: ClipboardEntry) {
    Row() {
      Text('移出收藏夹')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(Color.White)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
    }
    .height('100%')
    .backgroundColor(ThemeTokens.WARNING)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onRemoveFromFolder(entry);
    })
  }

  // ── Handlers ──────────────────────────────────────────────────────────

  private onItemClick(entry: ClipboardEntry): void {
    const params: Record<string, Object> = { 'entryId': entry.id };
    this.navPathStack.pushPath({
      name: 'DetailPage',
      param: params
    });
  }

  private onItemLongPress(entry: ClipboardEntry): void {
    console.info('[FavoritesPage] Item long-pressed: ' + entry.id);
  }

  private onItemPin(entry: ClipboardEntry): void {
    // Pin/unpin doesn't affect favorites page, just reload
    this.loadData();
  }

  private async onFolderFilter(folderId: number | null): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.filterByFolder(folderId);
      this.syncState();
    }
  }

  private async onRemoveFromFolder(entry: ClipboardEntry): Promise<void> {
    if (this.viewModel) {
      const folderId: number | null = this.activeFolderId;
      if (folderId !== null) {
        await this.viewModel.removeFromFolder(entry.id, folderId);
      } else {
        // When viewing "all", remove from the first folder found
        // For simplicity, just reload
        await this.viewModel.loadEntries();
      }
      this.syncState();
    }
  }
}
