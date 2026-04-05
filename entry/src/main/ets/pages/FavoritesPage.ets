import { FavoritesViewModel } from '../viewmodel/FavoritesViewModel';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { ClipboardListItem } from '../component/ClipboardListItem';
import { EmptyState } from '../component/EmptyState';
import { LoadingState } from '../component/LoadingState';
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Favorites page showing the list of favorited clipboard entries.
 * Uses LazyForEach with IDataSource for performant rendering.
 * Supports search bar at top, swipe-to-unfavorite gesture, and
 * tap to navigate to DetailPage.
 *
 * The viewModel is initialized by the parent (Index).
 */
@Component
export struct FavoritesPage {
  @State isLoading: boolean = true;
  @State isEmpty: boolean = true;
  @State searchKeyword: string = '';
  @State dataSource: FavoritesDataSource = new FavoritesDataSource([]);
  private viewModel: FavoritesViewModel | null = null;

  /**
   * Set the ViewModel from outside (called by parent component).
   */
  setViewModel(vm: FavoritesViewModel): void {
    this.viewModel = vm;
  }

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.loadFavorites();
      this.isLoading = this.viewModel.isLoading;
      this.isEmpty = this.viewModel.isEmpty;
      this.dataSource = new FavoritesDataSource(this.viewModel.favorites);
    } else {
      this.isLoading = false;
      this.isEmpty = true;
    }
  }

  build() {
    Column() {
      // Title bar with search
      Column() {
        Row() {
          Text('\u6536\u85CF')
            .fontSize(ThemeTokens.FONT_SIZE_TITLE)
            .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
        }
        .width('100%')
        .height(56)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
        .alignItems(VerticalAlign.Center)

        // Search bar
        Row() {
          TextInput({ placeholder: '\u641C\u7D22\u6536\u85CF...', text: this.searchKeyword })
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .placeholderColor(ThemeTokens.TEXT_TERTIARY)
            .backgroundColor(ThemeTokens.SURFACE)
            .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
            .width('100%')
            .height(40)
            .padding({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })
            .onChange((value: string) => {
              this.searchKeyword = value;
            })
            .onSubmit(() => {
              this.onSearch(this.searchKeyword);
            })
        }
        .width('100%')
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG, bottom: ThemeTokens.SPACING_SM })
      }

      // Content area
      if (this.isLoading) {
        LoadingState()
      } else if (this.isEmpty) {
        EmptyState({ message: '\u8FD8\u6CA1\u6709\u6536\u85CF\u7684\u6761\u76EE\n\u5728\u8BE6\u60C5\u9875\u4E2D\u70B9\u51FB\u2B50\u6536\u85CF\u5E38\u7528\u5185\u5BB9' })
      } else {
        // Favorites list with LazyForEach
        List({ space: 0 }) {
          LazyForEach(
            this.dataSource,
            (entry: ClipboardEntry) => {
              ListItem() {
                ClipboardListItem({
                  entry: entry,
                  onItemClick: (e: ClipboardEntry) => this.onItemClick(e),
                  onItemLongPress: (e: ClipboardEntry) => this.onItemLongPress(e)
                })
              }
              .swipeAction({ end: this.SwipeToDeleteBuilder(entry) })
            },
            (entry: ClipboardEntry) => entry.id.toString()
          )
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

  @Builder
  SwipeToDeleteBuilder(entry: ClipboardEntry) {
    Row() {
      Button('\u53D6\u6D88\u6536\u85CF')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(Color.White)
        .backgroundColor(ThemeTokens.WARNING)
        .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
        .width(80)
        .height(ThemeTokens.LIST_ITEM_HEIGHT)
        .onClick(() => {
          this.onUnfavorite(entry.id);
        })
    }
  }

  private onItemClick(entry: ClipboardEntry): void {
    // Navigate to detail page - will be implemented with NavRouter
    console.info('[FavoritesPage] Item clicked: ' + entry.id);
  }

  private onItemLongPress(entry: ClipboardEntry): void {
    // Show context menu or quick actions
    console.info('[FavoritesPage] Item long-pressed: ' + entry.id);
  }

  private async onUnfavorite(id: number): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.unfavorite(id);
      this.isEmpty = this.viewModel.isEmpty;
      this.dataSource = new FavoritesDataSource(this.viewModel.favorites);
    }
  }

  private async onSearch(keyword: string): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.search(keyword);
      this.isEmpty = this.viewModel.isEmpty;
      this.dataSource = new FavoritesDataSource(this.viewModel.favorites);
    }
  }
}

/**
 * IDataSource implementation for LazyForEach on the favorites page.
 * Wraps a ClipboardEntry array and notifies listeners on data changes.
 */
class FavoritesDataSource implements IDataSource {
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
    const index: number = this.listeners.indexOf(listener);
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
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }
}
