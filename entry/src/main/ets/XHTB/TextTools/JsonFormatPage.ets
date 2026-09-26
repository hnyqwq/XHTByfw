import { GlobalInfoModel } from '../../common/GlobalInfoModel';
import { ToolNavTitleBar } from '../../components/ToolNavTitleBar';
import { KeyboardLiftScroll } from '../../common/utils/KeyboardLiftScroll';

@Component
export struct JsonFormatPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State inputText: string = '';
  @State resultText: string = '';
  @State errorMsg: string = '';
  @State isCompress: boolean = false;
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/TextTools/JsonFormatPage');
    AppStorage.delete('currentRouteParams');
  }

  private formatJson(): void {
    this.errorMsg = '';
    if (!this.inputText.trim()) {
      this.resultText = '';
      return;
    }
    try {
      let parsed: Object = JSON.parse(this.inputText);
      if (this.isCompress) {
        this.resultText = JSON.stringify(parsed);
      } else {
        this.resultText = JSON.stringify(parsed, null, 2);
      }
    } catch (e) {
      let err = e as Error;
      this.errorMsg = err.message;
      this.resultText = '';
    }
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
      KeyboardLiftScroll({ scroller: this.scroller }) {
        Column({ space: 16 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolNavTitleBar({ title: $r('app.string.sub_title4_value3') })
          Row({ space: 12 }) {
            Button($r('app.string.json_format_prettify'))
              .type(ButtonType.Capsule)
              .backgroundColor(!this.isCompress ? $r('app.color.brand') : Color.Gray)
              .fontColor(Color.White)
              .onClick(() => { this.isCompress = false; this.formatJson(); })
            Button($r('app.string.json_format_compress'))
              .type(ButtonType.Capsule)
              .backgroundColor(this.isCompress ? $r('app.color.brand') : Color.Gray)
              .fontColor(Color.White)
              .onClick(() => { this.isCompress = true; this.formatJson(); })
          }

          TextArea({ placeholder: $r('app.string.json_format_input_hint'), text: this.inputText })
            .id('kbLiftInput')
            .width('90%')
            .height(180)
            .onChange((value: string) => { this.inputText = value; })

          Button($r('app.string.json_format_execute'))
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.brand'))
            .fontColor(Color.White)
            .width('90%')
            .onClick(() => { this.formatJson(); })

          if (this.errorMsg) {
            Text(this.errorMsg)
              .fontSize(13)
              .fontColor(Color.Red)
              .width('90%')
              .padding(12)
              .borderRadius(8)
              .backgroundColor('#FFF0F0')
          }

          if (this.resultText) {
            Column() {
              Text($r('app.string.json_format_result'))
                .fontSize(14)
                .fontColor($r('app.color.font_secondary'))
                .margin({ bottom: 8 })
              Scroll() {
                Text(this.resultText)
                  .fontSize(12)
                  .fontFamily('monospace')
                  .copyOption(CopyOptions.LocalDevice)
                  .width('100%')
              }
              .height(200)
              .width('100%')
            }
            .width('90%')
            .padding(16)
            .borderRadius(12)
            .backgroundColor($r('app.color.second'))
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      }
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }
}
