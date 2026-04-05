import { HistoryViewModel } from '../viewmodel/HistoryViewModel';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { ClipboardListItem } from '../component/ClipboardListItem';
import { EmptyState } from '../component/EmptyState';
import { LoadingState } from '../component/LoadingState';
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Main history page showing the list of clipboard entries.
 * Uses LazyForEach with IDataSource for performant rendering.
 *
 * The viewModel is initialized by the parent (Index). When the repository
 * layer is fully wired up, the parent will construct HistoryViewModel with
 * the appropriate IClipboardRepository implementation and pass it in.
 */
@Component
export struct HistoryPage {
  @State isLoading: boolean = true;
  @State isEmpty: boolean = true;
  @State dataSource: HistoryDataSource = new HistoryDataSource([]);
  private viewModel: HistoryViewModel | null = null;

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
      await this.viewModel.loadHistory();
      this.isLoading = this.viewModel.isLoading;
      this.isEmpty = this.viewModel.isEmpty;
      this.dataSource = new HistoryDataSource(this.viewModel.entries);
    } else {
      // No repository wired yet - show empty state
      this.isLoading = false;
      this.isEmpty = true;
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
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
      .alignItems(VerticalAlign.Center)

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
              ClipboardListItem({
                entry: entry,
                onItemClick: (e: ClipboardEntry) => this.onItemClick(e),
                onItemLongPress: (e: ClipboardEntry) => this.onItemLongPress(e)
              })
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

  private onItemClick(entry: ClipboardEntry): void {
    // Navigate to detail page - will be implemented with NavRouter
    console.info('Item clicked: ' + entry.id);
  }

  private onItemLongPress(entry: ClipboardEntry): void {
    // Show context menu or quick actions
    console.info('Item long-pressed: ' + entry.id);
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
