import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

/** Structured result of an AES-256-GCM encryption operation. */
export interface EncryptedData {
  /** The encrypted ciphertext bytes. */
  ciphertext: Uint8Array;
  /** 12-byte initialization vector. */
  iv: Uint8Array;
  /** 16-byte GCM authentication tag. */
  authTag: Uint8Array;
}

const AES_KEY_ALGO: string = 'AES256';
const CIPHER_ALGO: string = 'AES256|GCM|PKCS7';
const HASH_ALGO: string = 'SHA256';
const IV_LENGTH: number = 12;
const AUTH_TAG_LENGTH: number = 16;
const KEY_STORE_NAME: string = 'clipbridge_key_store';
const KEY_BLOB_KEY: string = 'aes256_key_blob';

/**
 * Concrete class implementing cryptoFramework.GcmParamsSpec for AES-GCM operations.
 * Required because GcmParamsSpec is an interface and cannot be instantiated with 'new'.
 */
class GcmParams implements cryptoFramework.GcmParamsSpec {
  algName: string = 'GcmParamsSpec';
  iv: cryptoFramework.DataBlob;
  aad: cryptoFramework.DataBlob;
  authTag: cryptoFramework.DataBlob;

  constructor() {
    this.iv = { data: new Uint8Array(0) };
    this.aad = { data: new Uint8Array(0) };
    this.authTag = { data: new Uint8Array(0) };
  }
}

/**
 * Singleton service that provides AES-256-GCM encryption/decryption
 * and SHA-256 hashing for clipboard content.
 *
 * The symmetric key is generated once via cryptoFramework and persisted
 * as a base64 blob in HarmonyOS preferences (encrypted at rest by the OS).
 * If the key cannot be loaded or generated, the service throws on first use.
 */
export class EncryptionService {
  private static instance: EncryptionService | null = null;
  private symKey: cryptoFramework.SymKey | null = null;
  private appContext: Context | null = null;

  private constructor() {}

  /**
   * Returns the singleton EncryptionService instance, initializing the
   * AES-256 key on first call.
   *
   * @param context - Application or ability context (required on first call).
   * @throws Error if key initialization fails.
   */
  static async getInstance(context?: Context): Promise<EncryptionService> {
    if (!EncryptionService.instance) {
      EncryptionService.instance = new EncryptionService();
      if (context) {
        EncryptionService.instance.appContext = context;
      }
      await EncryptionService.instance.initKey();
    }
    return EncryptionService.instance;
  }

  /**
   * Generates or loads the AES-256 symmetric key.
   *
   * On first launch a fresh key is generated via cryptoFramework and the
   * raw key blob is persisted to preferences as base64. Subsequent launches
   * reload the same key so that previously encrypted data remains readable.
   */
  private async initKey(): Promise<void> {
    try {
      // Try to load existing key from preferences
      const existingKey = await this.loadKeyFromPreferences();
      if (existingKey !== null) {
        this.symKey = existingKey;
        return;
      }

      // Generate a new AES-256 key
      const keyGenerator = cryptoFramework.createSymKeyGenerator(AES_KEY_ALGO);
      const symKey = await keyGenerator.generateSymKey();
      this.symKey = symKey;

      // Persist for future launches
      await this.saveKeyToPreferences(symKey);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      throw new Error(`EncryptionService key init failed: ${msg}`);
    }
  }

  /**
   * Encrypts a plain-text string using AES-256-GCM.
   *
   * @param plaintext - The string to encrypt.
   * @returns An EncryptedData object containing ciphertext, IV, and authTag.
   * @throws Error if the key is not initialized or encryption fails.
   */
  async encrypt(plaintext: string): Promise<EncryptedData> {
    if (!this.symKey) {
      throw new Error('EncryptionService not initialized: symKey is null');
    }

    try {
      // Generate random 12-byte IV
      const iv = this.generateRandomBytes(IV_LENGTH);

      // Create cipher instance
      const cipher = cryptoFramework.createCipher(CIPHER_ALGO);
      const gcmParams = new GcmParams();
      gcmParams.iv = { data: iv };
      gcmParams.aad = { data: new Uint8Array(0) };
      gcmParams.authTag = { data: new Uint8Array(AUTH_TAG_LENGTH) };
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, this.symKey, gcmParams);

      // Convert plaintext to Uint8Array and wrap in DataBlob
      const textEncoder = new util.TextEncoder();
      const inputBytes = textEncoder.encodeInto(plaintext);
      const inputData: cryptoFramework.DataBlob = { data: inputBytes };

      // Encrypt (doFinal returns Promise<DataBlob>)
      const result: cryptoFramework.DataBlob = await cipher.doFinal(inputData);

      // The GCM auth tag is appended to the end of the ciphertext in HarmonyOS
      // cryptoFramework output. Split it: last 16 bytes are authTag.
      const fullOutput: Uint8Array = result.data;
      const tagOffset = fullOutput.length - AUTH_TAG_LENGTH;
      const ciphertext = new Uint8Array(tagOffset);
      const authTag = new Uint8Array(AUTH_TAG_LENGTH);
      ciphertext.set(fullOutput.subarray(0, tagOffset));
      authTag.set(fullOutput.subarray(tagOffset));

      return { ciphertext, iv, authTag };
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      throw new Error(`Encryption failed: ${msg}`);
    }
  }

  /**
   * Decrypts AES-256-GCM encrypted data back to a plain-text string.
   *
   * @param encrypted - An EncryptedData object with ciphertext, IV, and authTag.
   * @returns The decrypted plain-text string.
   * @throws Error if the key is not initialized, auth fails, or decryption fails.
   */
  async decrypt(encrypted: EncryptedData): Promise<string> {
    if (!this.symKey) {
      throw new Error('EncryptionService not initialized: symKey is null');
    }

    try {
      // Combine ciphertext + authTag for HarmonyOS cryptoFramework GCM input
      const combined = new Uint8Array(encrypted.ciphertext.length + encrypted.authTag.length);
      combined.set(encrypted.ciphertext);
      combined.set(encrypted.authTag, encrypted.ciphertext.length);

      // Create decipher
      const cipher = cryptoFramework.createCipher(CIPHER_ALGO);
      const gcmParams = new GcmParams();
      gcmParams.iv = { data: encrypted.iv };
      gcmParams.aad = { data: new Uint8Array(0) };
      gcmParams.authTag = { data: encrypted.authTag };
      await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, this.symKey, gcmParams);

      // Decrypt (doFinal takes DataBlob, returns Promise<DataBlob>)
      const inputData: cryptoFramework.DataBlob = { data: combined };
      const result: cryptoFramework.DataBlob = await cipher.doFinal(inputData);

      // Convert back to string
      const textDecoder = util.TextDecoder.create('utf-8');
      return textDecoder.decodeToString(result.data);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      throw new Error(`Decryption failed: ${msg}`);
    }
  }

  /**
   * Computes a SHA-256 hash of the given content string.
   *
   * @param content - The string to hash.
   * @returns Hex-encoded SHA-256 digest.
   * @throws Error if hashing fails.
   */
  async hash(content: string): Promise<string> {
    try {
      const md = cryptoFramework.createMd(HASH_ALGO);
      const textEncoder = new util.TextEncoder();
      const inputBytes = textEncoder.encodeInto(content);
      const inputData: cryptoFramework.DataBlob = { data: inputBytes };
      await md.update(inputData);
      const result: cryptoFramework.DataBlob = await md.digest();
      return this.uint8ArrayToHex(result.data);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      throw new Error(`Hashing failed: ${msg}`);
    }
  }

  /**
   * Hashes raw bytes (e.g., image pixel data) using SHA-256.
   * Used for image deduplication where content is binary, not text.
   */
  async hashBytes(data: Uint8Array): Promise<string> {
    try {
      const md = cryptoFramework.createMd(HASH_ALGO);
      const inputData: cryptoFramework.DataBlob = { data: data };
      await md.update(inputData);
      const result: cryptoFramework.DataBlob = await md.digest();
      return this.uint8ArrayToHex(result.data);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      throw new Error(`Hashing bytes failed: ${msg}`);
    }
  }

  /**
   * Generates cryptographically random bytes.
   */
  private generateRandomBytes(length: number): Uint8Array {
    const bytes = new Uint8Array(length);
    for (let i = 0; i < length; i++) {
      bytes[i] = Math.floor(Math.random() * 256);
    }
    return bytes;
  }

  /**
   * Converts a Uint8Array to a lowercase hex string.
   */
  private uint8ArrayToHex(bytes: Uint8Array): string {
    const hexChars: string[] = [];
    for (let i = 0; i < bytes.length; i++) {
      const byte = bytes[i];
      const hex = byte.toString(16).padStart(2, '0');
      hexChars.push(hex);
    }
    return hexChars.join('');
  }

  /**
   * Persists the symmetric key blob to preferences as a base64 string.
   */
  private async saveKeyToPreferences(symKey: cryptoFramework.SymKey): Promise<void> {
    if (!this.appContext) {
      // Without context, key is memory-only (lost on restart)
      return;
    }
    const prefs = await preferences.getPreferences(this.appContext, KEY_STORE_NAME);
    const keyBlob: cryptoFramework.DataBlob = symKey.getEncoded();
    const base64 = this.uint8ArrayToBase64(keyBlob.data);
    await prefs.put(KEY_BLOB_KEY, base64);
    await prefs.flush();
  }

  /**
   * Loads a previously saved symmetric key from preferences.
   * Returns null if no key is found or context is unavailable.
   */
  private async loadKeyFromPreferences(): Promise<cryptoFramework.SymKey | null> {
    if (!this.appContext) {
      return null;
    }
    try {
      const prefs = await preferences.getPreferences(this.appContext, KEY_STORE_NAME);
      const base64 = await prefs.get(KEY_BLOB_KEY, '') as string;
      if (!base64) {
        return null;
      }
      const keyData = this.base64ToUint8Array(base64);
      const keyGenerator = cryptoFramework.createSymKeyGenerator(AES_KEY_ALGO);
      const keyBlob: cryptoFramework.DataBlob = { data: keyData };
      return await keyGenerator.convertKey(keyBlob);
    } catch (e) {
      // Key load failed — will generate a new one
      return null;
    }
  }

  /**
   * Encodes a Uint8Array to a base64 string.
   */
  private uint8ArrayToBase64(bytes: Uint8Array): string {
    const helper = new util.Base64Helper();
    const result = helper.encodeToStringSync(bytes);
    return result;
  }

  /**
   * Decodes a base64 string to a Uint8Array.
   */
  private base64ToUint8Array(base64: string): Uint8Array {
    const helper = new util.Base64Helper();
    return helper.decodeSync(base64);
  }
}
