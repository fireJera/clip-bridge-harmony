import { pasteboard } from '@kit.BasicServicesKit';
import { notificationManager } from '@kit.NotificationKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { util } from '@kit.ArkTS';
import { wantAgent } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { image } from '@kit.ImageKit';
import { IClipboardRepository } from '../repository/ClipboardRepository';
import { ContentTypeDetector, ContentType } from './ContentTypeDetector';
import { DeduplicationService } from './DeduplicationService';
import { EncryptionService } from './EncryptionService';
import { ImageStorageService } from './ImageStorageService';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { AppConstants } from '../common/constants/AppConstants';
import { AppContext } from '../common/utils/AppContext';
import { BlacklistDao } from '../data/database/BlacklistDao';

const TAG: string = '[ClipboardMonitor]';
const DOMAIN: number = 0x0000;

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
  private blacklistDao: BlacklistDao | null;
  private imageStorageService: ImageStorageService | null;
  private systemPasteboard: pasteboard.SystemPasteboard;
  private isMonitoring: boolean = false;
  private isPaused: boolean = false;
  private continuousTaskActive: boolean = false;

  constructor(
    repo: IClipboardRepository,
    encryptionService: EncryptionService,
    blacklistDao: BlacklistDao | null = null,
    imageStorageService: ImageStorageService | null = null
  ) {
    this.repo = repo;
    this.typeDetector = new ContentTypeDetector();
    this.dedupService = new DeduplicationService(repo);
    this.encryptionService = encryptionService;
    this.blacklistDao = blacklistDao;
    this.imageStorageService = imageStorageService;
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
      hilog.info(DOMAIN, TAG, 'pasteboard update event fired');
      this.onClipboardUpdate();
    });

    this.isMonitoring = true;
    this.isPaused = false;
    hilog.info(DOMAIN, TAG, 'Clipboard monitoring started');
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
   * Reads current clipboard content and processes it if new.
   * Called from onForeground() to capture copies that happened while
   * the app was not running or the listener wasn't registered.
   */
  async checkCurrentClipboard(): Promise<void> {
    await this.onClipboardUpdate();
  }

  /**
   * Handler invoked when the system pasteboard content changes.
   */
  private async onClipboardUpdate(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'onClipboardUpdate: start reading pasteboard');

      // 1. Read clipboard data
      const pasteData: pasteboard.PasteData = await this.systemPasteboard.getData();
      if (!pasteData || pasteData.getRecordCount() === 0) {
        hilog.warn(DOMAIN, TAG, 'onClipboardUpdate: pasteData is empty or null');
        return;
      }

      hilog.info(DOMAIN, TAG, 'onClipboardUpdate: got pasteData, recordCount=%{public}d', pasteData.getRecordCount());

      const record: pasteboard.PasteDataRecord = pasteData.getRecordAt(0);
      const mimeType: string = record.mimeType;
      hilog.info(DOMAIN, TAG, 'onClipboardUpdate: mimeType=%{public}s', mimeType);

      // 2. Extract content based on MIME type and enforce size limits
      let content: string = '';
      let contentSize: number = 0;
      let contentHash: string = '';

      if (mimeType.startsWith('image/') || mimeType === 'pixelMap') {
        // --- Image capture: extract PixelMap, save files ---
        let pixelMap: image.PixelMap | null = null;
        try {
          pixelMap = record.pixelMap;
          hilog.info(DOMAIN, TAG, 'record.pixelMap = %{public}s', pixelMap ? 'available' : 'null');
        } catch (e) {
          hilog.warn(DOMAIN, TAG, 'Failed to get PixelMap: %{public}s', JSON.stringify(e));
        }

        // Fallback: try creating PixelMap from URI if pixelMap is null
        if (!pixelMap && record.uri) {
          try {
            hilog.info(DOMAIN, TAG, 'Trying ImageSource from URI: %{public}s', record.uri);
            const imageSource = image.createImageSource(record.uri);
            pixelMap = await imageSource.createPixelMap();
            imageSource.release();
            hilog.info(DOMAIN, TAG, 'PixelMap created from URI OK');
          } catch (e) {
            hilog.warn(DOMAIN, TAG, 'Failed to create PixelMap from URI: %{public}s', JSON.stringify(e));
          }
        }

        // Fallback: search all records for a PixelMap
        if (!pixelMap) {
          const recordCount = pasteData.getRecordCount();
          for (let i = 0; i < recordCount; i++) {
            try {
              const r = pasteData.getRecordAt(i);
              if (r.pixelMap) {
                pixelMap = r.pixelMap;
                hilog.info(DOMAIN, TAG, 'Found PixelMap in record %{public}d', i);
                break;
              }
            } catch (e) {
              // skip
            }
          }
        }

        if (!pixelMap) {
          hilog.warn(DOMAIN, TAG, 'No PixelMap available from any record, saving as placeholder');
          // Fall through to create a text-based placeholder entry
          content = '[Image]';
          contentSize = 0;
          // Don't return — let it create a basic entry below
        } else {
          // Compute hash from pixel data for proper per-image dedup
          const imgInfo = await pixelMap.getImageInfo();
          const pixelBytes = new Uint8Array(imgInfo.size.width * imgInfo.size.height * 4);
          await pixelMap.readPixelsToBuffer(pixelBytes.buffer);
          contentHash = await this.encryptionService.hashBytes(pixelBytes);
          content = `[Image ${imgInfo.size.width}x${imgInfo.size.height}]`;
          contentSize = pixelBytes.byteLength;

          hilog.info(DOMAIN, TAG, 'Image: %{public}dx%{public}d, %{public}d bytes',
            imgInfo.size.width, imgInfo.size.height, contentSize);

          // Enforce image size limit
          if (contentSize > AppConstants.IMAGE_SIZE_LIMIT) {
            try { pixelMap.release(); } catch (e) { /* ignore */ }
            this.sendOversizeNotification('图片过大', contentSize, AppConstants.IMAGE_SIZE_LIMIT);
            return;
          }

          // Save image files
          let savedImagePath: string = '';
          let savedThumbnailPath: string = '';
          if (this.imageStorageService) {
            try {
              const tempId = Date.now();
              savedImagePath = await this.imageStorageService.saveImage(pixelMap, tempId);
              savedThumbnailPath = await this.imageStorageService.generateThumbnail(pixelMap, tempId);
              hilog.info(DOMAIN, TAG, 'Image files saved: img=%{public}s', savedImagePath ? 'yes' : 'no');
            } catch (imgErr) {
              hilog.error(DOMAIN, TAG, 'Image save failed: %{public}s', JSON.stringify(imgErr));
            }
          }
          try { pixelMap.release(); } catch (e) { /* ignore */ }

          // Dedup check
          const existing: ClipboardEntry | null = await this.dedupService.checkDuplicate(contentHash);
          if (existing) {
            await this.dedupService.promoteToTop(existing.id);
            AppContext.notifyDataChanged();
            return;
          }

          const now: string = new Date().toISOString();
          const entry: ClipboardEntry = new ClipboardEntry();
          entry.rawContent = content;
          entry.contentHash = contentHash;
          entry.contentType = 'image';
          entry.contentPreview = content;
          entry.contentSize = contentSize;
          entry.imagePath = savedImagePath;
          entry.thumbnailPath = savedThumbnailPath;
          entry.createdAt = now;
          entry.updatedAt = now;

          const newId: number = await this.repo.insert(entry);
          hilog.info(DOMAIN, TAG, 'Image entry saved (id=%{public}d)', newId);
          AppContext.notifyDataChanged();
          return;
        }
      } else {
        content = record.plainText ?? '';
        if (content.length > 0) {
          contentSize = new util.TextEncoder().encode(content).byteLength;
          hilog.info(DOMAIN, TAG, 'onClipboardUpdate: text content size=%{public}d', contentSize);

          if (contentSize > AppConstants.TEXT_SIZE_LIMIT) {
            console.info(`${TAG} Skipped oversized text content (${contentSize} bytes)`);
            this.sendOversizeNotification('文本内容过大', contentSize, AppConstants.TEXT_SIZE_LIMIT);
            return;
          }
        }
      }

      // Skip empty content
      if (!content) {
        hilog.warn(DOMAIN, TAG, 'onClipboardUpdate: content is empty, skipping');
        return;
      }

      hilog.info(DOMAIN, TAG, 'onClipboardUpdate: processing content, preview=%{public}s', content.substring(0, 30));

      // 2b. Check blacklist: skip if source app is blacklisted
      if (this.blacklistDao) {
        const prop: pasteboard.PasteDataProperty = pasteData.getProperty();
        let sourceApp: string = '';
        if (prop.additions) {
          const appValue = prop.additions['sourceApp'];
          if (appValue) {
            sourceApp = String(appValue);
          }
        }
        if (sourceApp) {
          try {
            const isBlocked: boolean = await this.blacklistDao.isBlacklisted(sourceApp);
            if (isBlocked) {
              console.info(`${TAG} Skipped blacklisted source app: ${sourceApp}`);
              return;
            }
          } catch (err) {
            console.warn(`${TAG} Blacklist check failed, proceeding with capture: ${err}`);
          }
        }
      }

      // 3. Detect content type
      const contentType: ContentType = this.typeDetector.detect(content, mimeType);
      hilog.info(DOMAIN, TAG, 'onClipboardUpdate: detected type=%{public}s', contentType);

      // 4. Compute hash for deduplication check (text path)
      contentHash = await this.encryptionService.hash(content);
      hilog.info(DOMAIN, TAG, 'onClipboardUpdate: hash=%{public}s', contentHash.substring(0, 16));

      // 5. Check for duplicate
      const existing: ClipboardEntry | null = await this.dedupService.checkDuplicate(contentHash);
      if (existing) {
        // Duplicate found: promote to top and skip insert
        await this.dedupService.promoteToTop(existing.id);
        hilog.info(DOMAIN, TAG, 'onClipboardUpdate: duplicate promoted to top (id=%{public}d)', existing.id);
        AppContext.notifyDataChanged();
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
      hilog.info(DOMAIN, TAG, 'onClipboardUpdate: NEW entry saved (id=%{public}d, type=%{public}s)', newId, contentType);
      AppContext.notifyDataChanged();

    } catch (err) {
      hilog.error(DOMAIN, TAG, 'onClipboardUpdate: ERROR %{public}s', JSON.stringify(err));
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
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [{ bundleName: 'com.clipbridge.harmony', abilityName: 'EntryAbility' }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
      };
      const agent = await wantAgent.getWantAgent(wantAgentInfo);
      await backgroundTaskManager.startBackgroundRunning(context, backgroundTaskManager.BackgroundMode.DATA_TRANSFER, agent);
      this.continuousTaskActive = true;
      hilog.info(DOMAIN, TAG, 'Continuous background task started');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to start continuous task: %{public}s', JSON.stringify(err));
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
      await backgroundTaskManager.stopBackgroundRunning(context);
      this.continuousTaskActive = false;
      console.info(`${TAG} Continuous background task stopped`);
    } catch (err) {
      console.error(`${TAG} Failed to stop continuous task: ${err}`);
    }
  }

  /**
   * Sends a local notification when clipboard content exceeds size limits.
   */
  private async sendOversizeNotification(title: string, actualSize: number, limit: number): Promise<void> {
    try {
      const actualMB: string = (actualSize / (1024 * 1024)).toFixed(1);
      const limitMB: string = (limit / (1024 * 1024)).toFixed(1);
      const notificationRequest: notificationManager.NotificationRequest = {
        id: AppConstants.NOTIFICATION_ID + 1,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: `内容大小 ${actualMB}MB 超过限制 ${limitMB}MB，已跳过记录`
          }
        },
        notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION
      };
      await notificationManager.publish(notificationRequest);
      console.info(`${TAG} Oversize notification published`);
    } catch (err) {
      console.warn(`${TAG} Failed to publish oversize notification: ${err}`);
    }
  }
}
