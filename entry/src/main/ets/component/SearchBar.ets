import { ThemeTokens } from '../common/theme/ThemeTokens';
import { AppConstants } from '../common/constants/AppConstants';

/**
 * Search bar component with debounce support.
 * Emits onSearch callback after 300ms of inactivity and onClear when
 * the input is cleared.
 */
@Component
export struct SearchBar {
  @State searchText: string = '';
  private debounceTimer: number = -1;
  onSearch?: (keyword: string) => void;
  onClear?: () => void;

  build() {
    Row() {
      // Search icon
      Text('\u{1F50D}')
        .fontSize(16)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .margin({ right: ThemeTokens.SPACING_SM })

      // Text input
      TextInput({ placeholder: '搜索剪贴板...', text: this.searchText })
        .layoutWeight(1)
        .height(36)
        .fontSize(ThemeTokens.FONT_SIZE_BODY)
        .fontColor(ThemeTokens.TEXT_PRIMARY)
        .placeholderColor(ThemeTokens.TEXT_TERTIARY)
        .backgroundColor(Color.Transparent)
        .type(InputType.Normal)
        .onChange((value: string) => {
          this.searchText = value;
          this.debouncedSearch(value);
        })
        .onSubmit((enterKey: EnterKeyType) => {
          this.clearDebounce();
          if (this.onSearch) {
            this.onSearch(this.searchText);
          }
        })

      // Clear button (visible only when there is text)
      if (this.searchText.length > 0) {
        Text('\u2715')
          .fontSize(14)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .borderRadius(14)
          .backgroundColor(ThemeTokens.DIVIDER)
          .onClick(() => {
            this.searchText = '';
            this.clearDebounce();
            if (this.onClear) {
              this.onClear();
            }
          })
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })
    .backgroundColor(ThemeTokens.SURFACE)
    .borderRadius(ThemeTokens.BORDER_RADIUS_MD)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * Debounces the search callback by AppConstants.SEARCH_DEBOUNCE_MS (300ms).
   */
  private debouncedSearch(keyword: string): void {
    this.clearDebounce();
    this.debounceTimer = setTimeout(() => {
      if (this.onSearch) {
        this.onSearch(keyword);
      }
    }, AppConstants.SEARCH_DEBOUNCE_MS);
  }

  /**
   * Clears any pending debounce timer.
   */
  private clearDebounce(): void {
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = -1;
    }
  }
}
