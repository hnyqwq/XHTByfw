import { GlobalInfoModel } from '../../common/GlobalInfoModel';
import { ToolNavTitleBar } from '../../components/ToolNavTitleBar';

interface SliderRowItem {
  label: ResourceStr;
  value: number;
  trackColor: ResourceColor;
  onChange: (v: number) => void;
}

interface ColorValueItem {
  label: string;
  value: string;
}

@Component
export struct ColorPickerPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State red: number = 255;
  @State green: number = 143;
  @State blue: number = 67;
  @State hexValue: string = '#FF8F43';
  @State rgbValue: string = '';
  @State hslValue: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/Utils/ColorPickerPage');
    AppStorage.delete('currentRouteParams');
    this.updateHex();
  }

  private updateHex(): void {
    let r = this.red.toString(16).toUpperCase().padStart(2, '0');
    let g = this.green.toString(16).toUpperCase().padStart(2, '0');
    let b = this.blue.toString(16).toUpperCase().padStart(2, '0');
    this.hexValue = '#' + r + g + b;
    this.rgbValue = this.getRgbString();
    this.hslValue = this.getHslString();
  }

  private getRgbString(): string {
    return 'rgb(' + this.red.toString() + ', ' + this.green.toString() + ', ' + this.blue.toString() + ')';
  }

  private getHslString(): string {
    let r = this.red / 255;
    let g = this.green / 255;
    let b = this.blue / 255;
    let max = Math.max(r, g, b);
    let min = Math.min(r, g, b);
    let h = 0;
    let s = 0;
    let l = (max + min) / 2;
    if (max !== min) {
      let d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      if (max === r) {
        h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
      } else if (max === g) {
        h = ((b - r) / d + 2) / 6;
      } else {
        h = ((r - g) / d + 4) / 6;
      }
    }
    return 'hsl(' + Math.round(h * 360).toString() + ', ' + Math.round(s * 100).toString() + '%, ' + Math.round(l * 100).toString() + '%)';
  }

  build() {
    NavDestination() {
    Column({ space: 0 }) {
      Scroll(this.scroller) {
        Column({ space: 16 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolNavTitleBar({ title: $r('app.string.sub_title7_value2') })
          Column() {
            Row()
              .width('100%')
              .height(120)
              .borderRadius(12)
              .backgroundColor(this.hexValue)
          }
          .width('90%')

          Column({ space: 12 }) {
            // 注意:@Builder必须按引用传递(对象字面量),按值传递不会随状态刷新
            this.sliderRow({
              label: $r('app.string.color_picker_red'), value: this.red, trackColor: Color.Red,
              onChange: (v: number) => { this.red = v; this.updateHex(); }
            })
            this.sliderRow({
              label: $r('app.string.color_picker_green'), value: this.green, trackColor: Color.Green,
              onChange: (v: number) => { this.green = v; this.updateHex(); }
            })
            this.sliderRow({
              label: $r('app.string.color_picker_blue'), value: this.blue, trackColor: Color.Blue,
              onChange: (v: number) => { this.blue = v; this.updateHex(); }
            })
          }
          .width('90%')

          Column({ space: 8 }) {
            this.colorValueRow({ label: 'HEX', value: this.hexValue })
            this.colorValueRow({ label: 'RGB', value: this.rgbValue })
            this.colorValueRow({ label: 'HSL', value: this.hslValue })
          }
          .width('90%')
          .padding(16)
          .borderRadius(12)
          .backgroundColor($r('app.color.second'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }

  @Builder
  sliderRow(item: SliderRowItem) {
    Row() {
      Text(item.label)
        .fontSize(14)
        .width(50)
      Slider({
        value: item.value,
        min: 0,
        max: 255,
        step: 1,
        style: SliderStyle.InSet
      })
        .trackColor(item.trackColor)
        .width('50%')
        .onChange((v: number) => { item.onChange(v); })
      Text(item.value.toString())
        .fontSize(14)
        .width(40)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  @Builder
  colorValueRow(item: ColorValueItem) {
    Row() {
      Text(item.label)
        .fontSize(14)
        .fontColor($r('app.color.font_secondary'))
        .width(40)
      Text(item.value)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .copyOption(CopyOptions.LocalDevice)
        .layoutWeight(1)
    }
    .width('100%')
  }
}
