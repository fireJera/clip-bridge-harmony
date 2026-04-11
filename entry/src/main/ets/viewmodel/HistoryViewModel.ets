import { ClipboardEntry } from '../model/ClipboardEntry';
import { CustomCategory } from '../model/CustomCategory';
import { IClipboardRepository } from '../repository/ClipboardRepository';
import { ICategoryRepository } from '../repository/CategoryRepository';
import { AppConstants } from '../common/constants/AppConstants';

/**
 * ViewModel for the clipboard history list page.
 *
 * Provides reactive state (@Trace) for the UI to observe:
 *   - entries: the current page of clipboard entries displayed in the list.
 *   - isLoading: whether a load/search operation is in progress.
 *   - isEmpty: whether there are no entries at all.
 *   - isSearching: whether the list is filtered by a search keyword.
 *   - categories: all user-defined custom categories.
 *   - activeTypeFilters: content types currently selected for filtering.
 *   - activeCategoryFilters: category IDs currently selected for filtering.
 *
 * Supports paginated loading (loadMore), full-text search over
 * the contentPreview field, and filtering by content type and custom tags.
 */
@ObservedV2
export class HistoryViewModel {
  private repo: IClipboardRepository;
  private categoryRepo: ICategoryRepository;
  private currentPage: number = 0;
  private hasMore: boolean = true;
  private searchKeyword: string = '';

  @Trace entries: ClipboardEntry[] = [];
  @Trace isLoading: boolean = false;
  @Trace isEmpty: boolean = true;
  @Trace isSearching: boolean = false;
  @Trace categories: CustomCategory[] = [];
  @Trace activeTypeFilters: string[] = [];
  @Trace activeCategoryFilters: number[] = [];

  constructor(repo: IClipboardRepository, categoryRepo: ICategoryRepository) {
    this.repo = repo;
    this.categoryRepo = categoryRepo;
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
      await this.populateTags(this.entries);
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
      await this.populateTags(newEntries);
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
      await this.populateTags(this.entries);
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
   * Updates the pinned state of an entry in the DB only.
   * Does NOT reload the entries list — caller handles UI state locally.
   *
   * @param id - The database id of the entry.
   * @param pinned - The new pinned state.
   */
  async updatePin(id: number, pinned: boolean): Promise<void> {
    await this.repo.updatePin(id, pinned);
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

  /**
   * Updates the favorite state of an entry in the DB only.
   * Does NOT reload the entries list — caller handles UI state locally.
   */
  async updateFavorite(id: number, favorited: boolean): Promise<void> {
    await this.repo.updateFavorite(id, favorited);
  }

  /**
   * Deletes multiple clipboard entries by their ids and removes them
   * from the current in-memory list without a full reload.
   *
   * @param ids - Array of database ids to delete.
   */
  async deleteBatch(ids: number[]): Promise<void> {
    if (ids.length === 0) {
      return;
    }
    await this.repo.deleteByIds(ids);
    const idSet: Set<number> = new Set(ids);
    this.entries = this.entries.filter((e: ClipboardEntry): boolean => !idSet.has(e.id));
    this.isEmpty = this.entries.length === 0;
  }

  /**
   * Deletes all clipboard entries and resets the in-memory list.
   */
  async clearAll(): Promise<void> {
    await this.repo.deleteAll();
    this.entries = [];
    this.isEmpty = true;
    this.currentPage = 0;
    this.hasMore = true;
    this.isSearching = false;
    this.searchKeyword = '';
  }

  // ── Category management ─────────────────────────────────────────────

  /**
   * Loads all custom categories from the repository.
   */
  async loadCategories(): Promise<void> {
    try {
      this.categories = await this.categoryRepo.getAll();
    } catch (error) {
      console.error('[HistoryViewModel] Failed to load categories: ' + JSON.stringify(error));
    }
  }

  /**
   * Creates a new custom category. Enforces the 50-category limit.
   *
   * @param name - Display name of the new category.
   * @param color - Optional hex color string.
   */
  async createCategory(name: string, color?: string): Promise<void> {
    try {
      const currentCount: number = await this.categoryRepo.count();
      if (currentCount >= AppConstants.MAX_CATEGORIES) {
        console.error('[HistoryViewModel] Maximum categories limit reached');
        return;
      }
      await this.categoryRepo.create(name, color);
      await this.loadCategories();
    } catch (error) {
      console.error('[HistoryViewModel] Failed to create category: ' + JSON.stringify(error));
    }
  }

  /**
   * Renames an existing custom category.
   *
   * @param id - Category ID to rename.
   * @param name - New display name.
   */
  async renameCategory(id: number, name: string): Promise<void> {
    try {
      const cat: CustomCategory | null = await this.categoryRepo.getById(id);
      if (cat) {
        await this.categoryRepo.update(id, name, cat.color);
        await this.loadCategories();
      }
    } catch (error) {
      console.error('[HistoryViewModel] Failed to rename category: ' + JSON.stringify(error));
    }
  }

  /**
   * Deletes a custom category and removes its tag associations.
   *
   * @param id - Category ID to delete.
   */
  async deleteCategory(id: number): Promise<void> {
    try {
      await this.categoryRepo.delete(id);
      await this.loadCategories();
      // Remove the deleted category from active filters if present
      this.activeCategoryFilters = this.activeCategoryFilters.filter(
        (cid: number): boolean => cid !== id
      );
    } catch (error) {
      console.error('[HistoryViewModel] Failed to delete category: ' + JSON.stringify(error));
    }
  }

  /**
   * Adds a custom tag to a clipboard entry.
   *
   * @param entryId - The clipboard entry ID.
   * @param categoryId - The category to tag the entry with.
   */
  async addTagToEntry(entryId: number, categoryId: number): Promise<void> {
    try {
      await this.categoryRepo.addTag(entryId, categoryId);
    } catch (error) {
      console.error('[HistoryViewModel] Failed to add tag: ' + JSON.stringify(error));
    }
  }

  /**
   * Removes a custom tag from a clipboard entry.
   *
   * @param entryId - The clipboard entry ID.
   * @param categoryId - The category to remove from the entry.
   */
  async removeTagFromEntry(entryId: number, categoryId: number): Promise<void> {
    try {
      await this.categoryRepo.removeTag(entryId, categoryId);
    } catch (error) {
      console.error('[HistoryViewModel] Failed to remove tag: ' + JSON.stringify(error));
    }
  }

  /**
   * Filters entries by auto-detected content type.
   * Applies combined with category filters and search via applyFilters().
   *
   * @param types - Array of ContentType strings to filter by.
   */
  async filterByType(types: string[]): Promise<void> {
    this.activeTypeFilters = types;
    await this.applyFilters();
  }

  /**
   * Filters entries by custom category tags.
   * Applies combined with type filters and search via applyFilters().
   *
   * @param categoryIds - Array of category IDs to filter by.
   */
  async filterByCategory(categoryIds: number[]): Promise<void> {
    this.activeCategoryFilters = categoryIds;
    await this.applyFilters();
  }

  /**
   * Applies all active filters (type + category + search) to produce
   * the filtered entries list. The intersection logic is:
   *   - If type filters are active, entries must match at least one type.
   *   - If category filters are active, entries must be tagged with at least one.
   *   - If search is active, entries must match the search keyword.
   *   - All conditions are ANDed together.
   */
  async applyFilters(): Promise<void> {
    this.isLoading = true;
    this.currentPage = 0;
    this.hasMore = true;

    try {
      let result: ClipboardEntry[] = [];

      // Step 1: Start with search results or full history
      if (this.isSearching && this.searchKeyword.trim()) {
        result = await this.repo.search(this.searchKeyword, 0, AppConstants.MAX_HISTORY_LIMIT);
      } else {
        result = await this.repo.getHistory(0, AppConstants.MAX_HISTORY_LIMIT);
      }

      // Step 2: Apply type filter
      if (this.activeTypeFilters.length > 0) {
        const typeSet: Set<string> = new Set(this.activeTypeFilters);
        result = result.filter((e: ClipboardEntry): boolean => typeSet.has(e.contentType));
      }

      // Step 3: Apply category filter
      if (this.activeCategoryFilters.length > 0) {
        const filteredByCategory: ClipboardEntry[] = [];
        for (const catId of this.activeCategoryFilters) {
          const tagged: ClipboardEntry[] = await this.categoryRepo.getEntriesByCategory(
            catId, 0, AppConstants.MAX_HISTORY_LIMIT
          );
          filteredByCategory.push(...tagged);
        }
        // Intersect with current result
        const catEntryIds: Set<number> = new Set(filteredByCategory.map((e: ClipboardEntry): number => e.id));
        result = result.filter((e: ClipboardEntry): boolean => catEntryIds.has(e.id));
      }

      this.entries = result;
      await this.populateTags(this.entries);
      this.isEmpty = this.entries.length === 0;
      this.currentPage = 1;
    } catch (error) {
      console.error('[HistoryViewModel] Failed to apply filters: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Populates the tags (folders) for each entry in the list.
   */
  private async populateTags(entries: ClipboardEntry[]): Promise<void> {
    for (const entry of entries) {
      try {
        entry.tags = await this.categoryRepo.getTagsForEntry(entry.id);
      } catch (e) {
        entry.tags = [];
      }
    }
  }
}
