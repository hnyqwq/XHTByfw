import { image } from '@kit.ImageKit';
import { ToolNavTitleBar } from '../../components/ToolNavTitleBar';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { createBrandImmersiveMaterial, createMenuImmersiveMaterial } from '../../common/utils/UIMaterialUtil';
import { GlobalInfoModel } from '../../common/GlobalInfoModel';
import { BRAND_COLOR } from '../../common/BrandColor';

interface ImageInfoResult {
  width: number;
  height: number;
  fileSize: string;
  mimeType: string;
}

interface ImageInfoItem {
  label: ResourceStr;
  value: string;
}

@Component
export struct ImageInfoPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @StorageProp('currentWidthBreakpoint') currentBreakpoint: string = 'sm';
  @State sourcePixelMap: PixelMap | undefined = undefined;
  @State infoResult: ImageInfoResult = {
    width: 0,
    height: 0,
    fileSize: '',
    mimeType: ''
  };
  @State hasInfo: boolean = false;
  private scroller: Scroller = new Scroller();
  private imageSource: image.ImageSource | undefined = undefined;

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/ImageTools/ImageInfoPage');
    AppStorage.delete('currentRouteParams');
  }

  aboutToDisappear() {
    if (this.sourcePixelMap) {
      this.sourcePixelMap.release();
    }
  }

  private async selectImage(): Promise<void> {
    let uri = await this.openPhoto();
    if (uri === undefined || uri === '') {
      return;
    }
    this.loadImage(uri);
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
        console.error('ImageInfo: Failed to get photo uri: ' + err.message);
        reject('');
      });
    });
  }

  private async loadImage(uri: string): Promise<void> {
    try {
      if (this.sourcePixelMap) {
        this.sourcePixelMap.release();
        this.sourcePixelMap = undefined;
      }
      let fileSource = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
      let stat = fileIo.statSync(fileSource.fd);
      this.imageSource = image.createImageSource(fileSource.fd);
      let sourceInfo = await this.imageSource.getImageInfo();
      this.sourcePixelMap = await this.imageSource.createPixelMap();
      let mimeType: string = 'image/*';
      const ext = uri.substring(uri.lastIndexOf('.') + 1).toLowerCase();
      const mimeMap: Record<string, string> = {
        'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
        'webp': 'image/webp', 'gif': 'image/gif', 'bmp': 'image/bmp', 'heic': 'image/heic'
      };
      if (mimeMap[ext]) {
        mimeType = mimeMap[ext];
      }
      this.infoResult = {
        width: sourceInfo.size.width,
        height: sourceInfo.size.height,
        fileSize: this.formatSize(stat.size),
        mimeType: mimeType
      };
      this.hasInfo = true;
      fileIo.closeSync(fileSource);
    } catch (e) {
      let err = e as BusinessError;
      console.error('ImageInfo loadImage error: ' + err.message);
    }
  }

  private formatSize(bytes: number): string {
    if (bytes < 1024) {
      return bytes + ' B';
    }
    if (bytes < 1024 * 1024) {
      return (bytes / 1024).toFixed(1) + ' KB';
    }
    return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
  }


  @Builder

  build() {
    NavDestination() {
    Column({ space: 0 }) {

      Scroll(this.scroller) {
        Column({ space: 16 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolNavTitleBar({ title: $r('app.string.sub_title5_value3') })
            Button($r('app.string.image_select'))
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.brand'))
              .fontColor(Color.White)
              .width('90%')
              .onClick(() => {
                this.selectImage();
              })
              .systemMaterial(createBrandImmersiveMaterial())

          if (this.sourcePixelMap) {
            Image(this.sourcePixelMap)
              .width('90%')
              .height(180)
              .objectFit(ImageFit.Contain)
              .borderRadius(8)
          }

          if (this.hasInfo) {
            Column({ space: 12 }) {
              // 注意:@Builder必须按引用传递(对象字面量),按值传递不会随状态刷新
              this.infoItem({ label: $r('app.string.image_info_width'), value: this.infoResult.width.toString() + ' px' })
              this.infoItem({ label: $r('app.string.image_info_height'), value: this.infoResult.height.toString() + ' px' })
              this.infoItem({ label: $r('app.string.image_info_size'), value: this.infoResult.fileSize })
              this.infoItem({ label: $r('app.string.image_info_format'), value: this.infoResult.mimeType })
              this.infoItem({ label: $r('app.string.image_info_ratio'), value: this.getAspectRatio() })
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
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }

  private getAspectRatio(): string {
    if (this.infoResult.width === 0 || this.infoResult.height === 0) {
      return '-';
    }
    let gcd = this.gcd(this.infoResult.width, this.infoResult.height);
    return (this.infoResult.width / gcd).toString() + ':' + (this.infoResult.height / gcd).toString();
  }

  private gcd(a: number, b: number): number {
    while (b !== 0) {
      let temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  @Builder
  infoItem(item: ImageInfoItem) {
    Row() {
      Text(item.label)
        .fontSize(15)
        .fontColor($r('app.color.font_secondary'))
      Blank()
      Text(item.value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
  }
}
