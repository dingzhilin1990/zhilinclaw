@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('ZhiLinClaw')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      Text('本地优先的开源 AI助手系统')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 40 })
      
      Text('Local-First AI Assistant Framework')
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
