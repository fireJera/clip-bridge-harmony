import { ClipboardEntry } from '../model/ClipboardEntry';
import { IClipboardRepository } from '../repository/ClipboardRepository';
import { AppConstants } from '../common/constants/AppConstants';

/**
 * ViewModel for the favorites page.
 *
 * Provides reactive state (@Trace) for the UI to observe:
 *   - favorites: the current page of favorited clipboard entries.
 *   - isLoading: whether a load/search operation is in progress.
 *   - isEmpty: whether there are no favorite entries.
 *   - searchKeyword: the current search filter keyword.
 *
 * Supports paginated loading (loadMore), unfavorite, delete, and
 * search over the contentPreview field within favorites only.
 */
@ObservedV2
export class FavoritesViewModel {
  private repo: IClipboardRepository;
  private currentPage: number = 0;
  private hasMore: boolean = true;

  @Trace favorites: ClipboardEntry[] = [];
  @Trace isLoading: boolean = false;
  @Trace isEmpty: boolean = true;
  @Trace searchKeyword: string = '';

  constructor(repo: IClipboardRepository) {
    this.repo = repo;
  }

  /**
   * Loads the first page of favorite entries, resetting all pagination
   * and search state.
   */
  async loadFavorites(): Promise<void> {
    this.isLoading = true;
    this.currentPage = 0;
    this.hasMore = true;
    this.searchKeyword = '';

    try {
      this.favorites = await this.repo.getFavorites(0, AppConstants.PAGE_SIZE);
      this.isEmpty = this.favorites.length === 0;
      this.currentPage = 1;
    } catch (error) {
      console.error('[FavoritesViewModel] Failed to load favorites: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Loads the next page of favorite entries and appends them to the
   * existing list.
   */
  async loadMore(): Promise<void> {
    if (!this.hasMore || this.isLoading) {
      return;
    }
    this.isLoading = true;

    try {
      const offset: number = this.currentPage * AppConstants.PAGE_SIZE;
      const newEntries: ClipboardEntry[] = await this.repo.getFavorites(offset, AppConstants.PAGE_SIZE);

      if (newEntries.length < AppConstants.PAGE_SIZE) {
        this.hasMore = false;
      }
      this.favorites = [...this.favorites, ...newEntries];
      this.currentPage++;
    } catch (error) {
      console.error('[FavoritesViewModel] Failed to load more: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Removes the entry from favorites (sets isFavorite to false in the database)
   * and removes it from the in-memory list without a full reload.
   *
   * @param id - The database id of the entry to unfavorite.
   */
  async unfavorite(id: number): Promise<void> {
    await this.repo.updateFavorite(id, false);
    this.favorites = this.favorites.filter((e: ClipboardEntry): boolean => e.id !== id);
    this.isEmpty = this.favorites.length === 0;
  }

  /**
   * Deletes a single clipboard entry by id and removes it from the
   * current in-memory list without a full reload.
   *
   * @param id - The database id of the entry to delete.
   */
  async deleteEntry(id: number): Promise<void> {
    await this.repo.deleteById(id);
    this.favorites = this.favorites.filter((e: ClipboardEntry): boolean => e.id !== id);
    this.isEmpty = this.favorites.length === 0;
  }

  /**
   * Searches within favorite entries by keyword. Resets pagination state.
   * If the keyword is empty, falls back to loadFavorites().
   *
   * Note: Uses the general search which covers all entries, then filters
   * to favorites only. For a true favorites-only search, we load all
   * favorites and filter locally since the DAO search method queries all entries.
   *
   * @param keyword - The search string to match against contentPreview.
   */
  async search(keyword: string): Promise<void> {
    if (!keyword.trim()) {
      await this.loadFavorites();
      return;
    }

    this.isLoading = true;
    this.searchKeyword = keyword;
    this.currentPage = 0;
    this.hasMore = true;

    try {
      const allFavorites: ClipboardEntry[] = await this.repo.getFavorites(0, AppConstants.MAX_HISTORY_LIMIT);
      const lowerKeyword: string = keyword.toLowerCase();
      const filtered: ClipboardEntry[] = allFavorites.filter((e: ClipboardEntry): boolean => {
        return e.contentPreview.toLowerCase().includes(lowerKeyword);
      });
      this.favorites = filtered;
      this.isEmpty = this.favorites.length === 0;
      this.currentPage = 1;
      this.hasMore = false; // local filter, no pagination
    } catch (error) {
      console.error('[FavoritesViewModel] Failed to search favorites: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }
}
