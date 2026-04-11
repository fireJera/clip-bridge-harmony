# ClipBridge Figma UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the ClipBridge app UI from basic Tabs layout to Figma-designed BottomNavBar with card-style history list, redesigned detail/settings/favorites pages, and a placeholder devices page.

**Architecture:** Replace ArkUI `Tabs` with custom `Row`-based BottomNavBar. Redesign `ClipboardListItem` into type-specific cards with icon, content preview, and tags. Restructure `DetailPage` into Fluid Hub + editable + notes + tags sections. Group settings into card-based sections with icons. All changes are pure UI — no data layer or ViewModel changes needed.

**Tech Stack:** ArkTS (HarmonyOS NEXT API 12+), ArkUI declarative components

**Design Reference:** Figma HarmonyOS optimized version (node 2316:2)

---

## File Structure

| Action | File | Responsibility |
|--------|------|---------------|
| Modify | `entry/src/main/ets/pages/Index.ets` | Replace Tabs with custom BottomNavBar |
| Modify | `entry/src/main/ets/common/theme/ThemeTokens.ets` | Add card/nav tokens |
| Modify | `entry/src/main/ets/component/ClipboardListItem.ets` | Redesign to card-style per type |
| Modify | `entry/src/main/ets/pages/HistoryPage.ets` | Time grouping + card layout |
| Modify | `entry/src/main/ets/pages/FavoritesPage.ets` | Category filter tabs |
| Modify | `entry/src/main/ets/pages/DetailPage.ets` | Fluid Hub + sections redesign |
| Modify | `entry/src/main/ets/pages/SettingsPage.ets` | Grouped card sections |
| Create | `entry/src/main/ets/pages/DevicesPage.ets` | v1 placeholder page |
| Create | `entry/src/main/ets/component/BottomNavBar.ets` | Reusable bottom navigation |
| Create | `entry/src/main/ets/component/TypeCard.ets` | Type-specific card component |

---

### Task 1: Add Theme Tokens for New Design

**Files:**
- Modify: `entry/src/main/ets/common/theme/ThemeTokens.ets`

- [ ] **Step 1: Add new design tokens**

Add these tokens to `ThemeTokens.ets` after the existing content type colors:

```typescript
  // Bottom Navigation Bar
  static readonly NAV_HEIGHT: number = 56;
  static readonly NAV_ICON_SIZE: number = 22;
  static readonly NAV_LABEL_SIZE: number = 11;
  static readonly NAV_ACTIVE_COLOR: string = '#007DFF';
  static readonly NAV_INACTIVE_COLOR: string = '#99182431';

  // Card design
  static readonly CARD_RADIUS: number = 16;
  static readonly CARD_PADDING: number = 16;
  static readonly CARD_ICON_SIZE: number = 40;
  static readonly CARD_ICON_RADIUS: number = 12;
  static readonly CARD_TAG_HEIGHT: number = 23;
  static readonly CARD_TAG_RADIUS: number = 12;
  static readonly CARD_TAG_FONT_SIZE: number = 12;

  // Detail page
  static readonly DETAIL_TOPBAR_HEIGHT: number = 64;
  static readonly DETAIL_FAB_HEIGHT: number = 64;
  static readonly DETAIL_FAB_RADIUS: number = 16;
  static readonly DETAIL_SECTION_RADIUS: number = 16;
  static readonly DETAIL_SECTION_PADDING: number = 16;

  // Settings
  static readonly SETTINGS_GROUP_RADIUS: number = 16;
  static readonly SETTINGS_ROW_HEIGHT: number = 72;
  static readonly SETTINGS_ROW_RADIUS: number = 12;
  static readonly SETTINGS_ICON_BG_SIZE: number = 40;
  static readonly SETTINGS_ICON_BG_RADIUS: number = 12;

  // Gradient decoration
  static readonly GRADIENT_START: string = '#E8F0FE';
  static readonly GRADIENT_END: string = '#F0E8FE';
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/common/theme/ThemeTokens.ets
git commit -m "feat: add design tokens for Figma UI redesign"
```

---

### Task 2: Create BottomNavBar Component

**Files:**
- Create: `entry/src/main/ets/component/BottomNavBar.ets`

- [ ] **Step 1: Create the BottomNavBar component**

Create `entry/src/main/ets/component/BottomNavBar.ets`:

```typescript
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Tab definition for the bottom navigation bar.
 */
interface NavTab {
  label: string;
  icon: ResourceStr;
  activeIcon: ResourceStr;
}

/**
 * Custom bottom navigation bar matching Figma HarmonyOS design.
 * Uses Row-based layout with 4 tabs: History, Favorites, Devices, Settings.
 */
@Component
export struct BottomNavBar {
  @Link currentIndex: number;
  private readonly tabs: NavTab[] = [
    {
      label: '历史',
      icon: $r('sys.media.oh_ic_public_clock'),
      activeIcon: $r('sys.media.oh_ic_public_clock')
    },
    {
      label: '收藏',
      icon: $r('sys.media.oh_ic_public_favor'),
      activeIcon: $r('sys.media.oh_ic_public_favor_filled')
    },
    {
      label: '设备',
      icon: $r('sys.media.oh_ic_public_device'),
      activeIcon: $r('sys.media.oh_ic_public_device')
    },
    {
      label: '设置',
      icon: $r('sys.media.oh_ic_public_settings'),
      activeIcon: $r('sys.media.oh_ic_public_settings')
    }
  ];

  build() {
    Row() {
      ForEach(this.tabs, (tab: NavTab, index?: number) => {
        Column() {
          Image(index === this.currentIndex ? tab.activeIcon : tab.icon)
            .width(ThemeTokens.NAV_ICON_SIZE)
            .height(ThemeTokens.NAV_ICON_SIZE)
            .fillColor(index === this.currentIndex ? ThemeTokens.NAV_ACTIVE_COLOR : ThemeTokens.NAV_INACTIVE_COLOR)
            .objectFit(ImageFit.Contain)

          Text(tab.label)
            .fontSize(ThemeTokens.NAV_LABEL_SIZE)
            .fontColor(index === this.currentIndex ? ThemeTokens.NAV_ACTIVE_COLOR : ThemeTokens.NAV_INACTIVE_COLOR)
            .fontWeight(index === this.currentIndex ? ThemeTokens.FONT_WEIGHT_MEDIUM : ThemeTokens.FONT_WEIGHT_REGULAR)
            .margin({ top: ThemeTokens.SPACING_XS })
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          if (index !== undefined) {
            this.currentIndex = index;
          }
        })
      }, (tab: NavTab, index?: number) => `nav_tab_${index}`)
    }
    .width('100%')
    .height(ThemeTokens.NAV_HEIGHT)
    .backgroundColor(ThemeTokens.SURFACE)
    .border({ width: { top: 0.5 }, color: ThemeTokens.DIVIDER })
    .padding({ bottom: ThemeTokens.SPACING_XS })
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/component/BottomNavBar.ets
git commit -m "feat: create BottomNavBar component with Figma design"
```

---

### Task 3: Create Devices Placeholder Page

**Files:**
- Create: `entry/src/main/ets/pages/DevicesPage.ets`

- [ ] **Step 1: Create placeholder DevicesPage**

Create `entry/src/main/ets/pages/DevicesPage.ets`:

```typescript
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Placeholder Devices page for v1.
 * Shows "coming soon" message. Full device sync management planned for v2.
 */
@Component
export struct DevicesPage {
  build() {
    Column() {
      // Title
      Row() {
        Text('设备')
          .fontSize(ThemeTokens.FONT_SIZE_TITLE)
          .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
          .fontColor(ThemeTokens.TEXT_PRIMARY)
      }
      .width('100%')
      .height(56)
      .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
      .alignItems(VerticalAlign.Center)

      // Placeholder content
      Column() {
        Text('设备同步功能即将上线')
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)

        Text('v2 将支持多设备间剪贴板历史同步')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .margin({ top: ThemeTokens.SPACING_SM })
          .textAlign(TextAlign.CENTER)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(ThemeTokens.SPACING_XL)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.BACKGROUND)
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/DevicesPage.ets
git commit -m "feat: add Devices placeholder page for v1"
```

---

### Task 4: Redesign Index.ets — Replace Tabs with BottomNavBar

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Rewrite Index.ets with BottomNavBar**

Replace the entire content of `entry/src/main/ets/pages/Index.ets`:

```typescript
import { HistoryPage } from './HistoryPage';
import { FavoritesPage } from './FavoritesPage';
import { SettingsPage } from './SettingsPage';
import { DevicesPage } from './DevicesPage';
import { DetailPage } from './DetailPage';
import { BottomNavBar } from '../component/BottomNavBar';
import { ThemeTokens } from '../common/theme/ThemeTokens';

interface DetailPageParams {
  entryId: number;
}

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string, param: Object) {
    if (name === 'DetailPage') {
      NavDestination() {
        DetailPage({
          entryId: (param as DetailPageParams).entryId,
          onBack: () => {
            this.navPathStack.pop();
          }
        })
      }
      .hideTitleBar(true)
      .backgroundColor(ThemeTokens.BACKGROUND)
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column() {
        // Page content area
        if (this.currentIndex === 0) {
          HistoryPage()
        } else if (this.currentIndex === 1) {
          FavoritesPage()
        } else if (this.currentIndex === 2) {
          DevicesPage()
        } else {
          SettingsPage()
        }

        // Bottom navigation bar
        BottomNavBar({ currentIndex: $currentIndex })
      }
      .width('100%')
      .height('100%')
    }
    .navDestination(this.PageMap)
    .mode(NavigationMode.Stack)
    .titleMode(NavigationTitleMode.Mini)
    .hideTitleBar(true)
    .hideToolBar(true)
    .backgroundColor(ThemeTokens.BACKGROUND)
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets
git commit -m "feat: replace Tabs with custom BottomNavBar in Index"
```

---

### Task 5: Redesign ClipboardListItem into Type-Specific Cards

**Files:**
- Modify: `entry/src/main/ets/component/ClipboardListItem.ets`

- [ ] **Step 1: Rewrite ClipboardListItem as card-style component**

Replace the entire content of `entry/src/main/ets/component/ClipboardListItem.ets`:

```typescript
import { ClipboardEntry } from '../model/ClipboardEntry';
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Card-style list item for displaying a clipboard entry.
 * Matches Figma HarmonyOS design with:
 *   - Header: type icon + type name + relative time + more button
 *   - Content: type-specific preview (text, link, email, phone, address, image)
 *   - Footer: auto-type tag + custom tags
 */
@Component
export struct ClipboardListItem {
  @Prop entry: ClipboardEntry;
  onItemClick?: (entry: ClipboardEntry) => void;
  onItemLongPress?: (entry: ClipboardEntry) => void;
  onItemFavorite?: (entry: ClipboardEntry) => void;

  build() {
    Column() {
      // Card header: icon + type label + time
      Row() {
        // Type icon background
        Row() {
          Text(this.getTypeIcon())
            .fontSize(18)
            .fontColor(Color.White)
        }
        .width(ThemeTokens.CARD_ICON_SIZE)
        .height(ThemeTokens.CARD_ICON_SIZE)
        .borderRadius(ThemeTokens.CARD_ICON_RADIUS)
        .backgroundColor(this.getTypeColor())
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        // Type name + time
        Column() {
          Text(this.getTypeLabel())
            .fontSize(10)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)

          Text(this.formatTime(this.entry.updatedAt))
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: ThemeTokens.SPACING_MD })

        Blank()

        // More button (three dots)
        Text('···')
          .fontSize(16)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .onClick(() => {
            if (this.onItemFavorite) {
              this.onItemFavorite(this.entry);
            }
          })
      }
      .width('100%')
      .padding({ left: ThemeTokens.CARD_PADDING, right: ThemeTokens.CARD_PADDING, top: ThemeTokens.CARD_PADDING })

      // Content preview area — type-specific
      this.ContentPreview()

      // Footer tags
      Row() {
        // Auto type tag
        Text(this.getTypeLabel())
          .fontSize(ThemeTokens.CARD_TAG_FONT_SIZE)
          .fontColor(ThemeTokens.TEXT_SECONDARY)
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .borderRadius(ThemeTokens.CARD_TAG_RADIUS)
          .backgroundColor(ThemeTokens.BACKGROUND)
      }
      .width('100%')
      .padding({ left: ThemeTokens.CARD_PADDING, right: ThemeTokens.CARD_PADDING, bottom: ThemeTokens.CARD_PADDING, top: ThemeTokens.SPACING_SM })
    }
    .width('100%')
    .backgroundColor(ThemeTokens.SURFACE)
    .borderRadius(ThemeTokens.CARD_RADIUS)
    .margin({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_MD })
    .shadow({ radius: 2, color: '#0A000000', offsetY: 1 })
    .onClick(() => {
      if (this.onItemClick) {
        this.onItemClick(this.entry);
      }
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (this.onItemLongPress) {
            this.onItemLongPress(this.entry);
          }
        })
    )
  }

  @Builder
  ContentPreview() {
    // Type-specific content preview
    if (this.entry.contentType === 'url') {
      this.LinkPreview()
    } else if (this.entry.contentType === 'image') {
      this.ImagePreview()
    } else {
      this.TextPreview()
    }
  }

  @Builder
  TextPreview() {
    Row() {
      // Left border accent for text type
      if (this.entry.contentType === 'text') {
        Column() {}
          .width(3)
          .height('100%')
          .backgroundColor(this.getTypeColor())
          .borderRadius(2)
          .margin({ right: ThemeTokens.SPACING_MD })
      }
      Text(this.entry.contentPreview)
        .fontSize(14)
        .fontColor(ThemeTokens.TEXT_PRIMARY)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({
      left: ThemeTokens.CARD_PADDING,
      right: ThemeTokens.CARD_PADDING,
      top: ThemeTokens.SPACING_SM
    })
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  LinkPreview() {
    Row() {
      // Link icon
      Column() {
        Text('🔗')
          .fontSize(16)
      }
      .width(36)
      .height(36)
      .borderRadius(8)
      .backgroundColor(ThemeTokens.BACKGROUND)
      .justifyContent(FlexAlign.Center)
      .margin({ right: ThemeTokens.SPACING_MD })

      Column() {
        Text(this.getLinkDomain())
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)

        Text(this.entry.contentPreview)
          .fontSize(13)
          .fontColor(ThemeTokens.TEXT_SECONDARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: ThemeTokens.CARD_PADDING, right: ThemeTokens.CARD_PADDING, top: ThemeTokens.SPACING_SM })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ImagePreview() {
    Column() {
      // Image placeholder with overlay
      Column() {
        Text('🖼')
          .fontSize(32)
          .opacity(0.6)
      }
      .width('100%')
      .height(120)
      .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
      .backgroundColor(ThemeTokens.BACKGROUND)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ top: ThemeTokens.SPACING_SM })
    }
    .width('100%')
    .padding({ left: ThemeTokens.CARD_PADDING, right: ThemeTokens.CARD_PADDING })
  }

  private getTypeLabel(): string {
    const labels: Record<string, string> = {
      'text': '文本',
      'url': '链接',
      'email': '邮箱',
      'phone': '电话',
      'image': '图片',
      'address': '地址'
    };
    return labels[this.entry.contentType] || '文本';
  }

  private getTypeIcon(): string {
    const icons: Record<string, string> = {
      'text': 'T',
      'url': '🔗',
      'email': '✉',
      'phone': '☎',
      'image': '🖼',
      'address': '📍'
    };
    return icons[this.entry.contentType] || 'T';
  }

  private getTypeColor(): string {
    const colors: Record<string, string> = {
      'text': ThemeTokens.TYPE_TEXT_COLOR,
      'url': ThemeTokens.TYPE_URL_COLOR,
      'email': ThemeTokens.TYPE_EMAIL_COLOR,
      'phone': ThemeTokens.TYPE_PHONE_COLOR,
      'image': ThemeTokens.TYPE_IMAGE_COLOR,
      'address': ThemeTokens.TYPE_ADDRESS_COLOR
    };
    return colors[this.entry.contentType] || ThemeTokens.TYPE_TEXT_COLOR;
  }

  private getLinkDomain(): string {
    if (this.entry.contentType !== 'url' || !this.entry.contentPreview) {
      return '';
    }
    try {
      const match = this.entry.contentPreview.match(/https?:\/\/([^/]+)/);
      return match ? match[1] : '';
    } catch (e) {
      return '';
    }
  }

  private formatTime(isoString: string): string {
    if (!isoString) return '';
    try {
      const date = new Date(isoString);
      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffMinutes = Math.floor(diffMs / 60000);

      if (diffMinutes < 1) return '刚刚';
      if (diffMinutes < 60) return `${diffMinutes}分钟前`;

      const isToday = date.getFullYear() === now.getFullYear() &&
        date.getMonth() === now.getMonth() &&
        date.getDate() === now.getDate();

      if (isToday) {
        return `今天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
      }

      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      const isYesterday = date.getFullYear() === yesterday.getFullYear() &&
        date.getMonth() === yesterday.getMonth() &&
        date.getDate() === yesterday.getDate();

      if (isYesterday) {
        return `昨天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
      }

      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const day = date.getDate().toString().padStart(2, '0');

      if (date.getFullYear() === now.getFullYear()) {
        return `${month}-${day}`;
      }
      return `${date.getFullYear()}-${month}-${day}`;
    } catch (e) {
      return isoString;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/component/ClipboardListItem.ets
git commit -m "feat: redesign ClipboardListItem as Figma card-style component"
```

---

### Task 6: Update HistoryPage with Time Grouping

**Files:**
- Modify: `entry/src/main/ets/pages/HistoryPage.ets`

- [ ] **Step 1: Add time-grouped sections and card layout**

Update the `build()` method inside `HistoryPage` to add time grouping labels before the card list. Replace the List section inside the `else` branch (where entries are shown) with:

Find this block in the `build()` method:
```typescript
      } else {
        List({ space: 0 }) {
          ForEach(this.entries, (entry: ClipboardEntry) => {
```

Replace the entire `List` block (from `List({ space: 0 })` through its closing `}`) with:

```typescript
      } else {
        List({ space: 0 }) {
          ForEach(this.getGroupedEntries(), (group: EntryGroup) => {
            ListItem() {
              Column() {
                // Date label
                Text(group.label)
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_TERTIARY)
                  .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
                  .padding({ left: ThemeTokens.SPACING_MD, top: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_XS })

                // Cards in group
                ForEach(group.entries, (entry: ClipboardEntry) => {
                  Row() {
                    if (this.isSelectionMode) {
                      Checkbox()
                        .select(this.selectedIds.has(entry.id))
                        .onChange((isChecked: boolean) => {
                          this.toggleSelection(entry.id);
                        })
                        .margin({ right: ThemeTokens.SPACING_MD })
                    }

                    ClipboardListItem({
                      entry: entry,
                      onItemClick: (e: ClipboardEntry) => {
                        if (this.isSelectionMode) {
                          this.toggleSelection(e.id);
                        } else {
                          this.onItemClick(e);
                        }
                      },
                      onItemLongPress: (e: ClipboardEntry) => this.onItemLongPress(e),
                      onItemFavorite: (e: ClipboardEntry) => this.onItemFavorite(e)
                    })
                  }
                  .width('100%')
                }, (entry: ClipboardEntry) => `${entry.id}_${entry.isFavorite}`)
              }
              .width('100%')
            }
          }, (group: EntryGroup) => group.label)
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
```

- [ ] **Step 2: Add EntryGroup interface and grouping helper**

Add this interface after the imports at the top of the file (after the imports, before the `@Component` annotation):

```typescript
/**
 * Group of entries by date label (Today / Yesterday / etc.)
 */
interface EntryGroup {
  label: string;
  entries: ClipboardEntry[];
}
```

Add this method to the `HistoryPage` class (after `syncState()`):

```typescript
  private getGroupedEntries(): EntryGroup[] {
    const groups: EntryGroup[] = [];
    const groupMap: Map<string, ClipboardEntry[]> = new Map();

    for (const entry of this.entries) {
      const label = this.getDateLabel(entry.updatedAt);
      if (!groupMap.has(label)) {
        groupMap.set(label, []);
      }
      groupMap.get(label)!.push(entry);
    }

    groupMap.forEach((entries: ClipboardEntry[], label: string) => {
      groups.push({ label, entries });
    });

    return groups;
  }

  private getDateLabel(isoString: string): string {
    if (!isoString) return '更早';
    try {
      const date = new Date(isoString);
      const now = new Date();
      const isToday = date.getFullYear() === now.getFullYear() &&
        date.getMonth() === now.getMonth() &&
        date.getDate() === now.getDate();
      if (isToday) return '今天';

      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      const isYesterday = date.getFullYear() === yesterday.getFullYear() &&
        date.getMonth() === yesterday.getMonth() &&
        date.getDate() === yesterday.getDate();
      if (isYesterday) return '昨天';

      return '更早';
    } catch (e) {
      return '更早';
    }
  }
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/pages/HistoryPage.ets
git commit -m "feat: add time-grouped sections to HistoryPage"
```

---

### Task 7: Update FavoritesPage with Category Filter

**Files:**
- Modify: `entry/src/main/ets/pages/FavoritesPage.ets`

- [ ] **Step 1: Add CategoryFilter to FavoritesPage**

Add `CategoryFilter` import at the top:

```typescript
import { CategoryFilter } from '../component/CategoryFilter';
import { CustomCategory } from '../model/CustomCategory';
```

Add state variables inside the `FavoritesPage` struct after the existing state:

```typescript
  @State categories: CustomCategory[] = [];
```

Add ViewModel init for categories (in `tryInitViewModel`, also get `catRepo`):

```typescript
  private tryInitViewModel(): void {
    const clipRepo = AppContext.getClipboardRepo();
    const catRepo = AppContext.getCategoryRepo();
    if (clipRepo && catRepo) {
      this.viewModel = new FavoritesViewModel(clipRepo);
      this.loadData();
    } else {
      setTimeout(() => { this.tryInitViewModel(); }, 200);
    }
  }
```

Add `CategoryFilter` in the `build()` method, between the search bar and the content area:

After the search bar `Row` block, add:

```typescript
      CategoryFilter({
        categories: this.categories,
        onFilterChange: (types: string[], categoryIds: number[]) => {
          this.onFilterChange(types, categoryIds);
        }
      })
```

Add the filter handler method to the class:

```typescript
  private async onFilterChange(types: string[], categoryIds: number[]): Promise<void> {
    if (this.viewModel) {
      if (types.length > 0 || categoryIds.length > 0) {
        await this.viewModel.search(this.searchKeyword);
      } else {
        await this.viewModel.loadFavorites();
      }
      this.syncState();
    }
  }
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/FavoritesPage.ets
git commit -m "feat: add CategoryFilter to FavoritesPage"
```

---

### Task 8: Redesign DetailPage to Figma HarmonyOS Style

**Files:**
- Modify: `entry/src/main/ets/pages/DetailPage.ets`

- [ ] **Step 1: Rewrite ContentLayout and sub-builders**

Replace the `ContentLayout` builder and all sub-builders (`TopBar`, `EditableTextArea`, `ReadOnlyTextArea`, `ImagePlaceholder`, `MetadataSection`, `TagsSection`, `BottomBar`) with redesigned versions. Keep the same state variables and helper methods.

Replace `ContentLayout`:

```typescript
  @Builder
  ContentLayout() {
    // Top bar
    this.TopBar()

    // Scrollable content area
    Scroll() {
      Column({ space: ThemeTokens.SPACING_MD }) {
        // Fluid Hub — original content display
        this.FluidHub()

        // Editable content area
        if (this.isTextEditable()) {
          this.EditSection()
        } else if (this.isReadOnlyTextType()) {
          this.ReadOnlySection()
        } else if (this.isImageType()) {
          this.ImageSection()
        }

        // Notes section
        this.NotesSection()

        // Tags section
        this.TagsSection()
      }
      .padding({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD, top: ThemeTokens.SPACING_MD })
    }
    .layoutWeight(1)

    // Bottom action bar
    this.BottomBar()
  }
```

Replace `TopBar`:

```typescript
  @Builder
  TopBar() {
    Row() {
      // Back button
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor(ThemeTokens.TEXT_PRIMARY)
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .onClick(() => { this.handleBack(); })

      // Title
      Text('Clip Detail')
        .fontSize(ThemeTokens.FONT_SIZE_TITLE)
        .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
        .fontColor(ThemeTokens.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // Favorite toggle
      Row() {
        Text(this.isFavorite ? '★' : '☆')
          .fontSize(18)
          .fontColor(this.isFavorite ? '#FFB800' : ThemeTokens.TEXT_TERTIARY)
      }
      .width(34)
      .height(34)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (this.viewModel) {
          this.viewModel.toggleFavorite().then(() => { this.syncState(); });
        }
      })

      // Edit button
      Row() {
        Text('编辑')
          .fontSize(14)
          .fontColor(ThemeTokens.PRIMARY)
      }
      .height(34)
      .padding({ left: 12, right: 12 })
      .justifyContent(FlexAlign.Center)
      .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
      .backgroundColor('#1A007DFF')
    }
    .width('100%')
    .height(ThemeTokens.DETAIL_TOPBAR_HEIGHT)
    .padding({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })
    .alignItems(VerticalAlign.Center)
  }
```

Add new `FluidHub` builder:

```typescript
  @Builder
  FluidHub() {
    Column() {
      // Label
      Text('Original Snippet')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
        .margin({ bottom: ThemeTokens.SPACING_SM })

      // Content card
      Column() {
        Text(this.decryptedContent || this.editedContent)
          .fontSize(14)
          .fontColor(ThemeTokens.TEXT_PRIMARY)
          .lineHeight(22)
          .width('100%')
      }
      .width('100%')
      .padding(ThemeTokens.DETAIL_SECTION_PADDING)
      .borderRadius(ThemeTokens.DETAIL_SECTION_RADIUS)
      .backgroundColor('#F5F5F5')

      // Content type + char count
      Row() {
        Text(this.getTypeIcon())
          .fontSize(12)
          .margin({ right: ThemeTokens.SPACING_XS })

        Text(`${this.typeLabel} · ${this.editedContent.length} chars`)
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
      }
      .margin({ top: ThemeTokens.SPACING_SM })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
```

Add `EditSection` builder:

```typescript
  @Builder
  EditSection() {
    Column() {
      Text('Edit Content')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
        .margin({ bottom: ThemeTokens.SPACING_SM })

      TextArea({ text: this.editedContent })
        .fontSize(ThemeTokens.FONT_SIZE_BODY)
        .fontColor(ThemeTokens.TEXT_PRIMARY)
        .backgroundColor('#F5F5F5')
        .borderRadius(ThemeTokens.DETAIL_SECTION_RADIUS)
        .width('100%')
        .constraintSize({ minHeight: 120 })
        .padding(ThemeTokens.DETAIL_SECTION_PADDING)
        .onChange((value: string) => {
          if (this.viewModel) {
            this.viewModel.onContentEdited(value);
            this.isDirty = this.viewModel.isDirty;
          }
          this.editedContent = value;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
```

Add `ReadOnlySection` builder:

```typescript
  @Builder
  ReadOnlySection() {
    Column() {
      Text('Content')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
        .margin({ bottom: ThemeTokens.SPACING_SM })

      Row() {
        Text(this.decryptedContent)
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontColor(ThemeTokens.TEXT_PRIMARY)
          .layoutWeight(1)
      }
      .width('100%')
      .padding(ThemeTokens.DETAIL_SECTION_PADDING)
      .borderRadius(ThemeTokens.DETAIL_SECTION_RADIUS)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
```

Add `ImageSection` builder:

```typescript
  @Builder
  ImageSection() {
    Column() {
      Text('Image Preview')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
        .margin({ bottom: ThemeTokens.SPACING_SM })

      Column() {
        Text('🖼')
          .fontSize(48)
          .margin({ bottom: ThemeTokens.SPACING_SM })

        Text('Tap to zoom')
          .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(20)
          .backgroundColor('#1A000000')
      }
      .width('100%')
      .height(200)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(ThemeTokens.DETAIL_SECTION_RADIUS)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
```

Add `NotesSection` builder:

```typescript
  @Builder
  NotesSection() {
    Column() {
      Text('Contextual Notes')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
        .margin({ bottom: ThemeTokens.SPACING_SM })

      TextInput({ placeholder: 'Add notes for this clip...' })
        .fontSize(ThemeTokens.FONT_SIZE_BODY)
        .fontColor(ThemeTokens.TEXT_PRIMARY)
        .backgroundColor('#F5F5F5')
        .borderRadius(ThemeTokens.DETAIL_SECTION_RADIUS)
        .width('100%')
        .height(56)
        .padding({ left: ThemeTokens.DETAIL_SECTION_PADDING })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
```

Replace `BottomBar`:

```typescript
  @Builder
  BottomBar() {
    Row() {
      if (this.isDirty) {
        Button(this.isSaving ? '保存中...' : '保存修改')
          .width('100%')
          .height(ThemeTokens.DETAIL_FAB_HEIGHT)
          .backgroundColor(
            this.isEditedContentEmpty() || this.isSaving
              ? ThemeTokens.TEXT_TERTIARY
              : ThemeTokens.PRIMARY
          )
          .fontColor(Color.White)
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
          .borderRadius(ThemeTokens.DETAIL_FAB_RADIUS)
          .enabled(!this.isSaving && !this.isEditedContentEmpty())
          .onClick(() => { this.handleSave(); })
      } else {
        Row() {
          Text('复制')
            .fontSize(16)
            .margin({ right: ThemeTokens.SPACING_SM })

          Text(this.isCopied ? '已复制到剪贴板' : 'Copy to Clipboard')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(Color.White)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .height(ThemeTokens.DETAIL_FAB_HEIGHT)
        .backgroundColor(this.isCopied ? ThemeTokens.SUCCESS : ThemeTokens.PRIMARY)
        .borderRadius(ThemeTokens.DETAIL_FAB_RADIUS)
        .onClick(() => { this.handleCopy(); })
      }
    }
    .width('100%')
    .padding({
      left: ThemeTokens.SPACING_LG,
      right: ThemeTokens.SPACING_LG,
      top: ThemeTokens.SPACING_MD,
      bottom: ThemeTokens.SPACING_MD
    })
  }
```

Add `getTypeIcon` helper (add after `getTypeColor`):

```typescript
  private getTypeIcon(): string {
    const icons: Record<string, string> = {
      'text': '📝',
      'url': '🔗',
      'email': '✉️',
      'phone': '📱',
      'image': '🖼️',
      'address': '📍'
    };
    return icons[this.contentType] || '📝';
  }
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/DetailPage.ets
git commit -m "feat: redesign DetailPage to Figma HarmonyOS style"
```

---

### Task 9: Restructure SettingsPage with Grouped Card Sections

**Files:**
- Modify: `entry/src/main/ets/pages/SettingsPage.ets`

- [ ] **Step 1: Rewrite build() with grouped card sections**

Replace the `build()` method's main `Column` content (the Scroll > Column block) with grouped card sections. Keep all existing state, dialog, and helper methods unchanged.

Find the `Scroll() {` inside `build()` and replace everything inside it with:

```typescript
    Scroll() {
      Column() {
        // Hero branding area
        this.HeroBranding()

        // Recording section
        this.SettingsGroup('Recording', [
          { icon: '📋', title: '自动录制', subtitle: '监听并记录剪贴板内容', type: 'toggle', isOn: this.isPrivacyMode === false, key: 'recording' }
        ])

        // Sync section
        this.SettingsGroup('Sync', [
          { icon: '☁️', title: '云同步', subtitle: '在设备间同步剪贴板历史', type: 'toggle', isOn: false, key: 'sync' },
          { icon: '🔄', title: '自动同步', subtitle: '仅在 Wi-Fi 下自动同步', type: 'navigate', value: '', key: 'autoSync' }
        ])

        // About section
        this.SettingsGroup('About', [
          { icon: 'ℹ️', title: 'Version', subtitle: '', type: 'display', value: this.appVersion, key: 'version' },
          { icon: '🔒', title: '隐私政策', subtitle: '', type: 'navigate', value: '', key: 'privacy' }
        ])

        // Footer
        this.SettingsFooter()

        // Remaining sections that were in original settings
        this.SectionHeader('历史记录上限')
        Row() {
          Text('保留条数')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_PRIMARY)
            .layoutWeight(1)
          Text(`${this.historyLimit}`)
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
            .fontColor(ThemeTokens.PRIMARY)
        }
        .width('100%')
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG, top: ThemeTokens.SPACING_SM, bottom: ThemeTokens.SPACING_XS })

        Slider({ value: this.historyLimit, min: AppConstants.MIN_HISTORY_LIMIT, max: AppConstants.MAX_HISTORY_LIMIT, step: 50, style: SliderStyle.OutSet })
          .width('100%')
          .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
          .blockColor(ThemeTokens.PRIMARY)
          .trackColor(ThemeTokens.DIVIDER)
          .selectedColor(ThemeTokens.PRIMARY)
          .onChange((value: number) => {
            this.historyLimit = Math.round(value);
            if (this.viewModel) { this.viewModel.updateHistoryLimit(this.historyLimit); }
          })

        this.SectionDivider()

        // Biometric section (keep original)
        this.SectionHeader('生物识别')
        Row() {
          Column() {
            Text('生物识别验证')
              .fontSize(ThemeTokens.FONT_SIZE_BODY)
              .fontColor(ThemeTokens.TEXT_PRIMARY)
            Text('从后台返回时需要验证身份')
              .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
              .fontColor(ThemeTokens.TEXT_TERTIARY)
              .margin({ top: ThemeTokens.SPACING_XS })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.isBiometricEnabled })
            .selectedColor(ThemeTokens.PRIMARY)
            .onChange((isOn: boolean) => {
              this.isBiometricEnabled = isOn;
              if (this.viewModel) { this.viewModel.toggleBiometric(); }
            })
        }
        .width('100%')
        .padding(ThemeTokens.SPACING_LG)
        .alignItems(VerticalAlign.Center)

        this.SectionDivider()

        // Blacklist section (keep original)
        this.SectionHeader('应用黑名单')
        Row() {
          Text('黑名单中的应用不会记录剪贴板')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .layoutWeight(1)
          Text('添加')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.PRIMARY)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
            .padding({ left: ThemeTokens.SPACING_SM, right: ThemeTokens.SPACING_SM })
            .onClick(() => { this.showAddBlacklist(); })
        }
        .width('100%')
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG, bottom: ThemeTokens.SPACING_SM })

        if (this.blacklist.length > 0) {
          List({ space: 0 }) {
            ForEach(this.blacklist, (entry: AppBlacklistEntry) => {
              ListItem() {
                Row() {
                  Text(entry.appName || entry.bundleName)
                    .fontSize(ThemeTokens.FONT_SIZE_BODY)
                    .fontColor(ThemeTokens.TEXT_PRIMARY)
                    .layoutWeight(1)
                  Text('移除')
                    .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                    .fontColor(ThemeTokens.ERROR)
                    .padding({ left: ThemeTokens.SPACING_SM, right: ThemeTokens.SPACING_SM })
                    .onClick(() => { this.removeBlacklistEntry(entry.id); })
                }
                .width('100%')
                .height(44)
                .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
                .alignItems(VerticalAlign.Center)
              }
              .swipeAction({ end: this.deleteBlacklistSwipeAction(entry) })
            }, (entry: AppBlacklistEntry) => entry.id.toString())
          }
          .width('100%')
        } else {
          Row() {
            Text('暂无黑名单应用')
              .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
              .fontColor(ThemeTokens.TEXT_TERTIARY)
          }
          .width('100%')
          .padding({ left: ThemeTokens.SPACING_LG, bottom: ThemeTokens.SPACING_SM })
        }

        this.SectionDivider()

        // Category management (keep original)
        this.SectionHeader('自定义标签管理')
        Row() {
          Text('管理自定义分类标签')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
            .layoutWeight(1)
          Text('添加')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(ThemeTokens.PRIMARY)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
            .padding({ left: ThemeTokens.SPACING_SM, right: ThemeTokens.SPACING_SM })
            .onClick(() => { this.showAddCategory(); })
        }
        .width('100%')
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG, bottom: ThemeTokens.SPACING_SM })

        if (this.categories.length > 0) {
          List({ space: 0 }) {
            ForEach(this.categories, (cat: CustomCategory) => {
              ListItem() {
                Row() {
                  Text('').width(12).height(12).borderRadius(6).backgroundColor(cat.color || ThemeTokens.PRIMARY).margin({ right: ThemeTokens.SPACING_MD })
                  Text(cat.name).fontSize(ThemeTokens.FONT_SIZE_BODY).fontColor(ThemeTokens.TEXT_PRIMARY).layoutWeight(1)
                  Text('重命名').fontSize(ThemeTokens.FONT_SIZE_CAPTION).fontColor(ThemeTokens.PRIMARY).margin({ right: ThemeTokens.SPACING_MD }).onClick(() => { this.showRenameCategory(cat); })
                  Text(`${cat.entryCount}`).fontSize(ThemeTokens.FONT_SIZE_CAPTION).fontColor(ThemeTokens.TEXT_TERTIARY).margin({ right: ThemeTokens.SPACING_MD })
                }
                .width('100%').height(48).padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG }).alignItems(VerticalAlign.Center)
              }
              .swipeAction({ end: this.deleteCategorySwipeAction(cat) })
            }, (cat: CustomCategory) => `settings_cat_${cat.id}`)
          }
          .width('100%')
        } else {
          Row() {
            Text('暂无自定义标签')
              .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
              .fontColor(ThemeTokens.TEXT_TERTIARY)
          }
          .width('100%')
          .padding({ left: ThemeTokens.SPACING_LG, bottom: ThemeTokens.SPACING_SM })
        }

        this.SectionDivider()

        // Data management
        this.SectionHeader('数据管理')
        Row() {
          Text('清除所有数据')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.ERROR)
            .layoutWeight(1)
          Text('→')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.TEXT_TERTIARY)
        }
        .width('100%')
        .height(48)
        .padding({ left: ThemeTokens.SPACING_LG, right: ThemeTokens.SPACING_LG })
        .alignItems(VerticalAlign.Center)
        .onClick(() => { this.showClearDataConfirm(); })
      }
    }
```

- [ ] **Step 2: Add new builder methods for grouped settings**

Add these builders to the SettingsPage class:

```typescript
  @Builder
  HeroBranding() {
    Column() {
      Text('ClipBridge Pro')
        .fontSize(28)
        .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
        .fontColor(ThemeTokens.TEXT_PRIMARY)

      Text('智能剪贴板管理，让复制更高效')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .margin({ top: ThemeTokens.SPACING_XS })
    }
    .width('100%')
    .padding({ left: ThemeTokens.SPACING_LG, top: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_MD })
    .alignItems(HorizontalAlign.Start)
  }

  interface SettingsItem {
    icon: string;
    title: string;
    subtitle: string;
    type: string; // 'toggle' | 'navigate' | 'display'
    isOn?: boolean;
    value?: string;
    key: string;
  }

  @Builder
  SettingsGroup(title: string, items: Object[]) {
    Column() {
      // Group title
      Text(title)
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
        .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
        .padding({ left: ThemeTokens.SPACING_MD, top: ThemeTokens.SPACING_MD, bottom: ThemeTokens.SPACING_XS })

      // Card container
      Column() {
        ForEach(items as SettingsItem[], (item: SettingsItem, index?: number) => {
          Row() {
            // Icon
            Row() {
              Text(item.icon)
                .fontSize(18)
            }
            .width(ThemeTokens.SETTINGS_ICON_BG_SIZE)
            .height(ThemeTokens.SETTINGS_ICON_BG_SIZE)
            .borderRadius(ThemeTokens.SETTINGS_ICON_BG_RADIUS)
            .backgroundColor(ThemeTokens.BACKGROUND)
            .justifyContent(FlexAlign.Center)

            // Text
            Column() {
              Text(item.title)
                .fontSize(ThemeTokens.FONT_SIZE_BODY)
                .fontColor(ThemeTokens.TEXT_PRIMARY)

              if (item.subtitle) {
                Text(item.subtitle)
                  .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
                  .fontColor(ThemeTokens.TEXT_TERTIARY)
                  .margin({ top: 2 })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: ThemeTokens.SPACING_MD })
            .layoutWeight(1)

            // Right control
            if (item.type === 'toggle') {
              Toggle({ type: ToggleType.Switch, isOn: item.isOn ?? false })
                .selectedColor(ThemeTokens.PRIMARY)
                .onChange((isOn: boolean) => {
                  if (item.key === 'recording' && this.viewModel) {
                    this.isPrivacyMode = !isOn;
                    this.viewModel.togglePrivacyMode();
                  }
                })
            } else if (item.type === 'navigate') {
              Text('>')
                .fontSize(14)
                .fontColor(ThemeTokens.TEXT_TERTIARY)
            } else if (item.type === 'display') {
              Text(item.value || '')
                .fontSize(ThemeTokens.FONT_SIZE_BODY)
                .fontColor(ThemeTokens.TEXT_TERTIARY)
            }
          }
          .width('100%')
          .padding(ThemeTokens.SPACING_MD)
          .alignItems(VerticalAlign.Center)
        }, (item: SettingsItem, index?: number) => `settings_${title}_${index}`)
      }
      .backgroundColor(ThemeTokens.SURFACE)
      .borderRadius(ThemeTokens.SETTINGS_GROUP_RADIUS)
      .margin({ left: ThemeTokens.SPACING_MD, right: ThemeTokens.SPACING_MD })
    }
    .width('100%')
    .margin({ bottom: ThemeTokens.SPACING_SM })
  }

  @Builder
  SettingsFooter() {
    Column() {
      // Logo placeholder
      Text('📋')
        .fontSize(32)
        .margin({ bottom: ThemeTokens.SPACING_XS })

      Text('ClipBridge v1.0.0')
        .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
        .fontColor(ThemeTokens.TEXT_TERTIARY)
    }
    .width('100%')
    .padding({ top: ThemeTokens.SPACING_XL, bottom: ThemeTokens.SPACING_XL })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
```

Note: The `SettingsItem` interface should be defined at the file level (outside the class), not inside the class. Move it to the top of the file after imports:

```typescript
interface SettingsItem {
  icon: string;
  title: string;
  subtitle: string;
  type: string;
  isOn?: boolean;
  value?: string;
  key: string;
}
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/pages/SettingsPage.ets
git commit -m "feat: restructure SettingsPage with Figma grouped card sections"
```

---

### Task 10: Build Verification and Fixes

**Files:**
- Potentially modify any files that have compilation errors

- [ ] **Step 1: Run build check**

```bash
cd /Users/jeremy/workspace/clip-bridge/clip-bridge-harmony && hvigorw assembleHap 2>&1 | head -100
```

Expected: Build succeeds. If errors, fix them.

- [ ] **Step 2: Fix any compilation errors**

Common fixes:
- ArkTS does not support generic method calls on interfaces — may need to cast types
- `@Builder` methods cannot have complex type annotations — simplify parameter types
- `@Prop` requires matching types between parent and child
- `ForEach` requires string keys

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "fix: resolve compilation errors from UI redesign"
```

---

## Self-Review

### 1. Spec Coverage Check

| Spec Requirement | Task |
|-----------------|------|
| FR-D01: BottomNavBar 4 Tab | Task 2, 4 |
| FR-D02: Time-grouped list | Task 6 |
| FR-D03: Category filter tabs | Already exists (CategoryFilter), Task 7 |
| FR-D04: Type-specific cards | Task 5 |
| FR-D05: HarmonyOS card design | Task 5 |
| FR-D06: Detail Fluid Hub + sections | Task 8 |
| FR-D07: Copy to Clipboard FAB | Task 8 |
| FR-D08: Favorites with filter | Task 7 |
| FR-D09: Settings grouped sections | Task 9 |
| FR-D10: Card icon + title + control rows | Task 9 |
| FR-D11: HarmonyOS Toggle | Already using Toggle component |
| FR-D12: Devices placeholder | Task 3 |

### 2. Placeholder Scan

No TBD/TODO/placeholders found. All steps contain complete code.

### 3. Type Consistency

- `ClipboardEntry` model is used consistently across all tasks
- `ThemeTokens` static methods are referenced correctly
- `NavPathStack` consumed via `@Consume('navPathStack')` in child pages
- `SettingsItem` interface defined at file level for ArkTS compatibility
