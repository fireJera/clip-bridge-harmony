import { IClipboardRepository } from './ClipboardRepository';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { ClipboardDao, ContentUpdateData } from '../data/database/ClipboardDao';
import { EncryptionService } from '../service/EncryptionService';
import { UserSettings } from '../data/preferences/UserSettings';
import { util } from '@kit.ArkTS';
import { AppConstants } from '../common/constants/AppConstants';

const TAG: string = '[ClipboardRepositoryImpl]';

export class ClipboardRepositoryImpl implements IClipboardRepository {
  private dao: ClipboardDao;
  private encryptionService: EncryptionService;
  private userSettings: UserSettings;

  constructor(dao: ClipboardDao, encryptionService: EncryptionService, userSettings: UserSettings) {
    this.dao = dao;
    this.encryptionService = encryptionService;
    this.userSettings = userSettings;
  }

  async insert(entry: ClipboardEntry): Promise<number> {
    try {
      // 1. Compute content hash for deduplication
      const rawContent: string = entry.rawContent;
      const contentHash: string = await this.encryptionService.hash(rawContent);

      // 2. Check for duplicate via hash
      const existing: ClipboardEntry | null = await this.dao.findByHash(contentHash);
      if (existing !== null) {
        // 3. Duplicate found: touch timestamp and return existing id
        await this.dao.touchTimestamp(existing.id);
        return existing.id;
      }

      // 4. New entry: encrypt content before storing
      const encryptedData = await this.encryptionService.encrypt(rawContent);
      entry.contentEncrypted = encryptedData.ciphertext;
      entry.iv = encryptedData.iv;
      entry.authTag = encryptedData.authTag;
      entry.contentHash = contentHash;

      // 5. Insert via DAO
      const id: number = await this.dao.insert(entry);

      // 6. Enforce history limit: prune oldest if over limit
      const limit: number = await this.userSettings.getHistoryLimit();
      const totalCount: number = await this.dao.count();
      if (totalCount > limit) {
        const excess: number = totalCount - limit;
        await this.dao.pruneOldest(excess);
      }

      return id;
    } catch (error) {
      throw new Error(`Failed to insert clipboard entry: ${error}`);
    }
  }

  async getById(id: number): Promise<ClipboardEntry | null> {
    try {
      return await this.dao.getById(id);
    } catch (error) {
      throw new Error(`Failed to get clipboard entry by id ${id}: ${error}`);
    }
  }

  async getHistory(offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      return await this.dao.getHistory(offset, limit);
    } catch (error) {
      throw new Error(`Failed to get clipboard history: ${error}`);
    }
  }

  async getByType(type: string, offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      return await this.dao.getByType(type, offset, limit);
    } catch (error) {
      throw new Error(`Failed to get clipboard entries by type "${type}": ${error}`);
    }
  }

  async getFavorites(offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      return await this.dao.getFavorites(offset, limit);
    } catch (error) {
      throw new Error(`Failed to get favorite clipboard entries: ${error}`);
    }
  }

  async search(keyword: string, offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      return await this.dao.search(keyword, offset, limit);
    } catch (error) {
      throw new Error(`Failed to search clipboard entries with keyword "${keyword}": ${error}`);
    }
  }

  async count(): Promise<number> {
    try {
      return await this.dao.count();
    } catch (error) {
      throw new Error(`Failed to count clipboard entries: ${error}`);
    }
  }

  async countFavorites(): Promise<number> {
    try {
      return await this.dao.countFavorites();
    } catch (error) {
      throw new Error(`Failed to count favorite clipboard entries: ${error}`);
    }
  }

  async findByHash(contentHash: string): Promise<ClipboardEntry | null> {
    try {
      return await this.dao.findByHash(contentHash);
    } catch (error) {
      throw new Error(`Failed to find clipboard entry by hash: ${error}`);
    }
  }

  async touchTimestamp(id: number): Promise<void> {
    try {
      await this.dao.touchTimestamp(id);
    } catch (error) {
      throw new Error(`Failed to touch timestamp for entry ${id}: ${error}`);
    }
  }

  async updatePin(id: number, pinned: boolean): Promise<void> {
    try {
      await this.dao.updatePin(id, pinned);
    } catch (error) {
      throw new Error(`Failed to update pin status for entry ${id}: ${error}`);
    }
  }

  async updateFavorite(id: number, favorited: boolean): Promise<void> {
    try {
      await this.dao.updateFavorite(id, favorited);
    } catch (error) {
      throw new Error(`Failed to update favorite status for entry ${id}: ${error}`);
    }
  }

  async updateContent(id: number, newContent: string): Promise<void> {
    try {
      // 1. Hash new content for deduplication
      const contentHash: string = await this.encryptionService.hash(newContent);

      // 2. Encrypt new content
      const encryptedData = await this.encryptionService.encrypt(newContent);

      // 3. Build update data
      const data: ContentUpdateData = new ContentUpdateData();
      data.contentHash = contentHash;
      data.contentEncrypted = encryptedData.ciphertext;
      data.contentPreview = newContent.substring(0, AppConstants.CONTENT_PREVIEW_LENGTH);
      data.contentSize = new util.TextEncoder().encode(newContent).byteLength;
      data.iv = encryptedData.iv;
      data.authTag = encryptedData.authTag;
      data.updatedAt = new Date().toISOString();

      // 4. Persist via DAO
      await this.dao.updateContent(id, data);
    } catch (error) {
      throw new Error(`Failed to update content for entry ${id}: ${error}`);
    }
  }

  async deleteById(id: number): Promise<void> {
    try {
      await this.dao.deleteById(id);
    } catch (error) {
      throw new Error(`Failed to delete clipboard entry ${id}: ${error}`);
    }
  }

  async deleteByIds(ids: number[]): Promise<void> {
    try {
      await this.dao.deleteByIds(ids);
    } catch (error) {
      throw new Error(`Failed to delete clipboard entries: ${error}`);
    }
  }

  async deleteAll(): Promise<void> {
    try {
      await this.dao.deleteAll();
    } catch (error) {
      throw new Error(`Failed to delete all clipboard entries: ${error}`);
    }
  }

  async pruneOldest(count: number): Promise<number> {
    try {
      return await this.dao.pruneOldest(count);
    } catch (error) {
      throw new Error(`Failed to prune oldest ${count} entries: ${error}`);
    }
  }
}
