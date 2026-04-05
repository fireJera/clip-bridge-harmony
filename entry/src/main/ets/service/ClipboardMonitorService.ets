import { pasteboard } from '@kit.BasicServicesKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { IClipboardRepository } from '../repository/ClipboardRepository';
import { ContentTypeDetector, ContentType } from './ContentTypeDetector';
import { DeduplicationService } from './DeduplicationService';
import { EncryptionService } from './EncryptionService';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { AppConstants } from '../common/constants/AppConstants';
import { AppContext } from '../common/utils/AppContext';

const TAG: string = '[ClipboardMonitor]';

/**
 * Core background service that monitors clipboard changes and automatically
 * records clipboard history.
 *
 * Lifecycle:
 *   start() — registers pasteboard on('update') listener and starts a
 *             BackgroundTaskManager continuous task.
 *   stop()  — unregisters the listener and cancels the continuous task.
 *
 * On each clipboard change the service:
 *   1. Reads clipboard content from the system pasteboard.
 *   2. Checks size limits (text >1 MB, images >10 MB are skipped).
 *   3. Detects the semantic content type via ContentTypeDetector.
 *   4. Computes a SHA-256 hash for deduplication.
 *   5. If duplicate: promotes the existing entry to top via touchTimestamp.
 *   6. If new: builds a ClipboardEntry and delegates to ClipboardRepository
 *      which handles encryption and auto-prune.
 */
export class ClipboardMonitorService {
  private repo: IClipboardRepository;
  private typeDetector: ContentTypeDetector;
  private dedupService: DeduplicationService;
  private encryptionService: EncryptionService;
  private systemPasteboard: pasteboard.SystemPasteboard;
  private isMonitoring: boolean = false;
  private isPaused: boolean = false;
  private continuousTaskActive: boolean = false;

  constructor(
    repo: IClipboardRepository,
    encryptionService: EncryptionService
  ) {
    this.repo = repo;
    this.typeDetector = new ContentTypeDetector();
    this.dedupService = new DeduplicationService(repo);
    this.encryptionService = encryptionService;
    this.systemPasteboard = pasteboard.getSystemPasteboard();
  }

  /**
   * Starts monitoring the system clipboard.
   * Registers a pasteboard update listener and begins a continuous background task.
   */
  async start(): Promise<void> {
    if (this.isMonitoring) {
      return;
    }

    // Start continuous background task so the monitor can run while the app
    // is in the background.
    await this.startContinuousTask();

    // Register clipboard change listener
    this.systemPasteboard.on('update', () => {
      this.onClipboardUpdate();
    });

    this.isMonitoring = true;
    this.isPaused = false;
    console.info(`${TAG} Clipboard monitoring started`);
  }

  /**
   * Stops monitoring the system clipboard and cancels the background task.
   */
  async stop(): Promise<void> {
    if (!this.isMonitoring) {
      return;
    }

    this.systemPasteboard.off('update');
    await this.stopContinuousTask();
    this.isMonitoring = false;
    this.isPaused = false;
    console.info(`${TAG} Clipboard monitoring stopped`);
  }

  /**
   * Pauses clipboard monitoring by unregistering the pasteboard listener
   * while keeping the ContinuousTask alive. This is the "privacy mode".
   */
  async pauseMonitoring(): Promise<void> {
    if (!this.isMonitoring || this.isPaused) {
      return;
    }

    this.systemPasteboard.off('update');
    this.isPaused = true;
    // Keep the continuous task active so we can resume without re-requesting
    console.info(`${TAG} Clipboard monitoring paused (privacy mode)`);
  }

  /**
   * Resumes clipboard monitoring by re-registering the pasteboard listener.
   * The ContinuousTask should still be active from before pause.
   */
  async resumeMonitoring(): Promise<void> {
    if (!this.isMonitoring || !this.isPaused) {
      return;
    }

    // Re-register clipboard change listener
    this.systemPasteboard.on('update', () => {
      this.onClipboardUpdate();
    });

    this.isPaused = false;
    console.info(`${TAG} Clipboard monitoring resumed`);
  }

  /**
   * Returns whether monitoring is currently paused (privacy mode active).
   */
  getPaused(): boolean {
    return this.isPaused;
  }

  /**
   * Returns whether the monitor is currently active.
   */
  isRunning(): boolean {
    return this.isMonitoring;
  }

  /**
   * Handler invoked when the system pasteboard content changes.
   */
  private async onClipboardUpdate(): Promise<void> {
    try {
      // 1. Read clipboard data
      const pasteData: pasteboard.PasteData = await this.systemPasteboard.getData();
      if (!pasteData || pasteData.getRecordCount() === 0) {
        return;
      }

      const record: pasteboard.PasteDataRecord = pasteData.getRecordAt(0);
      const mimeType: string = record.mimeType;

      // 2. Extract content based on MIME type and enforce size limits
      let content: string = '';
      let contentSize: number = 0;

      if (mimeType.startsWith('image/')) {
        // Image handling: for v1 we store a placeholder.
        // Full image save-to-file support will come in a later phase.
        content = '[Image]';
        contentSize = 0;
      } else {
        content = record.plainText || '';
        contentSize = new TextEncoder().encode(content).byteLength;

        if (contentSize > AppConstants.TEXT_SIZE_LIMIT) {
          console.info(`${TAG} Skipped oversized text content (${contentSize} bytes)`);
          return;
        }
      }

      // Skip empty content
      if (!content) {
        return;
      }

      // 3. Detect content type
      const contentType: ContentType = this.typeDetector.detect(content, mimeType);

      // 4. Compute hash for deduplication check
      const contentHash: string = await this.encryptionService.hash(content);

      // 5. Check for duplicate
      const existing: ClipboardEntry | null = await this.dedupService.checkDuplicate(contentHash);
      if (existing) {
        // Duplicate found: promote to top and skip insert
        await this.dedupService.promoteToTop(existing.id);
        console.info(`${TAG} Duplicate content promoted to top (id=${existing.id})`);
        return;
      }

      // 6. Build a new ClipboardEntry — raw content goes into rawContent
      //    so that ClipboardRepositoryImpl.insert() can encrypt it.
      const now: string = new Date().toISOString();
      const entry: ClipboardEntry = new ClipboardEntry();
      entry.rawContent = content;
      entry.contentHash = contentHash;
      entry.contentType = contentType;
      entry.contentPreview = content.substring(0, AppConstants.CONTENT_PREVIEW_LENGTH);
      entry.contentSize = contentSize;
      entry.createdAt = now;
      entry.updatedAt = now;

      // 7. Insert via repository (handles encryption + auto-prune)
      const newId: number = await this.repo.insert(entry);
      console.info(`${TAG} New clipboard entry recorded (id=${newId}, type=${contentType})`);

    } catch (err) {
      console.error(`${TAG} Error processing clipboard update: ${err}`);
    }
  }

  /**
   * Starts a BackgroundTaskManager continuous task so the clipboard monitor
   * can keep running while the app is in the background.
   */
  private async startContinuousTask(): Promise<void> {
    if (this.continuousTaskActive) {
      return;
    }
    try {
      const context = AppContext.getContext();
      backgroundTaskManager.startContinuousTask(context, 'dataTransfer', 'Clipboard monitoring');
      this.continuousTaskActive = true;
      console.info(`${TAG} Continuous background task started`);
    } catch (err) {
      console.error(`${TAG} Failed to start continuous task: ${err}`);
    }
  }

  /**
   * Stops the BackgroundTaskManager continuous task.
   */
  private async stopContinuousTask(): Promise<void> {
    if (!this.continuousTaskActive) {
      return;
    }
    try {
      const context = AppContext.getContext();
      backgroundTaskManager.stopContinuousTask(context);
      this.continuousTaskActive = false;
      console.info(`${TAG} Continuous background task stopped`);
    } catch (err) {
      console.error(`${TAG} Failed to stop continuous task: ${err}`);
    }
  }
}
