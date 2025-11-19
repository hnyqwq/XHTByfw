import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { scanCore, generateBarcode } from '@kit.ScanKit';
import Logger from '../utils/Logger';

import { fileIo } from '@kit.CoreFileKit';
import MediaFileUri from '../media/MediaFileUri';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

@Entry
@Component
export struct HomePage {
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';
  @State pixelMap: image.PixelMap | undefined = undefined
  @State createCount: number = 0;
  @State result: boolean = false;
  @State utteranceId: string = '123456'
  @State illegalText: string = '';
  @State sharepng: string = '.png'
  @StorageLink('isPlaying') isPlaying: boolean = false;

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

  build() {
    Column({ space: 0 }) {
      Row() {
        Text($r('app.string.sharepngon'))
          .textAlign(TextAlign.Center)
          .width('50%')
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
        //.width('90%')
        //.height(50)
        .margin({ top: 10, bottom: 10,
          left: $r('sys.float.padding_level16'),
          right: $r('sys.float.padding_level16'), })
        .onChange((sharepng: string) => {
          this.sharepng = sharepng;
          if (this.isValidUrl(sharepng)) {
            this.handleImageUpdate(); // 触发图片更新逻辑
          }
        })
      Text($r('app.string.texton'))
        .textAlign(TextAlign.Center)
        .width('55%')
        .margin({
          top: 50, right: 10 })
        //二维码生成
        TextArea({ placeholder: $r('app.string.qrcode'), text: this.networkVideoSrc })
          .margin({
            top: 10,
            left: $r('sys.float.padding_level16'),
            right: $r('sys.float.padding_level16'),
          })
          .onChange((networkVideoSrc: string) => {
            this.networkVideoSrc = networkVideoSrc;
            AppStorage.set('networkVideoSrc', networkVideoSrc);
          })

        Button($r('app.string.pick'))
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
        // 获取生成码后显示
        if (this.pixelMap) {
          Image(this.pixelMap).width(300).height(300).objectFit(ImageFit.Contain)
            .margin({ top: 10 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)
    }
}