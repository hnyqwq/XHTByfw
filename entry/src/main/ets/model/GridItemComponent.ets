import { CommonConstants } from '../constants/CommonConstants';
import { navigationManager } from '../common/NavigationManager';
import { GlobalInfoModel } from '../common/GlobalInfoModel';
import { UsageTracker } from '../common/utils/UsageTracker';

@Component
export default struct GridItemComponent {
  itemName: ResourceStr = '';
  itemImage?: Resource;
  itemSymbol?: Resource;
  @State isPressed: boolean = false;
  @Prop cardHeight: number = 92;
  @Prop glyphSize: number = 24;
  pageUrl: string = '';
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;

  build() {
    Column() {
      if (this.itemSymbol) {
        SymbolGlyph(this.itemSymbol)
          .fontSize(this.glyphSize)
          .fontColor([$r('sys.color.icon_primary')])
      } else if (this.itemImage) {
        Image(this.itemImage)
          .width(this.glyphSize)
          .height(this.glyphSize)
      }
      Text(this.itemName)
        .fontSize(13)
        .fontColor($r('app.color.font_primary'))
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(this.cardHeight)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.isPressed ? $r('app.color.pressed_color') : Color.Transparent)
    .borderRadius(10)
    .onClick(() => {
      if (this.pageUrl !== '') {
        navigationManager.pushPath(this.pageUrl);
        UsageTracker.getInstance().recordUsage(this.pageUrl);
      }
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
  }
}
