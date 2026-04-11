/**
 * Splash screen — minimal brand display.
 * Shows logo, name "鹊桥", and slogan.
 * Auto-dismisses after 800ms via onFinished callback.
 */
@Component
export struct SplashPage {
  onFinished: () => void = () => {};

  aboutToAppear(): void {
    setTimeout(() => {
      this.onFinished();
    }, 800);
  }

  build() {
    Column() {
      Image($r('app.media.app_icon'))
        .width(120)
        .height(120)
        .objectFit(ImageFit.Contain)
        .margin({ bottom: 40 })

      Text('鹊桥')
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .letterSpacing(10)

      Column() {}
        .width(48)
        .height(2)
        .borderRadius(1)
        .backgroundColor('#b4c5ff4D')
        .margin({ top: 24, bottom: 24 })

      Text('星河虽远，一贴即达')
        .fontSize(18)
        .fontWeight(FontWeight.Lighter)
        .fontColor('#b4c5ffCC')
        .letterSpacing(8)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#00174B')
  }
}
