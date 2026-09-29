import { image } from '@kit.ImageKit';
import { ToolNavTitleBar } from '../../components/ToolNavTitleBar';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { createBrandImmersiveMaterial, createMenuImmersiveMaterial } from '../../common/utils/UIMaterialUtil';
import { GlobalInfoModel } from '../../common/GlobalInfoModel';
import { BRAND_COLOR } from '../../common/BrandColor';

@Component
export struct ImageConvertPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @StorageProp('currentWidthBreakpoint') currentBreakpoint: string = 'sm';
  @State sourcePixelMap: PixelMap | undefined = undefined;
  @State convertedPixelMap: PixelMap | undefined = undefined;
  @State targetFormat: string = 'jpeg';
  @State sourceFormat: string = '';
  @State sourceUri: string = '';
  @State convertedSize: string = '';
  @State isSaving: boolean = false;
  private scroller: Scroller = new Scroller();
  private imageSource: image.ImageSource | undefined = undefined;

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/ImageTools/ImageConvertPage');
    AppStorage.delete('currentRouteParams');
  }

  aboutToDisappear() {
    if (this.sourcePixelMap) {
      this.sourcePixelMap.release();
    }
    if (this.convertedPixelMap) {
      this.convertedPixelMap.release();
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
        console.error('ImageConvert: Failed to get photo uri: ' + err.message);
        reject('');
      });
    });
  }

  private async loadImage(uri: string): Promise<void> {
    try {
      this.sourceUri = uri;
      if (uri.endsWith('.png')) {
        this.sourceFormat = 'PNG';
      } else if (uri.endsWith('.jpg') || uri.endsWith('.jpeg')) {
        this.sourceFormat = 'JPEG';
      } else if (uri.endsWith('.webp')) {
        this.sourceFormat = 'WEBP';
      } else {
        this.sourceFormat = 'Unknown';
      }
      if (this.sourcePixelMap) {
        this.sourcePixelMap.release();
        this.sourcePixelMap = undefined;
      }
      let fileSource = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
      this.imageSource = image.createImageSource(fileSource.fd);
      this.sourcePixelMap = await this.imageSource.createPixelMap();
      this.convertedPixelMap = undefined;
      this.convertedSize = '';
      fileIo.closeSync(fileSource);
    } catch (e) {
      let err = e as BusinessError;
      console.error('ImageConvert loadImage error: ' + err.message);
    }
  }

  private async convertImage(): Promise<void> {
    if (!this.sourcePixelMap) {
      return;
    }
    try {
      let ctx = getContext(this) as common.UIAbilityContext;
      let imagePacker = image.createImagePacker();
      let formatStr = 'image/' + this.targetFormat;
      let packOptions: image.PackingOption = {
        format: formatStr,
        quality: 90
      };
      let buffer = await imagePacker.packToData(this.sourcePixelMap, packOptions);
      let ext = this.targetFormat === 'jpeg' ? '.jpg' : '.' + this.targetFormat;
      let targetPath = ctx.filesDir + '/converted_' + Date.now() + ext;
      let file = fileIo.openSync(targetPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(file.fd, buffer);
      fileIo.closeSync(file);
      this.convertedSize = this.formatSize(buffer.byteLength);
      let newSource = image.createImageSource(targetPath);
      if (this.convertedPixelMap) {
        this.convertedPixelMap.release();
      }
      this.convertedPixelMap = await newSource.createPixelMap();
    } catch (e) {
      let err = e as BusinessError;
      console.error('ImageConvert convertImage error: ' + err.message);
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

  private async saveResultToGallery(): Promise<void> {
    if (!this.convertedPixelMap || this.isSaving) {
      return;
    }
    this.isSaving = true;
    let imagePacker: image.ImagePacker | undefined = undefined;
    let saveFile: fileIo.File | undefined = undefined;
    try {
      let helper = photoAccessHelper.getPhotoAccessHelper(getContext(this));
      let ext = this.targetFormat === 'jpeg' ? 'jpg' : this.targetFormat;
      let uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, ext);
      saveFile = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      imagePacker = image.createImagePacker();
      let packOpts: image.PackingOption = { format: 'image/' + this.targetFormat, quality: 90 };
      const packedData: ArrayBuffer = await imagePacker.packToData(this.convertedPixelMap, packOpts);
      fileIo.writeSync(saveFile.fd, packedData);
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.saved_to_album') });
    } catch (e) {
      let err = e as BusinessError;
      console.error('ImageConvert save error: ' + err.code + ', ' + err.message);
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.save_failed') });
    } finally {
      if (saveFile) {
        fileIo.closeSync(saveFile);
      }
      if (imagePacker) {
      }
      this.isSaving = false;
    }
  }


  @Builder

  build() {
    NavDestination() {
    Column({ space: 0 }) {

      Scroll(this.scroller) {
        Column({ space: 16 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolNavTitleBar({ title: $r('app.string.sub_title5_value2') })
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
            Text(getContext(this).resourceManager.getStringSync($r('app.string.image_convert_source_format')) + ': ' + this.sourceFormat)
              .fontSize(14)
              .fontColor($r('app.color.font_secondary'))

            Text($r('app.string.image_convert_target_format'))
              .fontSize(14)
              .margin({ top: 8 })

            Row({ space: 12 }) {
              Button('JPEG')
                .type(ButtonType.Capsule)
                .backgroundColor(this.targetFormat === 'jpeg' ? $r('app.color.brand') : Color.Gray)
                .fontColor(Color.White)
                .onClick(() => { this.targetFormat = 'jpeg'; })
              Button('PNG')
                .type(ButtonType.Capsule)
                .backgroundColor(this.targetFormat === 'png' ? $r('app.color.brand') : Color.Gray)
                .fontColor(Color.White)
                .onClick(() => { this.targetFormat = 'png'; })
              Button('WEBP')
                .type(ButtonType.Capsule)
                .backgroundColor(this.targetFormat === 'webp' ? $r('app.color.brand') : Color.Gray)
                .fontColor(Color.White)
                .onClick(() => { this.targetFormat = 'webp'; })
            }

            Button($r('app.string.image_convert_execute'))
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.brand'))
              .fontColor(Color.White)
              .width('90%')
              .margin({ top: 8 })
              .onClick(() => { this.convertImage(); })
          }

          if (this.convertedPixelMap) {
            Image(this.convertedPixelMap)
              .width('90%')
              .height(180)
              .objectFit(ImageFit.Contain)
              .borderRadius(8)
            Text(getContext(this).resourceManager.getStringSync($r('app.string.image_convert_result')) + ': ' + this.targetFormat.toUpperCase() + ' (' + this.convertedSize + ')')
              .fontSize(14)
              .fontColor($r('app.color.font_secondary'))

            SaveButton({
              icon: SaveIconStyle.FULL_FILLED,
              text: SaveDescription.DOWNLOAD,
              buttonType: ButtonType.Capsule
            })
              // 加宽与其他按钮一致,避免过窄不明显
              .width('90%')
              .onClick((event: ClickEvent, result: SaveButtonOnClickResult) => {
                if (result === SaveButtonOnClickResult.SUCCESS) {
                  this.saveResultToGallery();
                }
              })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        // 内容至少撑满一屏,超出即可滚动(对齐 KeyboardLiftScroll 结构,修复部分机型不可滑动)
        .constraintSize({ minHeight: '100%' })
        .padding({ bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      // 任意状态下都可拖动,内容超长时正常滚动
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .scrollBar(BarState.Off)
    }
    .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }
}
