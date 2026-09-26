import { NavigationManager } from '../common/NavigationManager';

/**
 * 工具页自定义标题栏(用于 NavDestination.hideTitleBar(true) 后):
 * 顶部 Blank 避让状态栏与元服务胶囊,下方返回键+标题
 */
@Component
export struct ToolNavTitleBar {
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @Prop title: ResourceStr = '';

  build() {
    Column() {
      Blank().height(Math.max(px2vp(this.topRectHeight) + 25, 60)).width('100%')
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(26)
          .fontColor([$r('sys.color.icon_primary')])
          .onClick(() => {
            NavigationManager.getInstance().popPath();
          })
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 8 })
        Blank()
      }
      .width('100%')
      .height(44)
      .padding({ left: 12, right: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }
}
