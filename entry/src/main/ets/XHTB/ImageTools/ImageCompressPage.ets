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
export struct ImageCompressPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @StorageProp('currentWidthBreakpoint') currentBreakpoint: string = 'sm';
  @State sourcePixelMap: PixelMap | undefined = undefined;
  @State compressedPixelMap: PixelMap | undefined = undefined;
  @State quality: number = 50;
  @State originalSize: string = '';
  @State compressedSize: string = '';
  @State sourceUri: string = '';
  @State isSaving: boolean = false;
  private scroller: Scroller = new Scroller();
  private imageSource: image.ImageSource | undefined = undefined;

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/ImageTools/ImageCompressPage');
    AppStorage.delete('currentRouteParams');
  }

  aboutToDisappear() {
    if (this.sourcePixelMap) {
      this.sourcePixelMap.release();
    }
    if (this.compressedPixelMap) {
      this.compressedPixelMap.release();
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
        console.error('ImageCompress: Failed to get photo uri: ' + err.message);
        reject('');
      });
    });
  }

  private async loadImage(uri: string): Promise<void> {
    try {
      this.sourceUri = uri;
      if (this.sourcePixelMap) {
        this.sourcePixelMap.release();
        this.sourcePixelMap = undefined;
      }
      let fileSource = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
      let stat = fileIo.statSync(fileSource.fd);
      this.originalSize = this.formatSize(stat.size);
      this.imageSource = image.createImageSource(fileSource.fd);
      this.sourcePixelMap = await this.imageSource.createPixelMap();
      this.compressedPixelMap = undefined;
      this.compressedSize = '';
      fileIo.closeSync(fileSource);
    } catch (e) {
      let err = e as BusinessError;
      console.error('ImageCompress loadImage error: ' + err.message);
    }
  }

  private async compressImage(): Promise<void> {
    if (!this.sourcePixelMap) {
      return;
    }
    try {
      let ctx = getContext(this) as common.UIAbilityContext;
      let imagePacker = image.createImagePacker();
      let packOptions: image.PackingOption = {
        format: 'image/jpeg',
        quality: this.quality
      };
      let buffer = await imagePacker.packToData(this.sourcePixelMap, packOptions);
      this.compressedSize = this.formatSize(buffer.byteLength);
      let targetPath = ctx.filesDir + '/compressed_' + Date.now() + '.jpg';
      let file = fileIo.openSync(targetPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(file.fd, buffer);
      fileIo.closeSync(file);
      let newSource = image.createImageSource(targetPath);
      if (this.compressedPixelMap) {
        this.compressedPixelMap.release();
      }
      this.compressedPixelMap = await newSource.createPixelMap();
    } catch (e) {
      let err = e as BusinessError;
      console.error('ImageCompress compressImage error: ' + err.message);
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
    if (!this.compressedPixelMap || this.isSaving) {
      return;
    }
    this.isSaving = true;
    let imagePacker: image.ImagePacker | undefined = undefined;
    let saveFile: fileIo.File | undefined = undefined;
    try {
      let helper = photoAccessHelper.getPhotoAccessHelper(getContext(this));
      let uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
      saveFile = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      imagePacker = image.createImagePacker();
      let packOpts: image.PackingOption = { format: 'image/jpeg', quality: this.quality };
      const packedData: ArrayBuffer = await imagePacker.packToData(this.compressedPixelMap, packOpts);
      fileIo.writeSync(saveFile.fd, packedData);
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.saved_to_album') });
    } catch (e) {
      let err = e as BusinessError;
      console.error('ImageCompress save error: ' + err.code + ', ' + err.message);
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
          ToolNavTitleBar({ title: $r('app.string.sub_title5_value1') })
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
              .height(200)
              .objectFit(ImageFit.Contain)
              .borderRadius(8)
            Text(getContext(this).resourceManager.getStringSync($r('app.string.image_original_size')) + ': ' + this.originalSize)
              .fontSize(14)
              .fontColor($r('app.color.font_secondary'))

            Row() {
              Text(getContext(this).resourceManager.getStringSync($r('app.string.image_compress_quality')) + ': ' + this.quality + '%')
                .fontSize(14)
              Slider({
                value: this.quality,
                min: 1,
                max: 100,
                step: 5,
                style: SliderStyle.InSet
              })
                .width('60%')
                .onChange((value: number) => { this.quality = value; })
            }
            .width('90%')
            .justifyContent(FlexAlign.SpaceBetween)

            Button($r('app.string.image_compress_execute'))
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.brand'))
              .fontColor(Color.White)
              .width('90%')
              .onClick(() => { this.compressImage(); })
          }

          if (this.compressedPixelMap) {
            Image(this.compressedPixelMap)
              .width('90%')
              .height(200)
              .objectFit(ImageFit.Contain)
              .borderRadius(8)
            Text(getContext(this).resourceManager.getStringSync($r('app.string.image_compressed_size')) + ': ' + this.compressedSize)
              .fontSize(14)
              .fontColor($r('app.color.font_secondary'))

            SaveButton({
              icon: SaveIconStyle.FULL_FILLED,
              text: SaveDescription.DOWNLOAD,
              buttonType: ButtonType.Capsule
            })
              .onClick((event: ClickEvent, result: SaveButtonOnClickResult) => {
                if (result === SaveButtonOnClickResult.SUCCESS) {
                  this.saveResultToGallery();
                }
              })
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
}
