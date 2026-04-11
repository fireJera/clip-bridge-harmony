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
   * Uses contextual patterns to avoid false positives from words like
   * "本市", "公司", "渠道" etc. which contain address-like characters
   * but are not addresses.
   */
  private isAddress(s: string): boolean {
    // High-confidence patterns: province/city/district followed by more address parts
    const highConfidence = /(?:省|自治区|直辖市)[^，。；！？\n]{1,20}(?:市|区|县|路|街|道|号)/;
    if (highConfidence.test(s)) {
      return true;
    }
    // City-level address: e.g. "北京市朝阳区", "深圳市南山区科技路"
    const cityAddress = /(?:省|市)[^，。；！？\n]{1,15}(?:区|县)[^，。；！？\n]{1,15}(?:路|街|道|镇|乡)/;
    if (cityAddress.test(s)) {
      return true;
    }
    // Road/street with number: e.g. "科技路1号", "中山大道88号"
    const roadWithNumber = /(?:路|街|大道)[\d]+号/;
    if (roadWithNumber.test(s)) {
      return true;
    }
    // Building/room: e.g. "xx路xx号xx楼xx室"
    const buildingRoom = /(?:路|街|号)[^，。；！？\n]{0,10}楼[^，。；！？\n]{0,10}室/;
    if (buildingRoom.test(s)) {
      return true;
    }
    // Village: "xx省xx市xx村" or "xx镇xx村"
    const village = /(?:镇|乡|县)[^，。；！？\n]{1,15}村/;
    if (village.test(s)) {
      return true;
    }
    return false;
  }
}
