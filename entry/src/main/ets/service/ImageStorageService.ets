import { fileIo as fs } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../common/constants/AppConstants';

const TAG: string = '[ImageStorage]';
const DOMAIN: number = 0x0000;

/**
 * Service for saving clipboard images to the app sandbox,
 * generating thumbnails, and cleaning up files on deletion.
 *
 * Images: {filesDir}/images/img_{id}_{ts}.jpg
 * Thumbnails: {filesDir}/thumbnails/thumb_{id}_{ts}.jpg
 */
export class ImageStorageService {
  private readonly imagesDir: string;
  private readonly thumbnailsDir: string;
  private dirsReady: boolean = false;

  constructor(filesDir: string) {
    this.imagesDir = `${filesDir}/images`;
    this.thumbnailsDir = `${filesDir}/thumbnails`;
  }

  private ensureDirectories(): void {
    if (this.dirsReady) return;
    try {
      if (!fs.accessSync(this.imagesDir)) {
        fs.mkdirSync(this.imagesDir);
      }
      if (!fs.accessSync(this.thumbnailsDir)) {
        fs.mkdirSync(this.thumbnailsDir);
      }
      this.dirsReady = true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'ensureDirectories failed: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * Saves a PixelMap as a JPEG file and returns the absolute path.
   */
  async saveImage(pixelMap: image.PixelMap, tempId: number): Promise<string> {
    this.ensureDirectories();
    const filePath = `${this.imagesDir}/img_${tempId}_${Date.now()}.jpg`;

    const packer = image.createImagePacker();
    const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 90 };
    const data: ArrayBuffer = await packer.packing(pixelMap, packOpts);
    packer.release();

    const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.writeSync(file.fd, data);
    fs.closeSync(file);

    hilog.info(DOMAIN, TAG, 'Saved image: %{public}s (%d bytes)', filePath, data.byteLength);
    return filePath;
  }

  /**
   * Generates a scaled-down thumbnail from a PixelMap and returns the absolute path.
   * Uses ImageSource + DecodingOptions for proper API 12 scaling.
   */
  async generateThumbnail(pixelMap: image.PixelMap, tempId: number): Promise<string> {
    this.ensureDirectories();
    const thumbPath = `${this.thumbnailsDir}/thumb_${tempId}_${Date.now()}.jpg`;

    // Get original dimensions
    const imageInfo = await pixelMap.getImageInfo();
    const origW = imageInfo.size.width;
    const origH = imageInfo.size.height;
    const maxSize = AppConstants.THUMBNAIL_SIZE;

    // Calculate target dimensions preserving aspect ratio
    let targetW: number;
    let targetH: number;
    if (origW >= origH) {
      targetW = maxSize;
      targetH = Math.round((origH / origW) * maxSize);
    } else {
      targetH = maxSize;
      targetW = Math.round((origW / origH) * maxSize);
    }
    if (targetH < 1) targetH = 1;
    if (targetW < 1) targetW = 1;

    // Pack original to buffer, then decode at target size
    const srcPacker = image.createImagePacker();
    const srcData: ArrayBuffer = await srcPacker.packing(pixelMap, { format: 'image/jpeg', quality: 80 });
    srcPacker.release();

    const imageSource = image.createImageSource(srcData);
    const thumbPixelMap = await imageSource.createPixelMap({
      desiredSize: { width: targetW, height: targetH },
      editable: false
    });
    imageSource.release();

    // Pack thumbnail and write to file
    const thumbPacker = image.createImagePacker();
    const thumbData: ArrayBuffer = await thumbPacker.packing(thumbPixelMap, { format: 'image/jpeg', quality: 75 });
    thumbPacker.release();
    thumbPixelMap.release();

    const file = fs.openSync(thumbPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.writeSync(file.fd, thumbData);
    fs.closeSync(file);

    hilog.info(DOMAIN, TAG, 'Saved thumbnail: %{public}s (%dx%d)', thumbPath, targetW, targetH);
    return thumbPath;
  }

  /**
   * Deletes image and thumbnail files for a single entry.
   */
  async deleteImageFiles(imagePath: string, thumbnailPath: string): Promise<void> {
    try {
      if (imagePath && fs.accessSync(imagePath)) {
        fs.unlinkSync(imagePath);
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Failed to delete image: %{public}s', JSON.stringify(e));
    }
    try {
      if (thumbnailPath && fs.accessSync(thumbnailPath)) {
        fs.unlinkSync(thumbnailPath);
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Failed to delete thumbnail: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * Deletes all image and thumbnail files (used on clear-all).
   */
  async deleteAllImageFiles(): Promise<void> {
    try {
      if (fs.accessSync(this.imagesDir)) {
        const files = fs.listFileSync(this.imagesDir);
        for (const f of files) {
          fs.unlinkSync(`${this.imagesDir}/${f}`);
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Failed to clean images dir: %{public}s', JSON.stringify(e));
    }
    try {
      if (fs.accessSync(this.thumbnailsDir)) {
        const files = fs.listFileSync(this.thumbnailsDir);
        for (const f of files) {
          fs.unlinkSync(`${this.thumbnailsDir}/${f}`);
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Failed to clean thumbnails dir: %{public}s', JSON.stringify(e));
    }
  }
}
