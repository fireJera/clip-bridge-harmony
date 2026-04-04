@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('Clip Bridge')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .margin({ top: 100 })

      Text('Clipboard Manager')
        .fontSize(16)
        .fontColor('#99182431')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F1F3F5')
  }
}
