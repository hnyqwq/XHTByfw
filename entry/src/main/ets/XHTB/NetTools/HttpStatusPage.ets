import { http } from '@kit.NetworkKit';
import { ToolPageTitleBar } from '../../components/ToolPageTitleBar';
import { BusinessError } from '@kit.BasicServicesKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { GlobalInfoModel } from '../../common/GlobalInfoModel';
import { KeyboardLiftScroll } from '../../common/utils/KeyboardLiftScroll';

@Component
export struct HttpStatusPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State inputUrl: string = '';
  @State statusCode: number = 0;
  @State responseHeaders: string = '';
  @State isChecking: boolean = false;
  @State hasResult: boolean = false;
  @State errorMsg: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/NetTools/HttpStatusPage');
    AppStorage.delete('currentRouteParams');
  }

  private async checkHttpStatus(): Promise<void> {
    if (!this.inputUrl.trim()) {
      return;
    }
    this.isChecking = true;
    this.errorMsg = '';
    this.hasResult = false;
    try {
      let url = this.inputUrl;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://' + url;
      }
      let httpRequest = http.createHttp();
      let response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      this.statusCode = response.responseCode;
      let headers = response.header as Record<string, string>;
      let headerStr = '';
      let keys = Object.keys(headers);
      for (let i = 0; i < keys.length; i++) {
        let key = keys[i];
        headerStr += key + ': ' + (headers[key] ?? '') + '\n';
      }
      this.responseHeaders = headerStr;
      this.hasResult = true;
      httpRequest.destroy();
    } catch (e) {
      let err = e as BusinessError;
      this.errorMsg = err.message;
    } finally {
      this.isChecking = false;
    }
  }

  build() {
    NavDestination() {
    Column({ space: 0 }) {
      KeyboardLiftScroll({ scroller: this.scroller }) {
        Column({ space: 16 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolPageTitleBar({ title: $r('app.string.sub_title6_value3') })
          Row({ space: 8 }) {
            TextInput({ placeholder: $r('app.string.http_status_url_hint'), text: this.inputUrl })
              .id('kbLiftInput')
              .layoutWeight(1)
              .type(InputType.Normal)
              .onChange((value: string) => { this.inputUrl = value; })
            PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
              .backgroundColor($r('app.color.brand'))
              .height(40)
              .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                if (PasteButtonOnClickResult.SUCCESS === result) {
                  pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                    if (err) {
                      return;
                    }
                    this.inputUrl = pasteData.getPrimaryText();
                  });
                }
              })
          }
          .width('90%')

          Row({ space: 8 }) {
            Button($r('app.string.scancodelink'))
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.brand'))
              .fontColor(Color.White)
              .height(40)
              .onClick(async () => {
                try {
                  let options: scanBarcode.ScanOptions = {
                    scanTypes: [scanCore.ScanType.ALL],
                    enableMultiMode: true,
                    enableAlbum: true
                  };
                  let result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(getContext(this), options);
                  this.inputUrl = result.originalValue;
                } catch (_e) {
                }
              })
            Button($r('app.string.http_status_execute'))
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.brand'))
              .fontColor(Color.White)
              .height(40)
              .enabled(!this.isChecking)
              .onClick(() => { this.checkHttpStatus(); })
          }
          .width('90%')
          .justifyContent(FlexAlign.SpaceBetween)

          if (this.errorMsg) {
            Text(this.errorMsg)
              .fontSize(13)
              .fontColor(Color.Red)
              .width('90%')
              .padding(12)
              .borderRadius(8)
              .backgroundColor('#FFF0F0')
          }

          if (this.hasResult) {
            Column({ space: 12 }) {
              Row() {
                Text($r('app.string.http_status_code'))
                  .fontSize(15)
                  .fontColor($r('app.color.font_secondary'))
                Blank()
                Text(this.statusCode.toString())
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.getStatusColor(this.statusCode))
              }
              .width('100%')

              Text($r('app.string.http_status_headers'))
                .fontSize(14)
                .fontColor($r('app.color.font_secondary'))
                .width('100%')

              Scroll() {
                Text(this.responseHeaders)
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
    .title($r('app.string.sub_title6_value3'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }

  private getStatusColor(code: number): ResourceColor {
    if (code >= 200 && code < 300) {
      return Color.Green;
    }
    if (code >= 300 && code < 400) {
      return 0xffd143;
    }
    return Color.Red;
  }
}
