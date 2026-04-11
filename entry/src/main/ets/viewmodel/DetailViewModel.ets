import { pasteboard } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { CustomCategory } from '../model/CustomCategory';
import { IClipboardRepository } from '../repository/ClipboardRepository';
import { ICategoryRepository } from '../repository/CategoryRepository';
import { EncryptionService } from '../service/EncryptionService';
import { AppContext } from '../common/utils/AppContext';

/**
 * ViewModel for the clipboard entry detail page.
 *
 * Manages loading a single entry, decrypting its content, and providing
 * actions such as copy-to-clipboard, pin toggle, favorite toggle, delete,
 * and custom tag management.
 *
 * Reactive state (@Trace):
 *   - entry: the currently loaded ClipboardEntry (null until loaded).
 *   - decryptedContent: the AES-256-GCM decrypted plain-text content.
 *   - isLoading: whether an async operation is in progress.
 *   - isCopied: transient flag set for 2 seconds after a successful copy.
 *   - categories: all custom categories (for tag picker).
 *   - entryTags: tags applied to the current entry.
 */
@ObservedV2
export class DetailViewModel {
  private repo: IClipboardRepository;
  private categoryRepo: ICategoryRepository;
  private encryptionService: EncryptionService;

  @Trace entry: ClipboardEntry | null = null;
  @Trace decryptedContent: string = '';
  @Trace isLoading: boolean = false;
  @Trace isCopied: boolean = false;
  @Trace categories: CustomCategory[] = [];
  @Trace entryTags: CustomCategory[] = [];
  @Trace editedContent: string = '';      // Current text in the editor
  @Trace isDirty: boolean = false;        // editedContent !== decryptedContent
  @Trace isSaving: boolean = false;       // Save in progress
  @Trace isNotFound: boolean = false;     // Entry was deleted externally
  @Trace note: string = '';               // User note for this entry

  constructor(
    repo: IClipboardRepository,
    categoryRepo: ICategoryRepository,
    encryptionService: EncryptionService
  ) {
    this.repo = repo;
    this.categoryRepo = categoryRepo;
    this.encryptionService = encryptionService;
  }

  /**
   * Loads a clipboard entry by id and decrypts its encrypted content.
   *
   * @param id - The database id of the entry to load.
   */
  async loadEntry(id: number): Promise<void> {
    this.isLoading = true;
    try {
      this.entry = await this.repo.getById(id);
      console.info('[DetailViewModel] loadEntry step1 getById OK');
    } catch (error) {
      console.error('[DetailViewModel] loadEntry step1 getById FAILED: ' + JSON.stringify(error));
      this.isLoading = false;
      return;
    }

    try {
      if (this.entry === null) {
        this.isNotFound = true;
        this.isLoading = false;
        return;
      }
      this.isNotFound = false;

      // Decrypt content
      try {
        if (this.entry.contentEncrypted.length > 0) {
          this.decryptedContent = await this.encryptionService.decrypt({
            ciphertext: this.entry.contentEncrypted,
            iv: this.entry.iv,
            authTag: this.entry.authTag
          });
        } else {
          this.decryptedContent = this.entry.contentPreview;
        }
      } catch (e) {
        console.error('[DetailViewModel] loadEntry decrypt FAILED: ' + JSON.stringify(e));
        this.decryptedContent = this.entry.contentPreview;
      }
      console.info('[DetailViewModel] loadEntry decrypt OK');

      this.editedContent = this.decryptedContent;
      this.isDirty = false;
      this.note = this.entry.note ?? '';
      console.info('[DetailViewModel] loadEntry note="' + this.note + '"');

      // Load categories and tags for this entry
      await this.loadCategories();
      console.info('[DetailViewModel] loadEntry categories OK');
      await this.loadEntryTags(id);
      console.info('[DetailViewModel] loadEntry tags OK');
    } catch (error) {
      console.error('[DetailViewModel] loadEntry step2/3 FAILED: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Copies the decrypted content back to the system clipboard.
   * Sets isCopied to true for 2 seconds to provide UI feedback.
   */
  async copyToClipboard(): Promise<void> {
    if (!this.entry) {
      return;
    }

    try {
      if (this.entry.contentType === 'image') {
        const imgPath: string = this.entry.imagePath || this.entry.thumbnailPath;
        if (imgPath) {
          const file = fs.openSync(imgPath, fs.OpenMode.READ_ONLY);
          const stat = fs.statSync(imgPath);
          const buffer = new ArrayBuffer(stat.size);
          fs.readSync(file.fd, buffer);
          fs.closeSync(file);

          const imageSource: image.ImageSource = image.createImageSource(buffer);
          const pixelMap: image.PixelMap = await imageSource.createPixelMap();
          const pasteData: pasteboard.PasteData = pasteboard.createData(
            pasteboard.MIMETYPE_PIXELMAP, pixelMap
          );
          await pasteboard.getSystemPasteboard().setData(pasteData);
        }
      } else {
        const content: string = this.decryptedContent || this.entry.contentPreview;
        const pasteData: pasteboard.PasteData = pasteboard.createData(
          pasteboard.MIMETYPE_TEXT_PLAIN, content
        );
        await pasteboard.getSystemPasteboard().setData(pasteData);
      }

      this.isCopied = true;
      setTimeout((): void => {
        this.isCopied = false;
      }, 2000);
    } catch (error) {
      console.error('[DetailViewModel] Failed to copy to clipboard: ' + JSON.stringify(error));
    }
  }

  /**
   * Toggles the pinned state of the current entry.
   */
  async togglePin(): Promise<void> {
    if (!this.entry) {
      return;
    }
    try {
      this.entry.isPinned = !this.entry.isPinned;
      await this.repo.updatePin(this.entry.id, this.entry.isPinned);
      AppContext.notifyDataChanged();
    } catch (error) {
      // Revert on failure
      this.entry.isPinned = !this.entry.isPinned;
      console.error('[DetailViewModel] Failed to toggle pin: ' + JSON.stringify(error));
    }
  }

  /**
   * Toggles the favorite state of the current entry.
   */
  async toggleFavorite(): Promise<void> {
    if (!this.entry) {
      return;
    }
    try {
      this.entry.isFavorite = !this.entry.isFavorite;
      await this.repo.updateFavorite(this.entry.id, this.entry.isFavorite);
      AppContext.notifyDataChanged();
    } catch (error) {
      // Revert on failure
      this.entry.isFavorite = !this.entry.isFavorite;
      console.error('[DetailViewModel] Failed to toggle favorite: ' + JSON.stringify(error));
    }
  }

  /**
   * Deletes the current entry from the database.
   *
   * @returns true if the entry was deleted, false if no entry was loaded.
   */
  async deleteEntry(): Promise<boolean> {
    if (!this.entry) {
      return false;
    }
    try {
      await this.repo.deleteById(this.entry.id);
      AppContext.notifyDataChanged();
      return true;
    } catch (error) {
      console.error('[DetailViewModel] Failed to delete entry: ' + JSON.stringify(error));
      return false;
    }
  }

  // ── Editing methods ──────────────────────────────────────────────────

  /**
   * Called when the user edits content in the text area.
   * Updates the edited content and tracks dirty state.
   *
   * @param newText - The current text in the editor.
   */
  onContentEdited(newText: string): void {
    this.editedContent = newText;
    this.isDirty = (newText !== this.decryptedContent);
  }

  /**
   * Saves the edited content back to the repository (re-encrypted).
   * Refreshes the entry from the database after saving.
   */
  async saveContent(): Promise<void> {
    if (this.entry === null) {
      return;
    }
    const newContent: string = this.editedContent;
    if (newContent === this.decryptedContent) {
      this.isDirty = false;
      return;
    }
    this.isSaving = true;
    try {
      await this.repo.updateContent(this.entry.id, newContent);
      // Update display directly — no need to re-decrypt
      this.decryptedContent = newContent;
      this.editedContent = newContent;
      this.isDirty = false;
      // Refresh entry metadata (updatedAt etc.)
      this.entry = await this.repo.getById(this.entry.id);
      AppContext.notifyDataChanged();
    } catch (error) {
      console.error('[DetailViewModel] Failed to save content: ' + JSON.stringify(error));
    } finally {
      this.isSaving = false;
    }
  }

  /**
   * Reverts the editor content back to the last saved/decrypted content.
   */
  revertContent(): void {
    this.editedContent = this.decryptedContent;
    this.isDirty = false;
  }

  /**
   * Saves the user note to the repository.
   */
  async saveNote(note: string): Promise<void> {
    if (!this.entry) {
      console.error('[DetailViewModel] saveNote: entry is null, skip');
      return;
    }
    this.note = note;
    try {
      await this.repo.updateNote(this.entry.id, note);
      AppContext.notifyDataChanged();
      console.info('[DetailViewModel] saveNote OK: id=' + this.entry.id + ' note=' + note);
    } catch (error) {
      console.error('[DetailViewModel] saveNote FAILED: ' + JSON.stringify(error));
    }
  }

  /**
   * Returns whether the editor has unsaved changes.
   */
  isEntryDirty(): boolean {
    return this.isDirty;
  }

  // ── Category / tag methods ──────────────────────────────────────────

  /**
   * Loads all custom categories (for the tag picker).
   */
  async loadCategories(): Promise<void> {
    try {
      this.categories = await this.categoryRepo.getAll();
    } catch (error) {
      console.error('[DetailViewModel] Failed to load categories: ' + JSON.stringify(error));
    }
  }

  /**
   * Loads the tags applied to a specific entry.
   *
   * @param entryId - The entry to load tags for.
   */
  async loadEntryTags(entryId: number): Promise<void> {
    try {
      this.entryTags = await this.categoryRepo.getTagsForEntry(entryId);
    } catch (error) {
      console.error('[DetailViewModel] Failed to load entry tags: ' + JSON.stringify(error));
    }
  }

  /**
   * Returns tags for a specific entry (used by DetailPage).
   *
   * @param entryId - The entry to get tags for.
   */
  async getTagsForEntry(entryId: number): Promise<CustomCategory[]> {
    try {
      return await this.categoryRepo.getTagsForEntry(entryId);
    } catch (error) {
      console.error('[DetailViewModel] Failed to get tags for entry: ' + JSON.stringify(error));
      return [];
    }
  }

  /**
   * Adds a custom tag to the current entry.
   *
   * @param entryId - The entry ID.
   * @param categoryId - The category to tag with.
   */
  async addTagToEntry(entryId: number, categoryId: number): Promise<void> {
    try {
      await this.categoryRepo.addTag(entryId, categoryId);
      await this.loadEntryTags(entryId);
    } catch (error) {
      console.error('[DetailViewModel] Failed to add tag: ' + JSON.stringify(error));
    }
  }

  /**
   * Removes a custom tag from the current entry.
   *
   * @param entryId - The entry ID.
   * @param categoryId - The category to remove.
   */
  async removeTagFromEntry(entryId: number, categoryId: number): Promise<void> {
    try {
      await this.categoryRepo.removeTag(entryId, categoryId);
      await this.loadEntryTags(entryId);
    } catch (error) {
      console.error('[DetailViewModel] Failed to remove tag: ' + JSON.stringify(error));
    }
  }

  /**
   * Returns a human-readable label for the entry's content type.
   */
  getTypeLabel(): string {
    if (!this.entry) {
      return '';
    }
    const labels: Record<string, string> = {
      'text': '文本',
      'url': '链接',
      'email': '邮箱',
      'phone': '电话',
      'image': '图片',
      'address': '地址'
    };
    return labels[this.entry.contentType] || '文本';
  }

  /**
   * Formats an ISO-8601 timestamp string to a readable date/time display.
   */
  formatTime(isoString: string): string {
    if (!isoString) {
      return '';
    }
    try {
      const date: Date = new Date(isoString);
      const year: string = date.getFullYear().toString();
      const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
      const day: string = date.getDate().toString().padStart(2, '0');
      const hours: string = date.getHours().toString().padStart(2, '0');
      const minutes: string = date.getMinutes().toString().padStart(2, '0');
      return `${year}-${month}-${day} ${hours}:${minutes}`;
    } catch (e) {
      return isoString;
    }
  }
}
