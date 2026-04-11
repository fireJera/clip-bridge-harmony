export class AppConstants {
  static readonly DEFAULT_HISTORY_LIMIT: number = 500;
  static readonly MAX_HISTORY_LIMIT: number = 5000;
  static readonly MIN_HISTORY_LIMIT: number = 50;
  static readonly MAX_CATEGORIES: number = 50;
  static readonly TEXT_SIZE_LIMIT: number = 1048576; // 1MB
  static readonly IMAGE_SIZE_LIMIT: number = 10485760; // 10MB
  static readonly THUMBNAIL_SIZE: number = 200;
  static readonly CONTENT_PREVIEW_LENGTH: number = 1048576; // 1MB, matches TEXT_SIZE_LIMIT
  static readonly SEARCH_DEBOUNCE_MS: number = 300;
  static readonly PAGE_SIZE: number = 20;
  static readonly DB_NAME: string = 'clipbridge.db';
  static readonly DB_ENCRYPTED: boolean = true;

  // Content types
  static readonly CONTENT_TYPE_TEXT: string = 'text';
  static readonly CONTENT_TYPE_URL: string = 'url';
  static readonly CONTENT_TYPE_EMAIL: string = 'email';
  static readonly CONTENT_TYPE_PHONE: string = 'phone';
  static readonly CONTENT_TYPE_IMAGE: string = 'image';
  static readonly CONTENT_TYPE_ADDRESS: string = 'address';

  // Notification channel
  static readonly NOTIFICATION_CHANNEL_ID: string = 'clipboard_monitor';
  static readonly NOTIFICATION_ID: number = 1001;
}
