import { CustomCategory } from '../model/CustomCategory';
import { ThemeTokens } from '../common/theme/ThemeTokens';

/**
 * Dialog for picking custom category tags to apply to a clipboard entry.
 *
 * Shows a list of all available custom categories with checkboxes.
 * Categories already applied to the entry appear pre-checked.
 * Includes a "Create new category" option at the bottom that reveals
 * an inline name input field.
 *
 * Usage:
 *   CategoryPickerDialog({
 *     categories: allCategories,
 *     selectedIds: currentlyAppliedIds,
 *     onConfirm: (ids) => { ... },
 *     onCreateCategory: (name) => { ... }
 *   })
 */
@CustomDialog
export struct CategoryPickerDialog {
  @State categories: CustomCategory[] = [];
  @State checkedIds: Set<number> = new Set();
  @State isNewCategoryVisible: boolean = false;
  @State newCategoryName: string = '';
  controller: CustomDialogController;
  onConfirm?: (selectedIds: number[]) => void;
  onCreateCategory?: (name: string) => void;

  aboutToAppear(): void {
    // checkedIds is initialized from selectedIds prop passed by caller
  }

  build() {
    Column() {
      // Title
      Text('选择标签')
        .fontSize(ThemeTokens.FONT_SIZE_TITLE)
        .fontWeight(ThemeTokens.FONT_WEIGHT_BOLD)
        .fontColor(ThemeTokens.TEXT_PRIMARY)
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ bottom: ThemeTokens.SPACING_MD })

      // Category list
      if (this.categories.length > 0) {
        List({ space: 0 }) {
          ForEach(this.categories, (cat: CustomCategory) => {
            ListItem() {
              Row() {
                // Checkbox
                Checkbox()
                  .select(this.checkedIds.has(cat.id))
                  .selectedColor(cat.color || ThemeTokens.PRIMARY)
                  .onChange((isChecked: boolean) => {
                    this.onCheckChanged(cat.id, isChecked);
                  })
                  .width(24)
                  .height(24)
                  .margin({ right: ThemeTokens.SPACING_MD })

                // Color dot
                Text('')
                  .width(12)
                  .height(12)
                  .borderRadius(6)
                  .backgroundColor(cat.color || ThemeTokens.PRIMARY)
                  .margin({ right: ThemeTokens.SPACING_SM })

                // Category name
                Text(cat.name)
                  .fontSize(ThemeTokens.FONT_SIZE_BODY)
                  .fontColor(ThemeTokens.TEXT_PRIMARY)
                  .layoutWeight(1)
              }
              .width('100%')
              .height(48)
              .padding({ left: ThemeTokens.SPACING_SM, right: ThemeTokens.SPACING_SM })
              .alignItems(VerticalAlign.Center)
            }
          }, (cat: CustomCategory) => `pick_${cat.id}`)
        }
        .width('100%')
        .height(240)
        .divider({ strokeWidth: 0.5, color: ThemeTokens.DIVIDER })
      } else {
        // No categories yet
        Text('还没有自定义标签')
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontColor(ThemeTokens.TEXT_TERTIARY)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(ThemeTokens.SPACING_XL)
      }

      // Divider
      Divider()
        .color(ThemeTokens.DIVIDER)
        .margin({ top: ThemeTokens.SPACING_SM, bottom: ThemeTokens.SPACING_SM })

      // "Create new category" section
      if (!this.isNewCategoryVisible) {
        Row() {
          Text('+ 新建标签')
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .fontColor(ThemeTokens.PRIMARY)
            .fontWeight(ThemeTokens.FONT_WEIGHT_MEDIUM)
        }
        .width('100%')
        .height(44)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.isNewCategoryVisible = true;
        })
      } else {
        // Inline new category input
        Row() {
          TextInput({ placeholder: '输入标签名称', text: this.newCategoryName })
            .type(InputType.Normal)
            .fontSize(ThemeTokens.FONT_SIZE_BODY)
            .layoutWeight(1)
            .height(40)
            .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
            .onChange((value: string) => {
              this.newCategoryName = value;
            })

          Button('创建')
            .fontSize(ThemeTokens.FONT_SIZE_CAPTION)
            .fontColor(Color.White)
            .backgroundColor(ThemeTokens.PRIMARY)
            .height(36)
            .borderRadius(ThemeTokens.BORDER_RADIUS_SM)
            .margin({ left: ThemeTokens.SPACING_SM })
            .enabled(this.newCategoryName.trim().length > 0)
            .onClick(() => {
              if (this.onCreateCategory && this.newCategoryName.trim()) {
                this.onCreateCategory(this.newCategoryName.trim());
                this.newCategoryName = '';
                this.isNewCategoryVisible = false;
              }
            })
        }
        .width('100%')
        .padding({ top: ThemeTokens.SPACING_XS, bottom: ThemeTokens.SPACING_XS })
      }

      // Confirm / Cancel buttons
      Row() {
        Button('取消')
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontColor(ThemeTokens.TEXT_SECONDARY)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onClick(() => {
            this.controller.close();
          })

        Button('确定')
          .fontSize(ThemeTokens.FONT_SIZE_BODY)
          .fontColor(Color.White)
          .backgroundColor(ThemeTokens.PRIMARY)
          .layoutWeight(1)
          .onClick(() => {
            if (this.onConfirm) {
              this.onConfirm(Array.from(this.checkedIds));
            }
            this.controller.close();
          })
      }
      .width('100%')
      .margin({ top: ThemeTokens.SPACING_MD })
    }
    .padding(ThemeTokens.SPACING_LG)
    .backgroundColor(ThemeTokens.SURFACE)
    .borderRadius(ThemeTokens.BORDER_RADIUS_LG)
  }

  private onCheckChanged(id: number, isChecked: boolean): void {
    const newSet = new Set(this.checkedIds);
    if (isChecked) {
      newSet.add(id);
    } else {
      newSet.delete(id);
    }
    this.checkedIds = newSet;
  }
}
