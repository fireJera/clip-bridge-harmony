/**
 * Junction table model representing the many-to-many relationship
 * between ClipboardEntry and CustomCategory.
 *
 * Each row links one entry to one category. An entry can have
 * multiple categories and a category can be applied to multiple entries.
 */
export class EntryCategoryRelation {
  /** Foreign key referencing ClipboardEntry.id. */
  entryId: number = 0;

  /** Foreign key referencing CustomCategory.id. */
  categoryId: number = 0;

  /** ISO-8601 timestamp when the association was created. */
  createdAt: string = '';
}
