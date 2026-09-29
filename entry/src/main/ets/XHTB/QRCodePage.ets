import { image } from '@kit.ImageKit';
import { ToolNavTitleBar } from '../components/ToolNavTitleBar';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { GlobalInfoModel } from '../common/GlobalInfoModel';
import { createBrandImmersiveMaterial } from '../common/utils/UIMaterialUtil';
import { KeyboardLiftScroll } from '../common/utils/KeyboardLiftScroll';

@Component
export struct QRCodePage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State pixelMap: image.PixelMap | undefined = undefined
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    // 保存当前页面信息到 AppStorage,供接续功能使用
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/QRCodePage');
    AppStorage.delete('currentRouteParams');
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
      KeyboardLiftScroll({ scroller: this.scroller }) {
        Column({ space: 20 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolNavTitleBar({ title: $r('app.string.sub_title2_value2') })
          TextArea({ placeholder: $r('app.string.qrcode'), text: this.networkVideoSrc })
            .id('kbLiftInput')
            .margin({
              left: $r('sys.float.padding_level16'),
              right: $r('sys.float.padding_level16'),
            })
            .onChange((networkVideoSrc: string) => {
              this.networkVideoSrc = networkVideoSrc;
              AppStorage.set('networkVideoSrc', networkVideoSrc);
            })

          Button($r('app.string.createqrcode'))
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.brand'))
            .fontColor(Color.White)
            .width('90%')
            .margin({ top: 10 })
            .onClick(() => {
              this.pixelMap = undefined;
              let content: string = this.networkVideoSrc;
              let options: generateBarcode.CreateOptions = {
                scanType: scanCore.ScanType.QR_CODE,
                height: 200,
                width: 200
              }
              try {
                generateBarcode.createBarcode(content, options).then((pixelMap: image.PixelMap) => {
                  this.pixelMap = pixelMap;
                  // 码图生成接口，成功返回PixelMap格式图片
                  hilog.info(0x0001, '[Scan Sample]', `Succeeded in getting PixelMap by promise with options`);
                }).catch((error: BusinessError) => {
                  hilog.error(0x0001, '[Scan Sample]',
                    `Failed to get PixelMap by promise with options. Code: ${error.code}, message: ${error.message}`);
                });
              } catch (error) {
                hilog.error(0x0001, '[Scan Sample]', `Failed to generateBarcode. Code: ${error.code}, message: ${error.message}`);
              }
            })
            .systemMaterial(createBrandImmersiveMaterial())

          // 获取生成码后显示
          if (this.pixelMap) {
            Image(this.pixelMap).width(300).height(300).objectFit(ImageFit.Contain)
              .margin({ top: 10 })
          }
        }
        .width('100%')
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