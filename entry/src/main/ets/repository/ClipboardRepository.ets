import { ClipboardEntry } from '../model/ClipboardEntry';

export interface IClipboardRepository {
  insert(entry: ClipboardEntry): Promise<number>;
  getById(id: number): Promise<ClipboardEntry | null>;
  getHistory(offset: number, limit: number): Promise<ClipboardEntry[]>;
  getByType(type: string, offset: number, limit: number): Promise<ClipboardEntry[]>;
  getFavorites(offset: number, limit: number): Promise<ClipboardEntry[]>;
  search(keyword: string, offset: number, limit: number): Promise<ClipboardEntry[]>;
  count(): Promise<number>;
  countFavorites(): Promise<number>;
  findByHash(contentHash: string): Promise<ClipboardEntry | null>;
  touchTimestamp(id: number): Promise<void>;
  updatePin(id: number, pinned: boolean): Promise<void>;
  updateFavorite(id: number, favorited: boolean): Promise<void>;
  deleteById(id: number): Promise<void>;
  deleteByIds(ids: number[]): Promise<void>;
  deleteAll(): Promise<void>;
  pruneOldest(count: number): Promise<number>;
}
