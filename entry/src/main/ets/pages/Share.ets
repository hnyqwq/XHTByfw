import { promptAction } from '@kit.ArkUI';
import window from '@ohos.window';
import { common } from '@kit.AbilityKit';
import { scanCore, scanBarcode } from '@kit.ScanKit';
// 导入日志模块和错误码模块
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import Logger from '../utils/Logger';
//粘贴组件
import { pasteboard } from '@kit.BasicServicesKit';
//分享相关
import { fileUri } from '@kit.CoreFileKit';
import request from '@ohos.request';
import router from '@ohos.router';
import { image } from '@kit.ImageKit';

//本地
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import MediaFileUri from '../media/MediaFileUri';
import KnockShareGuideCard, { CardRes } from '../model/KnockShareGuideCard';

let logger = Logger.getLogger('[KnockShare]');
let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;

/*
@Extend(Button) function globalButtonStyle() {
  .width('60%')
  .height(80)
  //.background (0x99CCFF)  // 白色背景
  .borderRadius(15)           // 圆角半径
  .margin({ top: 10 })         // 顶部间距
}*/

@Entry
@Component
  // 使用@Entry装饰器标记为入口组件，@Component表示自定义组件
export struct HomePage {
  @State initialOrientation: window.Orientation = window.Orientation.PORTRAIT; // 记录初始方向
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X
  @State isShortcutKeyEnabled: boolean = false
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';
  @State isPlaying: boolean = true;
  @State picture: PixelMap | undefined = undefined;
  //@State networkPreviewUri: string = 'https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250814201313.54764824779401317176433540350951:50001231000000:2800:0987A5ACC48494286FD28FDE9DDACFBCA0C24FD30400A3FE0AD75E2BC2A9EB2D.png'; // 默认网络预览图
  @State sharepng: string = 'https://www.hnyqwq.cn/hvideo/share.png'
  //@State networkPreviewUri: Resource = $r('app.media.homepageback');
  @State savefileUri: string = ' ';
  @State currentFitMode: ImageFit = ImageFit.Auto; // 当前填充模式
  @State isControls: boolean = false; // 控制栏显示状态
  @State handlePopup: boolean = false; // 气泡提示（Popup）
  @State enableShortcutKey: boolean = true; //设置组件支持快捷键响应。
  @State pengtitle: string = ' '; //碰一碰分享标题
  //分享
  @State localShareImageUri: string = ''; // 本地分享图片的URI
  @State isLocalImageSelected: boolean = false; // 是否已选择本地图片
  //碰一碰
  @State whiteStatus: boolean = false;
  //本地
  mediaFileUri: MediaFileUri = new MediaFileUri();
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  // 添加缺失的 imageExtension 状态属性
  @State imageExtension: string = '.png'; // 默认为.png格式

  //背景图片本地
  private async selectImage() {
    let uri = await this.openPhoto();
    if (uri === undefined) {
      hilog.error(0x0000, 'OCRDemo', "Failed to get uri.");
      return;
    }

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // 根据当前图片扩展名设置目标路径
    let targetPath = context.filesDir + '/pengyipeng' + this.imageExtension;

    this.sharepng = targetPath;

    let originFile: fileIo.File | undefined;
    try {
      originFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY); // 打开源URI文件
      fileIo.copyFileSync(originFile.fd, targetPath); // 复制到目标路径
      hilog.info(0x0000, 'localsharepng', 'Copy completed: ' + targetPath);
    } catch (error) {
      hilog.error(0x0000, 'localsharepng', 'Copy failed: ' + JSON.stringify(error));
    } finally {
      fileIo.closeSync(originFile); // 关闭文件句柄
    }
  }

  private openPhoto(): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      }).then((res: photoAccessHelper.PhotoSelectResult) => {
        resolve(res.photoUris[0]);
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'OCRDemo', `Failed to get photo image uri. code：${err.code}，message：${err.message}`);
        reject('');
      })
    })
  }

  //碰一碰分享
  private readonly cardSwiperResources: CardRes[] = [
    {
      text: '对方手机需 HarmonyOS 5 及以上版本。',
      rawfilePrefix: 'knock_share_guide/knock_share_guide_phone_',
      framesCount: 128,
      startDelay: 50,
      stopDelay: 500,
    },
    {
      text: '对方电脑需 HarmonyOS 6 及以上版本。',
      rawfilePrefix: 'knock_share_guide/knock_share_guide_pc_',
      framesCount: 104,
      startDelay: 50,
      stopDelay: 50,
    },
    {
      text: '对方手机需 HarmonyOS 6 及以上版本。',
      rawfilePrefix: 'knock_share_guide/knock_share_guide_pc_pull_',
      framesCount: 150,
      startDelay: 500,
      stopDelay: 1000,
    },
  ];
  private debounceTimer: number = 0

  // 修改 handleImageUpdate 方法
  private handleImageUpdate() {
    clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      this.updateImageExtension(); // 确保在下载前更新扩展名
    }, 1000); // 1秒防抖
  }

  // 添加缺失的 updateImageExtension 方法
  private updateImageExtension() {
    if (this.sharepng.endsWith('.png')) {
      this.imageExtension = '.png';
    } else if (this.sharepng.endsWith('.jpg') || this.sharepng.endsWith('.jpeg')) {
      this.imageExtension = '.jpg';
    } else if (this.sharepng.endsWith('.webp')) {
      this.imageExtension = '.webp';
    } else {
      // 默认使用.png格式
      this.imageExtension = '.png';
    }
  }

  isValidUrl(url: string): boolean {
    const pattern = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$/;
    return pattern.test(url);
  }

  onPageHide(): void { //隔空传送
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.emit('onBackGround');
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text($r('app.string.sharepngon'))
            .textAlign(TextAlign.Center)
            .width('55%')
            .margin({ right: 10 })
          Button($r('app.string.choose'))
            .height(50)
            .width('40%')
            .backgroundColor(0xb87cff)//紫色
            .onClick(() => {
              this.selectImage();
            })
        }
        .width('90%')

        TextArea({ placeholder: $r('app.string.sharepng'), text: this.sharepng })
        //.type(InputType.URL)
        //.backgroundColor('#FF9CCE')
          .width('90%')
          //.height(50)
          .margin({ top: 10, bottom: 10 })
          .onChange((sharepng: string) => {
            this.sharepng = sharepng;
            if (this.isValidUrl(sharepng)) {
              this.handleImageUpdate(); // 触发图片更新逻辑
            }
          })
        Text($r('app.string.texton'))
          .textAlign(TextAlign.Center)
          .margin({ top: 5, bottom: 10 })
        Row() {
          Button($r('app.string.scancode'))
          //.globalButtonStyle()
          //.type(ButtonType.Capsule)
          //.backgroundColor(0x66CCFF)//蓝色
          //.backgroundColor('#0044fc')
            .labelStyle({ overflow: TextOverflow.Ellipsis, maxLines: 3, minFontSize: 0 })
            .width('55%')
            .height(50)
            .margin({ right: 10 })
            .backgroundColor(0xFF66CC)
            .onClick(async () => {
              try {
                // 定义扫码参数options
                let options: scanBarcode.ScanOptions = {
                  scanTypes: [scanCore.ScanType.ALL],
                  enableMultiMode: true,
                  enableAlbum: true
                };
                // 调用扫码功能
                scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
                  // 正确获取扫描结果的字符串值
                  const originalValue: string = result.originalValue; // 假设ScanResult有originalValue属性
                  this.networkVideoSrc = originalValue;
                  promptAction.showToast({ duration: 10000, message: '扫码成功: ' + originalValue });
                }).catch((error: BusinessError) => {
                  hilog.error(0x0001, '[Scan]',
                    `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
                  promptAction.showToast({
                    message: '手动取消或扫码失败（PC/2in1设备暂不支持扫描二维码，请使用其它类型的设备）'
                  });
                });
              } catch (error) {
                //promptAction.showToast({ message: '扫码失败: 读取二维码信息错误； ' + error.message });
                promptAction.showToast({ message: '扫码失败: 启动扫码服务失败' });
                hilog.error(0x0001, '[Scan]',
                  `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
              }
            })
          PasteButton({
            icon: PasteIconStyle.LINES,
            text: PasteDescription.PASTE,
            buttonType: ButtonType.ROUNDED_RECTANGLE
          })
            .backgroundColor(0xFF66CC)
            //.backgroundColor(0x66CCFF)//浅蓝色
            .width('40%')
            .height(50)
            //.padding({top: 12, bottom: 12, left: 24, right: 24})
            .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
              if (PasteButtonOnClickResult.SUCCESS === result) {
                pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                  if (err) {
                    console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                    return;
                  }
                  this.networkVideoSrc = pasteData.getPrimaryText();
                });
              }
            })
        }
        .width('90%')
        .margin({ top: 5, bottom: 10 })

        TextArea({ placeholder: $r('app.string.testinput'), text: this.networkVideoSrc })
        //.type(InputType.URL)
        //.backgroundColor('#FF9CCE')
          .width('90%')
          //.height(50)
          .margin({ right: 10 })
          .onChange((networkVideoSrc: string) => {
            this.networkVideoSrc = networkVideoSrc;
            AppStorage.set('networkVideoSrc', networkVideoSrc);
          })
          .margin({ top: 5, bottom: 10 })
        Row() {
          Text($r('app.string.pengtitleset'))
            .width('40%')
            .textAlign(TextAlign.Center)
            .margin({ right: 10 })
          TextArea({ placeholder: $r('app.string.pengyipeng_title'), text: this.pengtitle })
          //.backgroundColor('#FF9CCE')
            .width('55%')
            .onChange((pengtitle: string) => {
              this.pengtitle = pengtitle;
              AppStorage.set('pengtitle', pengtitle);
            })
            .margin({ top: 10 })
            .width('90%') // 控制内容区域宽度
          Column() {
            Row() {
              Text($r('app.string.nowplaying'))
                .width('55%')
                .textAlign(TextAlign.Center)
                .margin({ right: 10 })
              Button($r('app.string.share'))
              //.type(ButtonType.Capsule)
                .width('40%')
                .height(50)
                .backgroundColor(0x66CCFF) //蓝色
            }
            .width('100%')
            .padding({ bottom: 10 })


            Text(this.networkVideoSrc)
              .padding({
                top: 10,
                bottom: 10,
                left: 10,
                right: 10
              })
              .copyOption(CopyOptions.LocalDevice)
              .textAlign(TextAlign.Center)//.margin({ right: 10 })
              .width('100%')

            //碰一碰提示
            Text($r('app.string.nowplayingon'))
              .padding({ top: 20, left: 24, right: 24 })
              .maxLines(2)
              .fontSize(11)
              .maxFontScale(1.75)
              .width('100%')
              .constraintSize({ minHeight: 16 })
              .fontColor($r('sys.color.font_secondary'))
              .fontFamily('HarmonyHeiTi')
              .textAlign(TextAlign.Center)
            KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResources })
              .padding({ top: 2 })

            /*Text(this.myFileName)
              .focusable(true)
              .focusOnTouch(true)
              .fontFamily('HarmonyHeiTi-Bold')
              .textAlign(TextAlign.Start)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text('Size: ' + JSON.stringify(this.myFileSize) + 'B')
              .focusable(true)
              .focusOnTouch(true)
              .fontFamily('HarmonyHeiTi')
              .textAlign(TextAlign.Start)*/
          }
          .width('90%') // 控制内容区域宽度
          .alignItems(HorizontalAlign.Center) // 内容水平居中
          .margin({ top: 10 })

          //.height('100%')
        }
      }
    }
  }
}