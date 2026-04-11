import { CustomCategory } from '../model/CustomCategory';
import { ClipboardEntry } from '../model/ClipboardEntry';

export interface ICategoryRepository {
  create(name: string, color?: string): Promise<number>;
  getAll(): Promise<CustomCategory[]>;
  getById(id: number): Promise<CustomCategory | null>;
  update(id: number, name: string, color?: string): Promise<void>;
  delete(id: number): Promise<void>;
  count(): Promise<number>;
  addTag(entryId: number, categoryId: number): Promise<void>;
  removeTag(entryId: number, categoryId: number): Promise<void>;
  getEntriesByCategory(categoryId: number, offset: number, limit: number): Promise<ClipboardEntry[]>;
  getTagsForEntry(entryId: number): Promise<CustomCategory[]>;
  getEntriesInAnyFolder(offset: number, limit: number): Promise<ClipboardEntry[]>;
  countEntriesInAnyFolder(): Promise<number>;
  deleteAllRelations(): Promise<void>;
}
