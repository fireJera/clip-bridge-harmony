import { ClipboardEntry } from '../model/ClipboardEntry';
import { CustomCategory } from '../model/CustomCategory';
import { ICategoryRepository } from '../repository/CategoryRepository';
import { AppConstants } from '../common/constants/AppConstants';

/**
 * ViewModel for the favorites page.
 *
 * Shows entries that belong to at least one folder (收藏夹).
 * Supports folder-based filtering via a horizontal chip bar.
 *
 * Reactive state (@Trace):
 *   - entries: the current page of entries in folders.
 *   - folders: all user-created folders (for filter bar).
 *   - activeFolderId: currently selected folder filter (null = all).
 *   - isLoading, isEmpty: loading and empty states.
 */
@ObservedV2
export class FavoritesViewModel {
  private categoryRepo: ICategoryRepository;
  private currentPage: number = 0;
  private hasMore: boolean = true;

  @Trace entries: ClipboardEntry[] = [];
  @Trace folders: CustomCategory[] = [];
  @Trace activeFolderId: number | null = null;
  @Trace isLoading: boolean = false;
  @Trace isEmpty: boolean = true;

  constructor(categoryRepo: ICategoryRepository) {
    this.categoryRepo = categoryRepo;
  }

  /**
   * Loads folders and the first page of entries.
   * If a folder filter is active, loads entries for that folder only.
   */
  async loadEntries(): Promise<void> {
    this.isLoading = true;
    this.currentPage = 0;
    this.hasMore = true;

    try {
      await this.loadFolders();
      await this.loadCurrentPage();
    } catch (error) {
      console.error('[FavoritesViewModel] Failed to load entries: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Loads all user-created folders for the filter bar.
   */
  async loadFolders(): Promise<void> {
    try {
      this.folders = await this.categoryRepo.getAll();
      if (this.activeFolderId === null && this.folders.length > 0) {
        this.activeFolderId = this.folders[0].id;
      }
    } catch (error) {
      console.error('[FavoritesViewModel] Failed to load folders: ' + JSON.stringify(error));
    }
  }

  /**
   * Sets the folder filter and reloads entries.
   * Pass null to show entries from all folders.
   */
  async filterByFolder(folderId: number | null): Promise<void> {
    this.activeFolderId = folderId;
    await this.loadEntries();
  }

  /**
   * Loads the next page and appends to the list.
   */
  async loadMore(): Promise<void> {
    if (!this.hasMore || this.isLoading) {
      return;
    }
    this.isLoading = true;

    try {
      const offset: number = this.currentPage * AppConstants.PAGE_SIZE;
      const newEntries: ClipboardEntry[] = await this.fetchEntries(offset, AppConstants.PAGE_SIZE);

      if (newEntries.length < AppConstants.PAGE_SIZE) {
        this.hasMore = false;
      }
      this.entries = [...this.entries, ...newEntries];
      this.currentPage++;
    } catch (error) {
      console.error('[FavoritesViewModel] Failed to load more: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Removes an entry from the specified folder.
   * After removal, reloads the list.
   */
  async removeFromFolder(entryId: number, folderId: number): Promise<void> {
    try {
      await this.categoryRepo.removeTag(entryId, folderId);
      await this.loadEntries();
    } catch (error) {
      console.error('[FavoritesViewModel] Failed to remove from folder: ' + JSON.stringify(error));
    }
  }

  /**
   * Removes an entry from the current view by reloading.
   * Actual deletion is handled by the caller through the clipboard repo.
   */
  async refreshAfterDelete(): Promise<void> {
    await this.loadEntries();
  }

  // ── Private helpers ──────────────────────────────────────────────────

  private async loadCurrentPage(): Promise<void> {
    const newEntries: ClipboardEntry[] = await this.fetchEntries(0, AppConstants.PAGE_SIZE);
    this.entries = newEntries;
    this.isEmpty = this.entries.length === 0;
    this.currentPage = 1;
  }

  private async fetchEntries(offset: number, limit: number): Promise<ClipboardEntry[]> {
    if (this.activeFolderId !== null) {
      return await this.categoryRepo.getEntriesByCategory(this.activeFolderId, offset, limit);
    } else {
      return await this.categoryRepo.getEntriesInAnyFolder(offset, limit);
    }
  }
}
