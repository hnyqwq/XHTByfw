import { http } from '@kit.NetworkKit';
import { ToolPageTitleBar } from '../../components/ToolPageTitleBar';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalInfoModel } from '../../common/GlobalInfoModel';

interface LatencyResult {
  url: string;
  latency: number;
  status: string;
}

@Component
export struct LatencyTestPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State results: LatencyResult[] = [];
  @State isTesting: boolean = false;
  @State currentUrl: string = '';
  private scroller: Scroller = new Scroller();

  private testUrls: string[] = [
    'http://connectivitycheck.platform.hicloud.com',
    'http://www.baidu.com',
    'http://www.qq.com',
    'http://captive.apple.com',
    'http://www.taobao.com',
    'http://www.bilibili.com',
    'http://www.zhihu.com',
    'http://www.douyin.com'
  ];

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/NetTools/LatencyTestPage');
    AppStorage.delete('currentRouteParams');
  }

  private async runTests(): Promise<void> {
    this.isTesting = true;
    this.results = [];
    for (let i = 0; i < this.testUrls.length; i++) {
      let url = this.testUrls[i];
      this.currentUrl = url;
      let startTime = Date.now();
      try {
        let httpRequest = http.createHttp();
        let response = await httpRequest.request(url, {
          method: http.RequestMethod.GET,
          connectTimeout: 5000,
          readTimeout: 5000
        });
        let endTime = Date.now();
        let latency = endTime - startTime;
        this.results = [...this.results, {
          url: url,
          latency: latency,
          status: response.responseCode.toString()
        }];
        httpRequest.destroy();
      } catch (e) {
        let err = e as BusinessError;
        let endTime = Date.now();
        let latency = endTime - startTime;
        this.results = [...this.results, {
          url: url,
          latency: latency,
          status: err.message
        }];
      }
    }
    this.isTesting = false;
    this.currentUrl = '';
  }

  build() {
    NavDestination() {
    Column({ space: 0 }) {
      Scroll(this.scroller) {
        Column({ space: 16 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolPageTitleBar({ title: $r('app.string.sub_title6_value2') })
          Button($r('app.string.latency_test_execute'))
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.brand'))
            .fontColor(Color.White)
            .width('90%')
            .enabled(!this.isTesting)
            .onClick(() => { this.runTests(); })

          if (this.isTesting) {
            Row() {
               LoadingProgress()
                 .width(20)
                 .height(20)
                 .color($r('app.color.brand'))
               Text($r('app.string.latency_test_testing'))
                 .fontSize(13)
                 .fontColor($r('app.color.font_secondary'))
                 .margin({ left: 8 })
               Text(' ' + this.currentUrl)
                 .fontSize(13)
                 .fontColor($r('app.color.font_secondary'))
             }
             .width('90%')
          }

          if (this.results.length > 0) {
            Column({ space: 8 }) {
              ForEach(this.results, (item: LatencyResult, index: number) => {
                Row() {
                  Column() {
                    Text(item.url)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.status)
                      .fontSize(11)
                      .fontColor($r('app.color.font_secondary'))
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Blank()
                  Text(item.latency.toString() + 'ms')
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.getLatencyColor(item.latency))
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
              }, (item: LatencyResult, index: number) => index.toString() + item.url)
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
      .width('100%')
      .layoutWeight(1)
    }
    .height('100%')
    }
    .title($r('app.string.sub_title6_value2'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }

  private getLatencyColor(ms: number): ResourceColor {
    if (ms < 200) {
      return Color.Green;
    }
    if (ms < 500) {
      return 0xffd143;
    }
    return Color.Red;
  }
}
