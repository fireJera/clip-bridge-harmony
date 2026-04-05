import { pasteboard } from '@kit.BasicServicesKit';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { IClipboardRepository } from '../repository/ClipboardRepository';
import { EncryptionService } from '../service/EncryptionService';

/**
 * ViewModel for the clipboard entry detail page.
 *
 * Manages loading a single entry, decrypting its content, and providing
 * actions such as copy-to-clipboard, pin toggle, favorite toggle, and delete.
 *
 * Reactive state (@Trace):
 *   - entry: the currently loaded ClipboardEntry (null until loaded).
 *   - decryptedContent: the AES-256-GCM decrypted plain-text content.
 *   - isLoading: whether an async operation is in progress.
 *   - isCopied: transient flag set for 2 seconds after a successful copy.
 */
@ObservedV2
export class DetailViewModel {
  private repo: IClipboardRepository;
  private encryptionService: EncryptionService;

  @Trace entry: ClipboardEntry | null = null;
  @Trace decryptedContent: string = '';
  @Trace isLoading: boolean = false;
  @Trace isCopied: boolean = false;

  constructor(repo: IClipboardRepository, encryptionService: EncryptionService) {
    this.repo = repo;
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
      if (this.entry && this.entry.contentEncrypted.length > 0) {
        this.decryptedContent = await this.encryptionService.decrypt({
          ciphertext: this.entry.contentEncrypted,
          iv: this.entry.iv,
          authTag: this.entry.authTag
        });
      } else if (this.entry) {
        // Fallback to preview if no encrypted content (edge case)
        this.decryptedContent = this.entry.contentPreview;
      }
    } catch (error) {
      console.error('[DetailViewModel] Failed to load entry: ' + JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Copies the decrypted content back to the system clipboard.
   * Sets isCopied to true for 2 seconds to provide UI feedback.
   */
  async copyToClipboard(): Promise<void> {
    if (!this.decryptedContent && !this.entry) {
      return;
    }

    const content: string = this.decryptedContent || this.entry!.contentPreview;
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(
        pasteboard.MIMETYPE_TEXT_PLAIN,
        content
      );
      await pasteboard.getSystemPasteboard().setData(pasteData);

      this.isCopied = true;
      // Reset feedback flag after 2 seconds
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
      return true;
    } catch (error) {
      console.error('[DetailViewModel] Failed to delete entry: ' + JSON.stringify(error));
      return false;
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
