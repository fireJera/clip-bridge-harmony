import { ClipboardEntry } from '../model/ClipboardEntry';
import { IClipboardRepository } from '../repository/ClipboardRepository';

/**
 * Thin wrapper around ClipboardRepository's dedup logic.
 *
 * While ClipboardRepositoryImpl already has hash-based dedup in its insert method,
 * this service provides a pre-check for the monitor so that duplicate content can
 * be promoted to top without going through a full insert cycle.
 */
export class DeduplicationService {
  private repo: IClipboardRepository;

  constructor(repo: IClipboardRepository) {
    this.repo = repo;
  }

  /**
   * Checks whether a clipboard entry with the given content hash already exists.
   *
   * @param contentHash - SHA-256 hex digest of the clipboard content.
   * @returns The existing ClipboardEntry if found, or null.
   */
  async checkDuplicate(contentHash: string): Promise<ClipboardEntry | null> {
    return await this.repo.findByHash(contentHash);
  }

  /**
   * Promotes an existing entry to the top of the history by touching its timestamp.
   *
   * @param id - The database id of the entry to promote.
   */
  async promoteToTop(id: number): Promise<void> {
    await this.repo.touchTimestamp(id);
  }
}
