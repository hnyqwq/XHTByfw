import { http } from '@kit.NetworkKit';
import { ToolPageTitleBar } from '../../components/ToolPageTitleBar';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalInfoModel } from '../../common/GlobalInfoModel';

interface IPInfo {
  ip: string;
  city: string;
  region: string;
  country: string;
  isp: string;
}

interface IPInfoItem {
  label: ResourceStr;
  value: string;
}

@Component
export struct IPQueryPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State ipInfo: IPInfo = {
    ip: '',
    city: '',
    region: '',
    country: '',
    isp: ''
  };
  @State isQuerying: boolean = false;
  @State errorMsg: string = '';
  @State rawResponse: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/NetTools/IPQueryPage');
    AppStorage.delete('currentRouteParams');
  }

  private async queryIP(): Promise<void> {
    this.isQuerying = true;
    this.errorMsg = '';
    try {
      let httpRequest = http.createHttp();
      let response = await httpRequest.request('http://ip-api.com/json/?lang=zh-CN', {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 10000,
        readTimeout: 10000
      });
      this.rawResponse = response.result as string;
      if (response.responseCode === 200) {
        let parsed: Record<string, string> = JSON.parse(response.result as string) as Record<string, string>;
        this.ipInfo = {
          ip: parsed['query'] ?? '',
          city: parsed['city'] ?? '',
          region: parsed['regionName'] ?? '',
          country: parsed['country'] ?? '',
          isp: parsed['isp'] ?? ''
        };
      } else {
        this.errorMsg = 'HTTP ' + response.responseCode.toString();
      }
      httpRequest.destroy();
    } catch (e) {
      let err = e as BusinessError;
      this.errorMsg = err.message;
    } finally {
      this.isQuerying = false;
    }
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
      Scroll(this.scroller) {
        Column({ space: 16 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolPageTitleBar({ title: $r('app.string.sub_title6_value1') })
          Button() {
            Row({ space: 8 }) {
              if (this.isQuerying) {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color(Color.White)
              }
              Text(this.isQuerying ? $r('app.string.ip_querying') : $r('app.string.ip_query_execute'))
                .fontColor(Color.White)
                .fontSize(16)
            }
          }
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.brand'))
            .width('90%')
            .enabled(!this.isQuerying)
            .onClick(() => { this.queryIP(); })

          if (this.errorMsg) {
            Text(this.errorMsg)
              .fontSize(13)
              .fontColor(Color.Red)
              .width('90%')
              .padding(12)
              .borderRadius(8)
              .backgroundColor('#FFF0F0')
          }

          if (this.ipInfo.ip) {
            Column({ space: 12 }) {
              // 注意:@Builder必须按引用传递(对象字面量),按值传递不会随状态刷新
              this.infoItem({ label: $r('app.string.ip_query_address'), value: this.ipInfo.ip })
              this.infoItem({ label: $r('app.string.ip_query_country'), value: this.ipInfo.country })
              this.infoItem({ label: $r('app.string.ip_query_region'), value: this.ipInfo.region })
              this.infoItem({ label: $r('app.string.ip_query_city'), value: this.ipInfo.city })
              this.infoItem({ label: $r('app.string.ip_query_isp'), value: this.ipInfo.isp })
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
    .title($r('app.string.sub_title6_value1'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }

  @Builder
  infoItem(item: IPInfoItem) {
    Row() {
      Text(item.label)
        .fontSize(15)
        .fontColor($r('app.color.font_secondary'))
      Blank()
      Text(item.value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .copyOption(CopyOptions.LocalDevice)
    }
    .width('100%')
  }
}
