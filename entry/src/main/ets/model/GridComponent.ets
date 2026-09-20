import { GridData, GridItemInfo } from '../model/GridListDataSources';
import GridItemComponent from './GridItemComponent';

@Component
export default struct GridComponent {
  @State gridData: GridData = new GridData('', []);
  @State isLastItem: boolean = false;
  @Prop columns: number = 2;
  @Prop itemH: number = 92;
  @Prop iconSize: number = 24;
  @Prop titleSize: number = 14;
  @Prop showTitle: boolean = true;
  @State gridWidth: number = 0;

  // 拖拽分栏时宫格宽度变化，按宽度自适应列数（常用功能约 80vp/列，分类宫格约 130vp/列，2~4 列）
  private getColumnsTemplate(): string {
    if (this.gridWidth <= 0) {
      return this.columns >= 4 ? '1fr 1fr 1fr 1fr' : '1fr 1fr';
    }
    const minCell = this.columns >= 4 ? 80 : 130;
    const cols = Math.max(2, Math.min(4, Math.floor(this.gridWidth / minCell)));
    return new Array(cols).fill('1fr').join(' ');
  }

  build() {
    Column() {
      if (this.showTitle) {
        Text(this.gridData.groupName)
          .fontSize(this.titleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
          .margin({ top: 8, bottom: 6 })
          .padding({ left: 16, right: 16 })
          .width('100%')
      }

      Grid() {
        ForEach(this.gridData.gridItemList, (item: GridItemInfo, index: number) => {
          GridItem() {
            GridItemComponent({ itemName: item.name, pageUrl: item.pageUrl, itemImage: item.icon, itemSymbol: item.symbol, cardHeight: this.itemH, glyphSize: this.iconSize })
          }
        }, (item: GridItemInfo, index: number) => index + JSON.stringify(item))
      }
      .columnsTemplate(this.getColumnsTemplate())
      .onAreaChange((oldArea: Area, newArea: Area) => {
        this.gridWidth = Number(newArea.width);
      })
      .margin({ left: 12, right: 12, bottom: 4 })
      .borderRadius(16)
      .padding({ top: 2, bottom: 2 })
      .backgroundColor($r('app.color.second'))

      if (this.isLastItem) {
        Blank()
          .height(20)
      }
    }
  }
}
