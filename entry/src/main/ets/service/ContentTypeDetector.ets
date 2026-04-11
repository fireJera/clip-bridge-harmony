/**
 * Content type constants used throughout the application.
 */
export type ContentType = 'text' | 'url' | 'email' | 'phone' | 'image' | 'address';

/**
 * Stateless, synchronous service that detects the semantic type of
 * clipboard content.
 *
 * Detection follows a priority cascade:
 *   email > phone > url > address > image > text
 *
 * The class has no mutable state and can be instantiated freely
 * or used as a singleton from a module-level constant.
 */
export class ContentTypeDetector {
  /**
   * Detects the content type of a clipboard payload.
   *
   * @param content - The text content from the clipboard (may be empty for images).
   * @param mimeType - The MIME type of the clipboard data (e.g. 'text/plain', 'image/png').
   * @returns The detected ContentType.
   */
  detect(content: string, mimeType: string): ContentType {
    if (mimeType.startsWith('image/') || mimeType === 'pixelMap') {
      // Even for images, check if meaningful text patterns are present
      const textType = this.detectText(content);
      if (textType !== 'text') {
        return textType;
      }
      return 'image';
    }
    return this.detectText(content);
  }

  /**
   * Detects content type from plain text using pattern matching.
   * Priority: email > phone > url > address > text.
   */
  private detectText(content: string): ContentType {
    const trimmed = content.trim();

    if (trimmed.length === 0) {
      return 'text';
    }

    // Priority 1: Email
    if (this.isEmail(trimmed)) {
      return 'email';
    }
    // Priority 2: Phone
    if (this.isPhone(trimmed)) {
      return 'phone';
    }
    // Priority 3: URL
    if (this.isUrl(trimmed)) {
      return 'url';
    }
    // Priority 4: Address (Chinese address heuristic)
    if (this.isAddress(trimmed)) {
      return 'address';
    }
    // Fallback: plain text
    return 'text';
  }

  /**
   * Checks whether the string is a single valid email address.
   */
  private isEmail(s: string): boolean {
    const emailRegex = /^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(s);
  }

  /**
   * Checks whether the string is a phone number.
   * Strips common separator characters and verifies the remaining
   * digits form a plausible phone number (7-15 digits, optional leading +).
   */
  private isPhone(s: string): boolean {
    // Strip common separator characters
    const digits = s.replace(/[-.\s()]/g, '');
    // Must be primarily digits, 7-15 digits, optional leading +
    if (!/^\+?\d{7,15}$/.test(digits)) {
      return false;
    }
    return true;
  }

  /**
   * Checks whether the string is a URL (http/https or www-prefixed).
   */
  private isUrl(s: string): boolean {
    const urlRegex = /^https?:\/\/[^\s]+$/;
    const wwwRegex = /^www\.[^\s]+\.[a-zA-Z]{2,}/;
    return urlRegex.test(s) || wwwRegex.test(s);
  }

  /**
   * Checks whether the string looks like a Chinese address.
   * Requires at least 2 Chinese address keywords (province, city, district,
   * road, street, etc.) and a minimum length of 6 characters.
   */
  private isAddress(s: string): boolean {
    const addressKeywordPattern = /省|市|区|县|路|街|道|号|楼|室|镇|乡|村/g;
    const matches = s.match(addressKeywordPattern);
    return matches !== null && matches.length >= 2 && s.length > 6;
  }
}
