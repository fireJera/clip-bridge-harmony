import { FavoritesViewModel } from '../viewmodel/FavoritesViewModel';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { ClipboardListItem } from '../component/ClipboardListItem';
import { EmptyState } from '../component/EmptyState';
import { LoadingState } from '../component/LoadingState';
import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppContext } from '../common/utils/AppContext';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';

/**
 * Favorites page showing the list of favorited clipboard entries.
 * Uses ForEach for reliable UI refresh on state changes.
 * Supports search bar, swipe-to-unfavorite, and toggle favorite.
 */
@Component
export struct FavoritesPage {
  @State isLoading: boolean = true;
  @State isEmpty: boolean = true;
  @State searchKeyword: string = '';
  @State entries: ClipboardEntry[] = [];
  private viewModel: FavoritesViewModel | null = null;
  navPathStack: NavPathStack | null = null;

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
    const clipRepo = AppContext.getClipboardRepo();
    if (clipRepo) {
      hilog.info(0x0000, '[FavoritesPage]', 'repo ready, creating ViewModel');
      this.viewModel = new FavoritesViewModel(clipRepo);
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
      await this.viewModel.loadFavorites();
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
      this.entries = [...this.viewModel.favorites];
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

      // Search bar
      Row() {
        TextInput({ placeholder: '搜索收藏...', text: this.searchKeyword })
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

      // Content area
      if (this.isLoading) {
        LoadingState()
      } else if (this.isEmpty) {
        EmptyState({ message: '还没有收藏的条目\n在历史页点击收藏常用内容' })
      } else {
        List({ space: 0 }) {
          ForEach(this.entries, (entry: ClipboardEntry) => {
            ListItem() {
              ClipboardListItem({
                entry: entry,
                onItemClick: (e: ClipboardEntry) => this.onItemClick(e),
                onItemLongPress: (e: ClipboardEntry) => this.onItemLongPress(e),
                onItemFavorite: (e: ClipboardEntry) => this.onUnfavorite(e)
              })
            }
            .swipeAction({ end: this.SwipeToDeleteBuilder(entry) })
          }, (entry: ClipboardEntry) => `${entry.id}_${entry.isFavorite}`)
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
      Text('取消收藏')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(Color.White)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
    }
    .height('100%')
    .backgroundColor(ThemeTokens.WARNING)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onUnfavorite(entry);
    })
  }

  private onItemClick(entry: ClipboardEntry): void {
    console.info('[FavoritesPage] Item clicked: ' + entry.id);
    if (this.navPathStack) {
      this.navPathStack.pushPath({
        name: 'DetailPage',
        param: { entryId: entry.id }
      });
    }
  }

  private onItemLongPress(entry: ClipboardEntry): void {
    console.info('[FavoritesPage] Item long-pressed: ' + entry.id);
  }

  private async onUnfavorite(entry: ClipboardEntry): Promise<void> {
    if (this.viewModel) {
      promptAction.showToast({ message: '已取消收藏', duration: 1500 });
      await this.viewModel.unfavorite(entry.id);
      this.syncState();
    }
  }

  private async onSearch(keyword: string): Promise<void> {
    if (this.viewModel) {
      await this.viewModel.search(keyword);
      this.syncState();
    }
  }
}
