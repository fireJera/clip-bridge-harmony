/**
 * Application-wide context holder.
 * Initialized in EntryAbility.onCreate() so that downstream services
 * and utilities can access the AbilityContext without coupling to the UI layer.
 */
export class AppContext {
  private static context: Context | null = null;

  static setContext(context: Context): void {
    AppContext.context = context;
  }

  static getContext(): Context {
    if (!AppContext.context) {
      throw new Error('AppContext not initialized. Call AppContext.setContext() in EntryAbility.onCreate() first.');
    }
    return AppContext.context;
  }
}
