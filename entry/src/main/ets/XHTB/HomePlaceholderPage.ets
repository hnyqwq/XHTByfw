/**
 * 分栏模式(Navigation Split)工具列表右侧的默认占位页
 * 栈为空时显示品牌 logo 与应用名
 */
@Component
export struct HomePlaceholderPage {
  build() {
    NavDestination() {
      Column() {
        Image($r('app.media.CIcon'))
          .width(96)
          .height(96)
          .borderRadius(22)
        Text($r('app.string.appname'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
          .margin({ top: 20 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.White'))
    }
    .hideTitleBar(true)
    .onShown(() => {
      AppStorage.setOrCreate('toolPageActive', false);
    })
    .onHidden(() => {
      AppStorage.setOrCreate('toolPageSyncTick', Date.now());
    })
  }
}
