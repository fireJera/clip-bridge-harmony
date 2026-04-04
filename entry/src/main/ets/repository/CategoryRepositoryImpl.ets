import { ICategoryRepository } from './CategoryRepository';
import { CustomCategory } from '../model/CustomCategory';
import { ClipboardEntry } from '../model/ClipboardEntry';
import { CategoryDao } from '../data/database/CategoryDao';
import { AppConstants } from '../common/constants/AppConstants';

const TAG: string = '[CategoryRepositoryImpl]';

export class CategoryRepositoryImpl implements ICategoryRepository {
  private dao: CategoryDao;

  constructor(dao: CategoryDao) {
    this.dao = dao;
  }

  async create(name: string, color?: string): Promise<number> {
    try {
      // Enforce max categories limit
      const currentCount: number = await this.dao.count();
      if (currentCount >= AppConstants.MAX_CATEGORIES) {
        throw new Error(`Maximum number of categories (${AppConstants.MAX_CATEGORIES}) reached`);
      }
      return await this.dao.insert(name, color);
    } catch (error) {
      throw new Error(`Failed to create category "${name}": ${error}`);
    }
  }

  async getAll(): Promise<CustomCategory[]> {
    try {
      return await this.dao.getAll();
    } catch (error) {
      throw new Error(`Failed to get all categories: ${error}`);
    }
  }

  async getById(id: number): Promise<CustomCategory | null> {
    try {
      return await this.dao.getById(id);
    } catch (error) {
      throw new Error(`Failed to get category by id ${id}: ${error}`);
    }
  }

  async update(id: number, name: string, color?: string): Promise<void> {
    try {
      await this.dao.update(id, name, color);
    } catch (error) {
      throw new Error(`Failed to update category ${id}: ${error}`);
    }
  }

  async delete(id: number): Promise<void> {
    try {
      await this.dao.delete(id);
    } catch (error) {
      throw new Error(`Failed to delete category ${id}: ${error}`);
    }
  }

  async count(): Promise<number> {
    try {
      return await this.dao.count();
    } catch (error) {
      throw new Error(`Failed to count categories: ${error}`);
    }
  }

  async addTag(entryId: number, categoryId: number): Promise<void> {
    try {
      await this.dao.addRelation(entryId, categoryId);
    } catch (error) {
      throw new Error(`Failed to add tag (entry=${entryId}, category=${categoryId}): ${error}`);
    }
  }

  async removeTag(entryId: number, categoryId: number): Promise<void> {
    try {
      await this.dao.removeRelation(entryId, categoryId);
    } catch (error) {
      throw new Error(`Failed to remove tag (entry=${entryId}, category=${categoryId}): ${error}`);
    }
  }

  async getEntriesByCategory(categoryId: number, offset: number, limit: number): Promise<ClipboardEntry[]> {
    try {
      return await this.dao.getEntriesByCategory(categoryId, offset, limit);
    } catch (error) {
      throw new Error(`Failed to get entries for category ${categoryId}: ${error}`);
    }
  }

  async getTagsForEntry(entryId: number): Promise<CustomCategory[]> {
    try {
      return await this.dao.getCategoriesForEntry(entryId);
    } catch (error) {
      throw new Error(`Failed to get tags for entry ${entryId}: ${error}`);
    }
  }
}
