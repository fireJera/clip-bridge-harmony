import { CustomCategory } from '../model/CustomCategory';
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Auto-detected content type filter definition.
 */
interface TypeFilterItem {
  type: string;
  label: string;
  color: string;
}

/**
 * Horizontal scrollable filter chip bar for filtering clipboard entries
 * by auto-detected content type and custom user-defined categories.
 *
 * Supports multi-select: multiple filters can be active simultaneously.
 * The parent receives callbacks via onFilterChange with the active types
 * and category IDs.
 */
@Component
export struct CategoryFilter {
  @Prop categories: CustomCategory[] = [];
  @State activeTypes: Set<string> = new Set();
  @State activeCategoryIds: Set<number> = new Set();
  onFilterChange?: (types: string[], categoryIds: number[]) => void;

  private readonly typeFilters: TypeFilterItem[] = [
    { type: 'text', label: '文本', color: ThemeTokens.TYPE_TEXT_COLOR },
    { type: 'url', label: '链接', color: ThemeTokens.TYPE_URL_COLOR },
    { type: 'email', label: '邮箱', color: ThemeTokens.TYPE_EMAIL_COLOR },
    { type: 'phone', label: '电话', color: ThemeTokens.TYPE_PHONE_COLOR },
    { type: 'image', label: '图片', color: ThemeTokens.TYPE_IMAGE_COLOR },
    { type: 'address', label: '地址', color: ThemeTokens.TYPE_ADDRESS_COLOR }
  ];

  build() {
    Scroll() {
      Row({ space: ThemeTokens.SPACING_SM }) {
        // Section 1: Auto-detected content type chips
        ForEach(this.typeFilters, (item: TypeFilterItem) => {
          this.FilterChip({
            label: item.label,
            color: item.color,
            isActive: this.activeTypes.has(item.type),
            onToggle: () => this.toggleType(item.type)
          })
        }, (item: TypeFilterItem) => `type_${item.type}`)

        // Separator between sections if custom categories exist
        if (this.categories.length > 0) {
          Divider()
            .vertical(true)
            .height(20)
            .color(ThemeTokens.DIVIDER)
            .margin({ left: ThemeTokens.SPACING_XS, right: ThemeTokens.SPACING_XS })
        }

        // Section 2: Custom category chips
        ForEach(this.categories, (cat: CustomCategory) => {
          this.FilterChip({
            label: cat.name,
            color: cat.color || ThemeTokens.PRIMARY,
            isActive: this.activeCategoryIds.has(cat.id),
            onToggle: () => this.toggleCategory(cat.id)
          })
        }, (cat: CustomCategory) => `cat_${cat.id}`)
      }
      .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(44)
  }

  @Builder
  FilterChip(params: {
    label: string;
    color: string;
    isActive: boolean;
    onToggle: () => void
  }) {
    Row() {
      // Color dot
      Text('')
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(params.isActive ? Color.White : params.color)
        .margin({ right: ThemeTokens.SPACING_XS })

      // Label
      Text(params.label)
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(params.isActive ? Color.White : ThemeTokens.TEXT_PRIMARY)
        .fontWeight(params.isActive ? ThemeTokens.FONT_WEIGHT_MEDIUM : ThemeTokens.FONT_WEIGHT_REGULAR)
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
    .backgroundColor(params.isActive ? params.color : ThemeTokens.SURFACE)
    .border({
      width: params.isActive ? 0 : 1,
      color: params.isActive ? Color.Transparent : ThemeTokens.DIVIDER
    })
    .onClick(() => {
      params.onToggle();
    })
  }

  private toggleType(type: string): void {
    const newSet = new Set(this.activeTypes);
    if (newSet.has(type)) {
      newSet.delete(type);
    } else {
      newSet.add(type);
    }
    this.activeTypes = newSet;
    this.emitChange();
  }

  private toggleCategory(id: number): void {
    const newSet = new Set(this.activeCategoryIds);
    if (newSet.has(id)) {
      newSet.delete(id);
    } else {
      newSet.add(id);
    }
    this.activeCategoryIds = newSet;
    this.emitChange();
  }

  private emitChange(): void {
    if (this.onFilterChange) {
      this.onFilterChange(
        Array.from(this.activeTypes),
        Array.from(this.activeCategoryIds)
      );
    }
  }
}
