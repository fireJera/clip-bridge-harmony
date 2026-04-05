import { ClipboardEntry } from '../model/ClipboardEntry';
import { IClipboardRepository } from '../repository/ClipboardRepository';
import { AppConstants } from '../common/constants/AppConstants';

/**
 * ViewModel for the clipboard history list page.
 *
 * Provides reactive state (@Trace) for the UI to observe:
 *   - entries: the current page of clipboard entries displayed in the list.
 *   - isLoading: whether a load/search operation is in progress.
 *   - isEmpty: whether there are no entries at all.
 *   - isSearching: whether the list is filtered by a search keyword.
 *
 * Supports paginated loading (loadMore) and full-text search over
 * the contentPreview field.
 */
@ObservedV2
export class HistoryViewModel {
  private repo: IClipboardRepository;
  private currentPage: number = 0;
  private hasMore: boolean = true;
  private searchKeyword: string = '';

  @Trace entries: ClipboardEntry[] = [];
  @Trace isLoading: boolean = false;
  @Trace isEmpty: boolean = true;
  @Trace isSearching: boolean = false;

  constructor(repo: IClipboardRepository) {
    this.repo = repo;
  }

  /**
   * Loads the first page of clipboard history, resetting all pagination
   * and search state.
   */
  async loadHistory(): Promise<void> {
    this.isLoading = true;
    this.currentPage = 0;
    this.hasMore = true;
    this.isSearching = false;
    this.searchKeyword = '';

    try {
      this.entries = await this.repo.getHistory(0, AppConstants.PAGE_SIZE);
      this.isEmpty = this.entries.length === 0;
      this.currentPage = 1;
    } catch (error) {
      console.error('[HistoryViewModel] Failed to load history: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Loads the next page of entries and appends them to the existing list.
   * Respects the current search filter if one is active.
   */
  async loadMore(): Promise<void> {
    if (!this.hasMore || this.isLoading) {
      return;
    }
    this.isLoading = true;

    try {
      const offset: number = this.currentPage * AppConstants.PAGE_SIZE;
      let newEntries: ClipboardEntry[];

      if (this.isSearching) {
        newEntries = await this.repo.search(this.searchKeyword, offset, AppConstants.PAGE_SIZE);
      } else {
        newEntries = await this.repo.getHistory(offset, AppConstants.PAGE_SIZE);
      }

      if (newEntries.length < AppConstants.PAGE_SIZE) {
        this.hasMore = false;
      }
      this.entries = [...this.entries, ...newEntries];
      this.currentPage++;
    } catch (error) {
      console.error('[HistoryViewModel] Failed to load more: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Searches clipboard entries by keyword. Resets pagination state.
   * If the keyword is empty, falls back to loadHistory().
   *
   * @param keyword - The search string to match against contentPreview.
   */
  async search(keyword: string): Promise<void> {
    if (!keyword.trim()) {
      await this.loadHistory();
      return;
    }

    this.isLoading = true;
    this.searchKeyword = keyword;
    this.isSearching = true;
    this.currentPage = 0;
    this.hasMore = true;

    try {
      this.entries = await this.repo.search(keyword, 0, AppConstants.PAGE_SIZE);
      this.isEmpty = this.entries.length === 0;
      this.currentPage = 1;
    } catch (error) {
      console.error('[HistoryViewModel] Failed to search: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Clears the active search filter and reloads the full history.
   */
  clearSearch(): void {
    this.loadHistory();
  }

  /**
   * Deletes a single clipboard entry by id and removes it from the
   * current in-memory list without a full reload.
   *
   * @param id - The database id of the entry to delete.
   */
  async deleteEntry(id: number): Promise<void> {
    await this.repo.deleteById(id);
    this.entries = this.entries.filter((e: ClipboardEntry): boolean => e.id !== id);
  }

  /**
   * Toggles the pinned state of an entry and reloads history to
   * reflect the new sort order.
   *
   * @param entry - The entry to pin/unpin.
   */
  async togglePin(entry: ClipboardEntry): Promise<void> {
    const newPinState: boolean = !entry.isPinned;
    await this.repo.updatePin(entry.id, newPinState);
    entry.isPinned = newPinState;
    // Refresh to update sort order (pinned entries float to top)
    await this.loadHistory();
  }
}
