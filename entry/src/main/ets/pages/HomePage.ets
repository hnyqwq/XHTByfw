import { promptAction, PromptAction } from '@kit.ArkUI';
import window from '@ohos.window';
import { common } from '@kit.AbilityKit';
import { scanCore, scanBarcode } from '@kit.ScanKit';
// 导入日志模块和错误码模块
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { effectKit } from '@kit.ArkGraphics2D';
import { fileIo as fs } from '@kit.CoreFileKit';
import Logger from '../utils/Logger';
//粘贴组件
import { pasteboard } from '@kit.BasicServicesKit';
//分享相关
import { fileUri } from '@kit.CoreFileKit';
import request from '@ohos.request';
import { navigationManager } from '../common/NavigationManager';
import { image } from '@kit.ImageKit';
import { CommonConstants } from '../constants/CommonConstants';

//本地
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { picker } from '@kit.CoreFileKit';
import MediaFileUri from '../media/MediaFileUri';
import { GlobalInfoModel } from '../common/GlobalInfoModel';
import { DeviceSegmentButton } from '../components/DeviceSegmentButton';

let logger = Logger.getLogger('[HomePage]');
let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;

// 将路径转为文件URI（如 file://bundleName/path），已含 file:// 前缀的直接返回
function toFileUri(path: string): string {
  if (path.startsWith('file://')) {
    return path;
  }
  return fileUri.getUriFromPath(path);
}

@Entry
@Component
  // 使用@Entry装饰器标记为入口组件，@Component表示自定义组件
export struct HomePage {
  private promptActionObj: PromptAction = this.getUIContext().getPromptAction();
  @State initialOrientation: window.Orientation = window.Orientation.PORTRAIT; // 记录初始方向
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X
  @State isShortcutKeyEnabled: boolean = false
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';
  @State isPlaying: boolean = true;
  @State picture: PixelMap | undefined = undefined;
  @State localPixelMap: PixelMap | undefined = undefined; // 本地图片的PixelMap
  //@State networkPreviewUri: string = ''; // 默认网络预览图
  @StorageLink('sharepng') sharepng: string = 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharelink.png?token=01db909c-fd6a-4dcc-8c57-4538e4689629' // 背景图片(预览卡片显示)
  @State backgroundImagePath: string = 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharelink.png?token=01db909c-fd6a-4dcc-8c57-4538e4689629' // 背景图片路径(独立)
  @State backgroundPixelMap: PixelMap | undefined = undefined; // 背景图片的PixelMap(独立)
  @State backgroundImageKey: string = ''; // 背景图片key(独立)
  @State useCustomBackground: boolean = false; // 标记是否用户手动设置了自定义背景图片
  //@State networkPreviewUri: Resource = $r('app.media.homepageback');
  @State savefileUri: string = ' ';
  @State currentFitMode: ImageFit = ImageFit.Auto; // 当前填充模式
  @State isControls: boolean = false; // 控制栏显示状态
  @State handlePopup: boolean = false; // 气泡提示（Popup）
  @State enableShortcutKey: boolean = true; //设置组件支持快捷键响应。
  @StorageLink('pengtitle') pengtitle: string = ' '
  //分享
  @State localShareImageUri: string = ''; // 本地分享图片的URI
  @State isLocalImageSelected: boolean = false; // 是否已选择本地图片

  // 添加一个状态来存储图片的宽高比
  @State imageAspectRatio: number = 1; // 默认为1:1
  @State isImageLoaded: boolean = false; // 图片是否已加载
  @State imageKey: string = ''; // 图片key用于强制刷新

  // 调试数据状态
  @State debugImagePath: string = '';
  @State debugImageExtension: string = '';
  @State debugSharepng: string = '';
  @State debugFilesDir: string = '';
  @State debugFilesList: string = '';
  @State debugFileExists: boolean = false;
  @State debugFileStat: string = '';
  @State debugFileError: string = '';

  // 顶部胶囊按钮
  @State selectedShareMode: number = 0; // 0: 碰一碰, 1: 隔空传输
  @State currentDescription: Resource = $r('app.string.pengyipeng_description'); // 当前显示的描述

  // 分享类型选择
  @State shareTypeIndex: number = 0; // 0: 链接, 1: 文本, 2: 图片, 3: 视频, 4: 文件

  // 各类型分享内容
  @State shareLinkContent: string = ''; // 链接内容
  @State shareTextContent: string = ''; // 文本内容
  @State shareImagePath: string = ''; // 图片路径（单个）
  @State shareImagePaths: string[] = []; // 图片路径数组（多个）
  @StorageLink('shareVideoPath') shareVideoPath: string = ''; // 视频路径（单个）- 使用StorageLink以响应AppStorage更新
  @State shareVideoPaths: string[] = []; // 视频路径数组（多个）
  @State shareFilePaths: string[] = []; // 文件路径数组（多个）
  @State shareFilePath: string = ''; // 文件路径（单个）

  // 主颜色获取相关
  @State mainColor: string = '#F5E5D8'; // 获取的主颜色，用于文字背景，默认为#F5E5D8

  // 顶部背景渐变相关
  @State topBgColor: string = '#FFFFFF'; // 顶部背景颜色
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  @State topSafeHeight: number = 0; // 顶部安全区域高度（已废弃，保留兼容性）

  // 新年卡片相关

  // 沉浸式Tab相关
  @StorageLink('isImmersiveTab') isImmersiveTab: boolean = false; // 沉浸式Tab栏设置，从AppStorage读取

  // 手机多设备选择相关

  // 默认背景图片URL列表（五张默认图）
  private readonly defaultBackgroundUrls: string[] = [
    'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharelink.png?token=01db909c-fd6a-4dcc-8c57-4538e4689629',
    'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharetext.png?token=0ff083d9-0f48-4848-b090-b3ecab82e5dd',
    'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharepic.png?token=86d11f71-7f41-4ba8-9e2a-f2adda0e6974',
    'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharevideo.png?token=b0fb7863-52d0-471d-b228-c8d565e0b07c',
    'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharefiles.png?token=607f6397-d9bf-40b2-8454-5227510d8c68'
  ];

  // 断点相关
  @StorageProp('currentWidthBreakpoint') currentBreakpoint: string = 'md';

  // 监听断点变化，动态调整默认分享模式
  @Watch('onBreakpointChange')
  @StorageProp('currentWidthBreakpoint') currentBreakpointWatcher: string = 'md';

  // 用于响应式更新的断点状态
  @State currentBreakpointForUI: string = 'md';

  // 断点变化回调
  onBreakpointChange() {
    // 同步断点到状态变量以触发UI更新
    this.currentBreakpointForUI = this.currentBreakpoint;
    console.info(`HomePage onBreakpointChange: currentBreakpoint=${this.currentBreakpoint}, currentBreakpointForUI=${this.currentBreakpointForUI}`);

    // 如果是平板设备（屏幕宽度>=840vp）且当前是碰一碰模式，自动切换到隔空投送模式
    if (this.useSplitLayoutByWidth && this.selectedShareMode === 0) {
      this.selectedShareMode = 1;
      this.currentDescription = $r('app.string.gekong_description');
      console.log('检测到大屏设备，自动切换到隔空投送模式');
    }
    // 同时更新分栏布局状态
    this.updateSplitLayoutByWidth();
  }

  // 使用屏幕宽度判断分栏布局（>=840vp时使用分栏布局）
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State useSplitLayoutByWidth: boolean = false;

  // 监听GlobalInfoModel变化,动态更新分栏布局状态
  @Watch('onGlobalInfoModelChange')
  @StorageProp('GlobalInfoModel') globalInfoModelWatcher: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;

  // GlobalInfoModel变化回调
  onGlobalInfoModelChange() {
    this.updateSplitLayoutByWidth();
  }

  // 根据屏幕宽度更新分栏布局状态
  updateSplitLayoutByWidth() {
    if (this.globalInfoModel && this.globalInfoModel.deviceWidth >= 840) {
      this.useSplitLayoutByWidth = true;
    } else {
      this.useSplitLayoutByWidth = false;
    }
    console.info(`HomePage: deviceWidth=${this.globalInfoModel?.deviceWidth}, useSplitLayoutByWidth=${this.useSplitLayoutByWidth}`);
  }

  //本地
  mediaFileUri: MediaFileUri = new MediaFileUri();
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  // 添加缺失的 imageExtension 状态属性
  @State imageExtension: string = '.png'; // 默认为.png格式

  // 安全 showToast：使用 UIContext 绑定的 PromptAction 实例调用，页面销毁时静默忽略
  private safeShowToast(options: promptAction.ShowToastOptions): void {
    try {
      this.promptActionObj.showToast(options);
    } catch (e) {
      const err = e as BusinessError;
      if (err.code !== 100001) {
        throw new Error(`showToast failed: code=${err.code}, message=${err.message}`);
      }
    }
  }

  //背景图片本地
  private async selectImage() {
    let uri: string | undefined = undefined;
    try {
      uri = await this.openPhoto();
    } catch (e) {
      hilog.error(0x0000, 'OCRDemo', "selectImage: openPhoto rejected");
      return;
    }

    if (uri === undefined) {
      hilog.error(0x0000, 'OCRDemo', "Failed to get uri.");
      return;
    }

    console.log('=== selectImage 开始 ===');
    console.log('选择的图片 URI: ' + uri);

    // 根据选中的图片URI更新扩展名
    if (uri.endsWith('.png')) {
      this.imageExtension = '.png';
    } else if (uri.endsWith('.jpg') || uri.endsWith('.jpeg')) {
      this.imageExtension = '.jpg';
    } else if (uri.endsWith('.webp')) {
      this.imageExtension = '.webp';
    } else {
      // 默认使用.png格式
      this.imageExtension = '.png';
    }

    console.log('更新后的 imageExtension: ' + this.imageExtension);

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    console.log('selectImage 中的 context.filesDir: ' + context.filesDir);
    console.log('全局 filesDir: ' + filesDir);
    console.log('两者是否相同: ' + (context.filesDir === filesDir));

    // 根据当前图片扩展名设置目标路径
    let targetPath = context.filesDir + '/pengyipeng' + this.imageExtension;
    console.log('目标完整路径 targetPath: ' + targetPath);

    // 使用文件描述符方式复制文件（适配图库URI）
    try {
      // 打开源文件（图库URI）
      let sourceFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      // 创建目标文件
      let targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);

      // 读取并写入文件
      let bufferSize = 1024 * 1024; // 1MB 缓冲区
      let buffer = new ArrayBuffer(bufferSize);
      let readLen: number = 0;

      while ((readLen = fileIo.readSync(sourceFile.fd, buffer)) > 0) {
        fileIo.writeSync(targetFile.fd, buffer, { length: readLen });
      }

      // 关闭文件
      fileIo.closeSync(sourceFile);
      fileIo.closeSync(targetFile);

      hilog.info(0x0000, 'localsharepng' , 'Copy completed: ' + targetPath);

      // 等待文件系统同步
      await new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 100);
      });

      // 验证文件是否真的存在
      const stat = fileIo.statSync(targetPath);
      hilog.info(0x0000, 'localsharepng' , 'File verified, size: ' + stat.size);

      // 释放之前的背景PixelMap
      if (this.backgroundPixelMap) {
        this.backgroundPixelMap.release();
        this.backgroundPixelMap = undefined;
      }

      // 加载为 PixelMap,只更新背景图片,不更新分享图片
      let imageSource: image.ImageSource | undefined = undefined;
      try {
        imageSource = image.createImageSource(targetPath);
        this.backgroundPixelMap = await imageSource.createPixelMap();
        hilog.info(0x0000, 'localsharepng' , 'PixelMap created for background image');
      } finally {
      }

      // 只更新背景图片路径,不影响分享图片(sharepng)
      this.backgroundImagePath = 'file://' + targetPath;
      hilog.info(0x0000, 'localsharepng' , 'Background image path updated (sharepng unchanged)');
    } catch (error) {
      hilog.error(0x0000, 'localsharepng' , 'Copy failed: ' + JSON.stringify(error));
      return;
    }

    // 强制刷新背景图片显示
    this.backgroundImageKey = Date.now().toString();

    // 重新获取图片宽高比
    await this.getImageAspectRatio();

    // 如果是横屏+隔空模式，获取主颜色
    if (this.imageAspectRatio >= 1 && this.selectedShareMode === 1) {
      await this.extractMainColor();
    }

    console.log('=== selectImage 结束 ===');
  }

  // 从URI中提取原始文件名(去查询参数、URL解码),取不到时用fallback命名
  private extractFileNameFromUri(uri: string, fallback: string): string {
    let path = uri.split('?')[0].split('#')[0];
    let name = path.substring(path.lastIndexOf('/') + 1);
    try {
      name = decodeURIComponent(name);
    } catch (e) {
      // URL编码非法时直接使用原始段
    }
    name = name.replace(/\//g, '_').trim();
    return name || fallback;
  }

  // 在目录内生成不冲突的目标路径:优先保持原文件名,同名时追加序号避免覆盖
  private uniqueSandboxPath(dir: string, fileName: string): string {
    try {
      fs.mkdirSync(dir, true);
    } catch (e) {
      // 目录已存在,忽略
    }
    let targetPath = dir + '/' + fileName;
    if (!fs.accessSync(targetPath)) {
      return targetPath;
    }
    let dotIndex = fileName.lastIndexOf('.');
    let base = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    let ext = dotIndex > 0 ? fileName.substring(dotIndex) : '';
    let seq = 1;
    while (fs.accessSync(dir + '/' + base + '_' + seq + ext)) {
      seq++;
    }
    return dir + '/' + base + '_' + seq + ext;
  }

  // 选择分享图片(不影响背景图片)
  private async selectShareImage() {
    // 添加模式:openPhoto会用新选择覆盖shareImagePaths,先保留已有的沙箱路径
    const previousImagePaths = this.shareImagePaths.slice();
    let uri: string | undefined = undefined;
    try {
      uri = await this.openPhoto();
    } catch (e) {
      hilog.error(0x0000, 'OCRDemo', "openPhoto rejected: " + JSON.stringify(e));
      this.safeShowToast({ message: $r('app.string.image_select_cancel_or_failed') });
      return;
    }

    if (uri === undefined || this.shareImagePaths.length === 0) {
      hilog.error(0x0000, 'OCRDemo', "Failed to get uri.");
      this.safeShowToast({ message: $r('app.string.no_image_selected') });
      return;
    }

    this.safeShowToast({ message: getContext(this).resourceManager.getStringSync($r('app.string.selected_images_processing').id, this.shareImagePaths.length) });

    let ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;

    // 复制所有选中的图片到沙箱（Picker URI 是临时的，不可分享）
    let localImagePaths: string[] = [];
    try {
      for (let i = 0; i < this.shareImagePaths.length; i++) {
        let originalUri = this.shareImagePaths[i];
        // 沙箱内保留原始文件名,分享出去不显示成shareimg_i_时间戳
        let originalName = this.extractFileNameFromUri(originalUri, 'shareimg_' + i + '_' + Date.now() + '.png');
        let targetPath = this.uniqueSandboxPath(ctx.filesDir + '/share_tmp', originalName);

        hilog.info(0x0000, 'localsharepng', `Copying image ${i}: ${originalUri} -> ${targetPath}`);

        // 使用 copyFile 复制（比 openSync+readSync+writeSync 更可靠，自动处理权限）
        try {
          fileIo.copyFileSync(originalUri, targetPath);
        } catch (copyErr) {
          // copyFileSync 可能不支持 media URI，降级为手动读写
          hilog.warn(0x0000, 'localsharepng', `copyFileSync failed for ${i}, fallback to manual copy: ${JSON.stringify(copyErr)}`);
          let sourceFile = fileIo.openSync(originalUri, fileIo.OpenMode.READ_ONLY);
          let targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
          let bufferSize = 1024 * 1024;
          let buffer = new ArrayBuffer(bufferSize);
          let readLen: number = 0;
          while ((readLen = fileIo.readSync(sourceFile.fd, buffer)) > 0) {
            fileIo.writeSync(targetFile.fd, buffer, { length: readLen });
          }
          fileIo.closeSync(sourceFile);
          fileIo.closeSync(targetFile);
        }

        // 验证文件
        let stat = fileIo.statSync(targetPath);
        hilog.info(0x0000, 'localsharepng', `Copy completed for image ${i}: ${targetPath}, size=${stat.size}`);

        localImagePaths.push(toFileUri(targetPath));
      }

      // 等待文件系统同步
      await new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 100);
      });

      // 更新 shareImagePaths 为沙箱文件路径(追加到已有选择)
      this.shareImagePaths = previousImagePaths.concat(localImagePaths);
      this.shareImagePath = this.shareImagePaths[0];
      // 确保在图片类型
      this.shareTypeIndex = 2;

      hilog.info(0x0000, 'localsharepng', 'Share image path updated: ' + this.shareImagePath);
      hilog.info(0x0000, 'localsharepng', 'Total images copied: ' + this.shareImagePaths.length);
      this.safeShowToast({ message: getContext(this).resourceManager.getStringSync($r('app.string.added_images').id, localImagePaths.length) });
    } catch (error) {
      hilog.error(0x0000, 'localsharepng', 'Copy failed: ' + JSON.stringify(error));
      // 降级：仍使用原始URI显示，但分享可能不可用
      this.shareImagePath = this.shareImagePaths[0];
      this.shareTypeIndex = 2;
      this.safeShowToast({ message: $r('app.string.image_copy_to_sandbox_failed') });
    }

    // 强制刷新分享图片显示
    this.imageKey = Date.now().toString();
  }

  // 将指定图片设置为背景图片
  private async setImageAsBackground(imagePath: string): Promise<void> {
    console.log('=== setImageAsBackground 开始 ===');
    console.log('要设置为背景的图片 URI: ' + imagePath);

    try {
      // 根据图片URI获取扩展名
      let extension = '.png';
      if (imagePath.endsWith('.png')) {
        extension = '.png';
      } else if (imagePath.endsWith('.jpg') || imagePath.endsWith('.jpeg')) {
        extension = '.jpg';
      } else if (imagePath.endsWith('.webp')) {
        extension = '.webp';
      }

      this.imageExtension = extension;

      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let targetPath = context.filesDir + '/pengyipeng' + this.imageExtension;

      // 复制文件到应用目录
      let sourceFile = fileIo.openSync(imagePath, fileIo.OpenMode.READ_ONLY);
      let targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);

      let bufferSize = 1024 * 1024;
      let buffer = new ArrayBuffer(bufferSize);
      let readLen: number = 0;

      while ((readLen = fileIo.readSync(sourceFile.fd, buffer)) > 0) {
        fileIo.writeSync(targetFile.fd, buffer, { length: readLen });
      }

      fileIo.closeSync(sourceFile);
      fileIo.closeSync(targetFile);

      hilog.info(0x0000, 'HomePage', 'Copy completed: ' + targetPath);

      // 等待文件系统同步
      await new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 100);
      });

      // 释放之前的背景PixelMap
      if (this.backgroundPixelMap) {
        this.backgroundPixelMap.release();
        this.backgroundPixelMap = undefined;
      }

      // 加载为PixelMap
      let imageSource: image.ImageSource | undefined = undefined;
      try {
        imageSource = image.createImageSource(targetPath);
        this.backgroundPixelMap = await imageSource.createPixelMap();
      } finally {
      }

      // 更新背景图片(独立状态,不影响分享图片)
      this.backgroundImagePath = 'file://' + targetPath;
      hilog.info(0x0000, 'HomePage', 'Background image updated to: ' + this.backgroundImagePath);

      // 标记用户已手动设置自定义背景
      this.useCustomBackground = true;

      // 强制刷新背景图片显示
      this.backgroundImageKey = Date.now().toString();

      // 重新获取图片宽高比(使用背景图片)
      await this.getImageAspectRatio();

      // 如果是横屏+隔空模式，获取主颜色
      if (this.imageAspectRatio >= 1 && this.selectedShareMode === 1) {
        await this.extractMainColor();
      }

      this.safeShowToast({ message: $r('app.string.set_as_background_success') });

      console.log('=== setImageAsBackground 结束 ===');
    } catch (error) {
      hilog.error(0x0000, 'HomePage', 'setImageAsBackground failed: ' + JSON.stringify(error));
      this.safeShowToast({ message: $r('app.string.set_background_failed') });
    }
  }

  private openPhoto(): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 500 // 最多选择500个图片
      }).then((res: photoAccessHelper.PhotoSelectResult) => {
        if (!res.photoUris || res.photoUris.length === 0) {
          hilog.warn(0x0000, 'OCRDemo', 'No photo selected');
          reject('no_selection');
          return;
        }
        hilog.info(0x0000, 'OCRDemo', `Photo selected: count=${res.photoUris.length}, firstUri=${res.photoUris[0]}`);
        this.shareImagePaths = res.photoUris; // 保存所有选择的图片
        resolve(res.photoUris[0]);
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'OCRDemo', `Failed to get photo image uri. code：${err.code}，message：${err.message}`);
        reject('');
      })
    })
  }

  private urlDebounceTimer: number = 0

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
    if (!url || typeof url !== 'string') {
      return false;
    }
    const trimmedUrl = url.trim();
    if (trimmedUrl.length < 3 || trimmedUrl.length > 2048) {
      return false;
    }

    // 不能包含空格
    if (trimmedUrl.includes(' ')) {
      return false;
    }

    // 检查是否为 file:// 协议（本地文件），不算作网络 URL
    if (trimmedUrl.startsWith('file://')) {
      return false;
    }

    // 检查是否为 http:// 或 https:// 开头的 URL
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      const domainStart = trimmedUrl.indexOf('://') + 3;
      if (domainStart >= trimmedUrl.length) return false;

      const domainPart = trimmedUrl.substring(domainStart);
      if (domainPart.length === 0) return false;

      // 域名至少包含一个点
      if (!domainPart.includes('.')) {
        return false;
      }

      return true;
    }

    // 检查是否为 URL scheme 格式（如 bilibili://, weixin://, tel:, mailto:, etc.）
    const colonIndex = trimmedUrl.indexOf(':');
    if (colonIndex === -1 || colonIndex === 0) {
      return false;
    }

    const scheme = trimmedUrl.substring(0, colonIndex);
    const rest = trimmedUrl.substring(colonIndex + 1);

    // scheme 部分必须只包含字母、数字、点、加号和减号
    for (let i = 0; i < scheme.length; i++) {
      const char = scheme[i];
      const lowerChar = char.toLowerCase();
      if (!((lowerChar >= 'a' && lowerChar <= 'z') || (char >= '0' && char <= '9') || char === '.' || char === '+' || char === '-')) {
        return false;
      }
    }

    // scheme 后面必须有内容（可以是 // 或其他内容）
    return rest.length > 0;
  }

  // 判断是否为默认背景图片
  isDefaultBackground(url: string): boolean {
    if (!url) {
      return false;
    }
    return this.defaultBackgroundUrls.some(defaultUrl => url === defaultUrl || url.includes(defaultUrl.split('?')[0]));
  }

  // 从文本中提取链接
  extractUrlFromText(text: string): string | null {
    if (!text || text.trim() === '') {
      return null;
    }

    const trimmedText = text.trim();
    let startIndex = -1;

    // 查找 http:// 或 https:// 的起始位置
    for (let i = 0; i < trimmedText.length - 6; i++) {
      if (trimmedText.substr(i, 7) === 'http://' ||
          (i < trimmedText.length - 7 && trimmedText.substr(i, 8) === 'https://')) {
        startIndex = i;
        break;
      }
    }

    if (startIndex === -1) {
      return null;
    }

    // 提取URL直到遇到空白字符或常见结束符
    let endIndex = startIndex;
    const endChars = [' ', '\n', '\t', '"', "'", '<', '>', '，', '。', '！', '？', '【', '】'];
    while (endIndex < trimmedText.length) {
      const char = trimmedText[endIndex];
      if (endChars.includes(char)) {
        break;
      }
      endIndex++;
    }

    const extractedUrl = trimmedText.substring(startIndex, endIndex);

    // 验证提取的URL是否有效
    if (this.isValidUrl(extractedUrl)) {
      return extractedUrl;
    }

    return null;
  }

  aboutToAppear(): void {
    console.log('=== aboutToAppear 开始 ===');
    // 初始化断点状态
    this.currentBreakpointForUI = this.currentBreakpoint;
    console.info(`HomePage aboutToAppear: currentBreakpoint=${this.currentBreakpoint}, currentBreakpointForUI=${this.currentBreakpointForUI}`);
    // 根据屏幕宽度判断是否使用分栏布局
    this.updateSplitLayoutByWidth();
    let context = getContext(this);

    // 从 AppStorage 读取接续数据（由 EntryAbility 在 restoreDistributedObject 中设置）
    const restoredPengtitle = AppStorage.get<string>('pengtitle');
    const restoredShareLinkContent = AppStorage.get<string>('shareLinkContent');

    console.log('aboutToAppear: restoredPengtitle from AppStorage = ' + (restoredPengtitle ?? 'null'));
    console.log('aboutToAppear: restoredShareLinkContent from AppStorage = ' + (restoredShareLinkContent ?? 'null'));

    // 恢复 pengtitle
    if (restoredPengtitle && restoredPengtitle !== ' ' && restoredPengtitle !== '分享当前的链接') {
      this.pengtitle = restoredPengtitle;
      console.log('接续恢复 pengtitle (从 AppStorage):', restoredPengtitle);
    } else {
      // 如果没有接续数据，才设置默认值
      this.pengtitle = this.context.resourceManager.getStringSync($r('app.string.pengyipeng_title').id);
    }

    // 同步 networkVideoSrc 到 shareLinkContent（仅在非接续场景）
    if (!restoredShareLinkContent || restoredShareLinkContent === '') {
      this.shareLinkContent = this.networkVideoSrc;
      if (this.shareLinkContent && this.shareLinkContent !== '') {
        AppStorage.setOrCreate('shareLinkContent', this.shareLinkContent);
        console.log('aboutToAppear: 保存 shareLinkContent 到 AppStorage: ' + this.shareLinkContent);
      }
    }

    // 初始化 AppStorage 中的默认值（如果不存在）
    if (!AppStorage.get('sharepng')) {
      AppStorage.setOrCreate('sharepng', 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharelink.png?token=01db909c-fd6a-4dcc-8c57-4538e4689629');
    }

    // 保存当前页面信息到 AppStorage,供接续功能使用
    AppStorage.setOrCreate('currentPageUrl', 'pages/HomePage');
    AppStorage.delete('currentRouteParams');

    // 获取顶部安全区域高度
    window.getLastWindow(this.getUIContext().getHostContext() as common.UIAbilityContext).then((windowInstance) => {
      this.topSafeHeight = px2vp(this.topRectHeight);
      this.extractTopBgColor(); // 获取初始背景颜色
    });


    // 元服务不支持分享，预览模式固定使用隔空投送卡片样式
    this.selectedShareMode = 1;
    this.currentDescription = $r('app.string.gekong_description');

    // 恢复接续的数据（优先级最高）- 从 AppStorage 读取
    const restoredSharepng = AppStorage.get<string>('sharepng');
    if (restoredSharepng && restoredSharepng !== 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharelink.png?token=01db909c-fd6a-4dcc-8c57-4538e4689629') {
      console.log('接续恢复 sharepng:', restoredSharepng);
    }

    // 从 AppStorage 恢复接续的分享链接/文本内容
    if (restoredShareLinkContent && restoredShareLinkContent !== '') {
      console.log('接续恢复 shareLinkContent (从 AppStorage):', restoredShareLinkContent);
      // 判断是链接还是文本内容
      if (this.isValidUrl(restoredShareLinkContent)) {
        // 是链接，填充到链接类型，背景图片设置为 sharelink.png
        this.shareLinkContent = restoredShareLinkContent;
        this.shareTypeIndex = 0;
        this.sharepng = 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharelink.png?token=01db909c-fd6a-4dcc-8c57-4538e4689629';
        AppStorage.setOrCreate('sharepng', this.sharepng);
        console.log('接续内容为链接，切换到链接分享类型，设置背景图片为 sharelink.png');
      } else {
        // 是文本内容，填充到文本类型，背景图片设置为 sharetext.png
        this.shareTextContent = restoredShareLinkContent;
        this.shareTypeIndex = 1;
        this.sharepng = 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharetext.png?token=0ff083d9-0f48-4848-b090-b3ecab82e5dd';
        AppStorage.setOrCreate('sharepng', this.sharepng);
        console.log('接续内容为文本，切换到文本分享类型，设置背景图片为 sharetext.png');
      }
      AppStorage.delete('shareLinkContent'); // 清除已处理的接续数据
    } else {
      console.log('aboutToAppear: 没有接续的 shareLinkContent (AppStorage 为空)');
    }

    // 建议调整顺序确保实时参数优先
    const params = navigationManager.getParams() as Record<string, string>;
    if (params?.['videoUrl']) {
      this.networkVideoSrc = params['videoUrl'];
    }
    const sharedUrl = AppStorage.get<string>('sharedVideoUrl');
    if (sharedUrl && this.isValidUrl(sharedUrl)) {
      this.networkVideoSrc = sharedUrl;
      AppStorage.delete('sharedVideoUrl');
    }
    // 触发视频加载
    this.context.eventHub.on('urlUpdate', (url: string) => {
      this.networkVideoSrc = url
      //this.controller.start()
    })

    console.log('=== aboutToAppear 结束 ===');
  }

  aboutToDisappear(): void {
    logger.info('aboutToDisappear invoked.');
    clearTimeout(this.urlDebounceTimer);
    let context = getContext(this);
    context.eventHub.off('onFocus');
    
    // 释放所有PixelMap资源，防止内存泄露
    this.releasePixelMapResources();
  }
  
  // 释放所有PixelMap和ImageSource资源
  private releasePixelMapResources(): void {
    try {
      if (this.picture) {
        this.picture.release();
        this.picture = undefined;
      }
      if (this.localPixelMap) {
        this.localPixelMap.release();
        this.localPixelMap = undefined;
      }
      if (this.backgroundPixelMap) {
        this.backgroundPixelMap.release();
        this.backgroundPixelMap = undefined;
      }
      logger.info('All PixelMap resources released');
    } catch (e) {
      logger.error(`Failed to release PixelMap resources: ${e}`);
    }
  }

  // 根据分享类型获取标题输入框的提示文字
  private getTitlePlaceholder(): string {
    switch (this.shareTypeIndex) {
      case 0:
        return this.context.resourceManager.getStringSync($r('app.string.enter_link_share_title').id);
      case 1:
        return this.context.resourceManager.getStringSync($r('app.string.enter_text_share_title').id);
      case 2:
        return this.context.resourceManager.getStringSync($r('app.string.enter_image_share_title').id);
      case 3:
        return this.context.resourceManager.getStringSync($r('app.string.enter_video_share_title').id);
      case 4:
        return this.context.resourceManager.getStringSync($r('app.string.enter_file_share_title').id);
      default:
        return this.context.resourceManager.getStringSync($r('app.string.enter_share_title').id);
    }
  }

  // 根据分享类型获取对应的标题字符串
  private getShareTypeTitle(typeIndex: number): string {
    let resourceId: Resource;
    switch (typeIndex) {
      case 0:
        resourceId = $r('app.string.pengyipeng_title');
        break;
      case 1:
        resourceId = $r('app.string.share_text_title');
        break;
      case 2:
        resourceId = $r('app.string.share_image_title');
        break;
      case 3:
        resourceId = $r('app.string.share_video_title');
        break;
      case 4:
        resourceId = $r('app.string.share_file_title');
        break;
      default:
        resourceId = $r('app.string.pengyipeng_title');
    }
    return this.context.resourceManager.getStringSync(resourceId.id);
  }

  // 根据分享类型更新标题和背景图片
  private updateTitleForShareType(typeIndex: number): void {
    this.pengtitle = this.getShareTypeTitle(typeIndex);
    // 根据分享类型设置对应的背景图片
    switch (typeIndex) {
      case 0: // 链接
        this.sharepng = 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharelink.png?token=01db909c-fd6a-4dcc-8c57-4538e4689629';
        break;
      case 1: // 文本
        this.sharepng = 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharetext.png?token=0ff083d9-0f48-4848-b090-b3ecab82e5dd';
        break;
      case 2: // 图片
        this.sharepng = 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharepic.png?token=86d11f71-7f41-4ba8-9e2a-f2adda0e6974';
        break;
      case 3: // 视频
        this.sharepng = 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharevideo.png?token=b0fb7863-52d0-471d-b228-c8d565e0b07c';
        break;
      case 4: // 文件
        this.sharepng = 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharefiles.png?token=607f6397-d9bf-40b2-8454-5227510d8c68';
        break;
      default:
        this.sharepng = 'https://agc-storage-drcn.platform.dbankcloud.cn/v0/xhtb-oteot/pngs%2Fsharelink.png?token=01db909c-fd6a-4dcc-8c57-4538e4689629';
    }
    // 切换分享类型时立即更换为对应默认背景图(清除自定义背景标记)
    this.useCustomBackground = false;
    if (this.backgroundPixelMap) {
      this.backgroundPixelMap.release();
      this.backgroundPixelMap = undefined;
    }
    this.backgroundImagePath = this.sharepng;
    this.backgroundImageKey = Date.now().toString();
    // 同步到 AppStorage
    AppStorage.set('pengtitle', this.pengtitle);
    AppStorage.set('sharepng', this.sharepng);
    console.log('updateTitleForShareType: typeIndex = ' + typeIndex + ', sharepng = ' + this.sharepng);
  }




  // 添加一个方法来获取图片的宽高比
  private async getImageAspectRatio(): Promise<void> {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let imageSource: image.ImageSource | undefined = undefined;
      // 优先使用背景图片路径
      let imagePath = this.backgroundImagePath !== '' ? this.backgroundImagePath : this.sharepng;

      console.log('=== getImageAspectRatio 开始 ===');
      console.log('当前背景图片路径: ' + this.backgroundImagePath);
      console.log('当前分享图片路径: ' + this.sharepng);
      console.log('使用的图片路径: ' + imagePath);
      console.log('当前 imageExtension: ' + this.imageExtension);

      try {
        if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
          // 如果是网络图片，使用本地缓存文件
          let localPath = context.filesDir + '/pengyipeng' + this.imageExtension;
          console.log('使用网络图片缓存路径: ' + localPath);
          imageSource = image.createImageSource(localPath);
        } else if (imagePath.startsWith('file://')) {
          // 如果是本地文件
          let filePath = imagePath.substring(7); // 移除 'file://' 前缀
          console.log('使用本地文件路径: ' + filePath);
          imageSource = image.createImageSource(filePath);
        } else {
          // 如果是资源文件
          console.log('使用资源文件: ' + imagePath);
          imageSource = image.createImageSource(imagePath);
        }

        const info = await imageSource.getImageInfo();
        console.log('获取到的图片信息: ' + JSON.stringify(info));

        if (info && info.size && info.size.width > 0 && info.size.height > 0) {
          this.imageAspectRatio = info.size.width / info.size.height;
          this.isImageLoaded = true;
          console.log('宽高比: ' + this.imageAspectRatio);
          console.log('图片宽度: ' + info.size.width);
          console.log('图片高度: ' + info.size.height);

          // 如果是横屏图片，自动获取主颜色
          if (this.imageAspectRatio >= 1) {
            console.log('检测到横屏图片，开始获取主颜色');
            await this.extractMainColor();
            console.log('主颜色获取完成: ' + this.mainColor);
          } else {
            console.log('不是横屏图片，不获取主颜色');
          }
        } else {
          console.log('图片信息无效');
        }
        console.log('=== getImageAspectRatio 结束 ===');
      } finally {
      }
    } catch (error) {
      console.error('Failed to get image info: ' + JSON.stringify(error));
      // 如果获取失败，默认按原始方式处理
      this.isImageLoaded = true;
    }
  }

  // 使用 ColorPicker 获取图片主颜色
  private async extractMainColor(): Promise<void> {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let pixelMap: PixelMap;
      let imageSource: image.ImageSource | undefined = undefined;
      let needReleasePixelMap = false; // 标记是否需要释放pixelMap

      if (this.backgroundPixelMap) {
        // 使用背景图片的 PixelMap
        pixelMap = this.backgroundPixelMap;
      } else {
        // 从文件加载 PixelMap
        let imagePath: string;
        if (this.backgroundImagePath.startsWith('file://')) {
          imagePath = this.backgroundImagePath.substring(7); // 移除 'file://' 前缀
        } else {
          imagePath = context.filesDir + '/pengyipeng' + this.imageExtension;
        }

        try {
          imageSource = image.createImageSource(imagePath);
          pixelMap = await imageSource.createPixelMap();
          needReleasePixelMap = true; // 需要释放这个新创建的pixelMap
        } finally {
        }
      }

      // 使用 ColorPicker 获取主颜色
      effectKit.createColorPicker(pixelMap, (err: BusinessError, colorPicker: effectKit.ColorPicker) => {
        if (err) {
          console.error('创建 ColorPicker 失败: ' + err.message);
          this.mainColor = '#FFFFFF';
          // 释放pixelMap
          if (needReleasePixelMap && pixelMap) {
            pixelMap.release();
          }
          return;
        }

        try {
          const mainColor = colorPicker.getMainColorSync();
          // 将颜色转换为 ARGB 格式的十六进制字符串
          const alpha: string = (mainColor.alpha ?? 255).toString(16).padStart(2, '0');
          const red: string = (mainColor.red ?? 255).toString(16).padStart(2, '0');
          const green: string = (mainColor.green ?? 255).toString(16).padStart(2, '0');
          const blue: string = (mainColor.blue ?? 255).toString(16).padStart(2, '0');
          this.mainColor = `#${alpha}${red}${green}${blue}`;
          console.log('获取到主颜色: ' + this.mainColor);

          // 同时更新顶部背景颜色
          this.updateTopBgColor();
        } catch (error) {
          console.error('获取主颜色失败: ' + JSON.stringify(error));
          this.mainColor = '#FFFFFF';
        } finally {
          // 释放pixelMap
          if (needReleasePixelMap && pixelMap) {
            pixelMap.release();
          }
        }
      });
    } catch (error) {
      console.error('获取主颜色失败: ' + JSON.stringify(error));
      // 失败时使用默认白色
      this.mainColor = '#FFFFFF';
    }
  }

  // 获取顶部背景颜色（带重试机制）
  private async extractTopBgColor(retryCount: number = 0, maxRetries: number = 3): Promise<void> {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let pixelMap: PixelMap;
      let imageSource: image.ImageSource | undefined = undefined;
      let needReleasePixelMap = false; // 标记是否需要释放pixelMap

      if (this.backgroundPixelMap) {
        pixelMap = this.backgroundPixelMap;
      } else {
        let imagePath: string;
        if (this.backgroundImagePath.startsWith('file://')) {
          imagePath = this.backgroundImagePath.substring(7);
        } else {
          imagePath = context.filesDir + '/pengyipeng' + this.imageExtension;
        }
        try {
          imageSource = image.createImageSource(imagePath);
          pixelMap = await imageSource.createPixelMap();
          needReleasePixelMap = true; // 需要释放这个新创建的pixelMap
        } finally {
        }
      }

      effectKit.createColorPicker(pixelMap, (err: BusinessError, colorPicker: effectKit.ColorPicker) => {
        if (err) {
          console.error('创建 ColorPicker 失败: ' + err.message);
          this.topBgColor = '#FFFFFF';
          this.retryExtractTopBgColor(retryCount, maxRetries);
          // 释放pixelMap
          if (needReleasePixelMap && pixelMap) {
            pixelMap.release();
          }
          return;
        }

        try {
          const mainColor = colorPicker.getMainColorSync();
          const alpha: string = (mainColor.alpha ?? 255).toString(CommonConstants.HEXADECIMAL);
          const red: string = (mainColor.red ?? 255).toString(CommonConstants.HEXADECIMAL);
          const green: string = (mainColor.green ?? 255).toString(CommonConstants.HEXADECIMAL);
          const blue: string = (mainColor.blue ?? 255).toString(CommonConstants.HEXADECIMAL);
          this.topBgColor = `#${alpha}${red}${green}${blue}`;
          console.log('获取到顶部背景颜色: ' + this.topBgColor);
        } catch (error) {
          console.error('获取顶部背景颜色失败: ' + JSON.stringify(error));
          this.topBgColor = '#FFFFFF';
          this.retryExtractTopBgColor(retryCount, maxRetries);
        } finally {
          // 释放pixelMap
          if (needReleasePixelMap && pixelMap) {
            pixelMap.release();
          }
        }
      });
    } catch (error) {
      console.error('获取顶部背景颜色失败: ' + JSON.stringify(error));
      this.topBgColor = '#FFFFFF';
      this.retryExtractTopBgColor(retryCount, maxRetries);
    }
  }

  // 重试获取顶部背景颜色
  private retryExtractTopBgColor(retryCount: number, maxRetries: number) {
    if (retryCount < maxRetries) {
      console.log(`获取顶部背景颜色失败，第 ${retryCount + 1} 次重试...`);
      setTimeout(() => {
        this.extractTopBgColor(retryCount + 1, maxRetries);
      }, 500); // 延迟500ms后重试
    } else {
      console.error(`已重试 ${maxRetries} 次，获取顶部背景颜色仍然失败，使用默认白色`);
      this.topBgColor = '#FFFFFF';
    }
  }

  // 更新顶部背景颜色（带动画）
  private updateTopBgColor() {
    this.getUIContext().animateTo({
      duration: CommonConstants.SWIPER_DURATION1,
      curve: Curve.Linear,
      iterations: CommonConstants.ANIMATION_ITERATIONS
    }, () => {
      this.topBgColor = this.mainColor;
    });
  }

  build() {
    Column() {
      // 固定顶部避让边:不随滚动,避开状态栏与元服务胶囊
      Blank().height(Math.max(px2vp(this.topRectHeight) + 25, 60)).width("100%")
      // 根据屏幕宽度选择不同的布局（>=840vp使用分栏布局）
      if (this.useSplitLayoutByWidth) {
        // 大屏：使用左右两栏布局
        Row() {
          // 左侧：预览区域（胶囊按钮 + Stack 图片预览）
          Column() {
            Scroll() {
              Column() {
                this.PreviewTopBuilder()
                this.PreviewStackBuilder()
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .padding({ left: 16, right: 16 })
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('45%')
          .height('100%')
          .padding({ right: 10 })

          // 右侧：其他所有内容（卡片容器 + 碰一碰引导）
          Scroll() {
            Column() {
              this.CardContainerBuilder()
              // 底部避让空白区域(沉浸tab模式使用100vp，普通tab模式使用16vp)
              Blank().height(this.isImmersiveTab ? 100 : 16).width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ left: 10, right: 16 })
          }
          .width('55%')
          .height('100%')
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        // 其他断点：保持原有的垂直布局
        Scroll() {
          Column() {
            this.PreviewTopBuilder()
            this.PreviewStackBuilder()
            this.CardContainerBuilder()
            // 底部避让空白区域(沉浸tab模式使用100vp，普通tab模式使用16vp)
            Blank().height(this.isImmersiveTab ? 100 : 16).width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 10 })
          .padding({ left: '5%', right: '5%' })
        }.scrollBar(BarState.Off)
        .layoutWeight(1)
      }
    }
    .width(CommonConstants.FULL_PARENT)
    .height(CommonConstants.FULL_PARENT)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[this.topBgColor, CommonConstants.START_GRADIENT_RANGE], [$r('app.color.page_background_gradient_end'), CommonConstants.END_GRADIENT_RANGE]]
    })

  }

  // 处理胶囊按钮选择变化
  private handleShareModeChange(index: number) {
    this.selectedShareMode = index;
    // 根据选中的模式更新描述
    if (index === 1) {
      // 隔空传送模式
      this.currentDescription = $r('app.string.gekong_description');
    } else {
      // 碰一碰模式
      this.currentDescription = $r('app.string.pengyipeng_description');
    }
  }



  // ========== 通用 @Builder 函数（消除手机/平板布局重复代码） ==========

  // 胶囊按钮
  @Builder
  PreviewTopBuilder() {
    DeviceSegmentButton({
      initialIndex: this.selectedShareMode,
      onIndexChange: (index: number) => {
        this.handleShareModeChange(index);
      }
    })
      .margin({ top: 10, bottom: this.useSplitLayoutByWidth ? 20 : 5 })
  }

  // 图片预览 Stack（三种模式）
  @Builder
  PreviewStackBuilder() {
    Stack() {
      // 横屏图片 + 碰一碰模式：使用卡片样式
      if (this.imageAspectRatio >= 1 && this.selectedShareMode === 0) {
        Column() {
          if (this.backgroundPixelMap) {
            Image(this.backgroundPixelMap)
              .width('100%')
              .aspectRatio(1.5)
              .margin({ bottom: 0 })
              .objectFit(ImageFit.Cover)
              .borderRadius(20)
              .linearGradientBlur(60,
                { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
              .onComplete(() => {
                this.getImageAspectRatio();
                this.extractMainColor();
              })
          } else {
            Image(this.backgroundImagePath)
              .width('100%')
              .aspectRatio(1.5)
              .objectFit(ImageFit.Cover)
              .borderRadius(20)
              .linearGradientBlur(60,
                { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
              .onComplete(() => {
                this.getImageAspectRatio();
                this.extractMainColor();
              })
          }
          Text(this.pengtitle)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 12, bottom: 8 })
            .blur(0)
            .fontColor(Color.Black)
          Text(this.currentDescription)
            .fontSize(16)
            .fontColor(0xA3A3A3)
            .margin({ bottom: 5 })
            .blur(0)
          Image($r('app.media.CIcon'))
            .width(20)
            .height(20)
            .margin({ bottom: 12 })
            .blur(0)
        }
        .width('100%')
        .constraintSize({ maxWidth: 350 })
        .height('auto')
        .backgroundColor(this.mainColor)
        .borderRadius(20)
        .border({ width: 2, color: 0xCCCCCC })
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
      } else if (this.imageAspectRatio >= 1 && this.selectedShareMode === 1) {
        // 横屏+隔空
        Column() {
          if (this.backgroundPixelMap) {
            Image(this.backgroundPixelMap)
              .width('100%')
              .aspectRatio(1.4)
              .objectFit(ImageFit.Cover)
              .borderRadius(10)
          } else {
            Image(this.backgroundImagePath)
              .width('100%')
              .aspectRatio(1.4)
              .objectFit(ImageFit.Cover)
              .borderRadius(10)
              .onComplete(() => {
                this.getImageAspectRatio();
              })
          }
          Text(this.pengtitle)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 12, bottom: 8 })
            .blur(0)
            .fontColor(Color.Black)
          Text(this.currentDescription)
            .fontSize(16)
            .fontColor(0xA3A3A3)
            .margin({ bottom: 5 })
            .blur(0)
          Image($r('app.media.CIcon'))
            .width(20)
            .height(20)
            .blur(0)
            .margin({ bottom: 8 })
        }
        .width('100%')
        .constraintSize({ maxWidth: 350 })
        .height('auto')
        .padding(8)
        .backgroundColor(0xFFFFFF)
        .borderRadius(20)
        .border({ width: 2, color: 0xCCCCCC })
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
      } else {
        // 其他模式：保持原有 Stack 样式
        if (this.backgroundPixelMap) {
          Column() {
            Image(this.backgroundPixelMap)
              .width(this.imageAspectRatio < 1 ? '100%' : '80%')
              .height(this.imageAspectRatio < 1 ? 'auto' : (this.selectedShareMode === 1 && this.imageAspectRatio >= 1 ? '80%' : '80%'))
              .constraintSize({ maxWidth: this.imageAspectRatio < 1 ? 250 : '100%' })
              .objectFit(ImageFit.Contain)
              .blur(0)
              .linearGradientBlur(60,
                { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
              .borderRadius(20)
          }
          .border({ width: 1, color: 0xCCCCCC })
          .borderRadius(20)
          .alignSelf(ItemAlign.Start)
          .justifyContent(FlexAlign.Center)
          .margin({ top: 0 })
        } else {
          Column() {
            Image(this.backgroundImagePath)
              .width(this.imageAspectRatio < 1 ? '100%' : '80%')
              .height(this.imageAspectRatio < 1 ? 'auto' : (this.selectedShareMode === 1 && this.imageAspectRatio >= 1 ? '80%' : '80%'))
              .constraintSize({ maxWidth: this.imageAspectRatio < 1 ? 250 : '100%' })
              .objectFit(ImageFit.Contain)
              .blur(0)
              .linearGradientBlur(60,
                { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
              .borderRadius(20)
              .onComplete(() => {
                this.getImageAspectRatio();
              })
          }
          .border({ width: 1, color: 0xCCCCCC })
          .borderRadius(20)
          .alignSelf(ItemAlign.Start)
          .justifyContent(FlexAlign.Center)
          .margin({ top: 0 })
        }
        Column() {
          Text(this.pengtitle)
            .fontWeight(600)
            .fontSize('20fp')
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)
            .fontColor($r('app.color.pengtitle'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 250 })
            .textAlign(TextAlign.Center)
          Text(this.currentDescription)
            .fontWeight(400)
            .fontSize('13vp')
            .margin({ top: 5, bottom: 5 })
            .fontWeight(FontWeight.Medium)
            .opacity(0.5)
            .fontColor($r('app.color.font_secondary'))
          Image($r('app.media.CIcon'))
            .width(20)
            .height(20)
            .margin({ top: 5, bottom: 10 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .align(Alignment.Bottom)
        .constraintSize({ maxWidth: '100%' })
      }
    }
    .width('100%')
    .height('auto')
    .alignContent(Alignment.Bottom)
    .margin({ bottom: this.useSplitLayoutByWidth ? 0 : 20 })
  }

  // 卡片容器：分享图片 + 分享内容 + 分享标题 + (平板含分享按钮)
  @Builder
  CardContainerBuilder() {
    Column() {
      // 区域1：分享图片
      this.ShareImageSectionBuilder()
      // 区域2：分享内容
      this.ShareContentSectionBuilder()
      // 区域3：分享标题
      this.ShareTitleSectionBuilder()
    }
    .width('100%')
    .backgroundColor(this.useSplitLayoutByWidth ? $r('app.color.card_container_background') : Color.Transparent)
    .borderRadius(this.useSplitLayoutByWidth ? 16 : 0)
    .padding(this.useSplitLayoutByWidth ? { left: 16, right: 16, top: 16, bottom: 16 } : 0)
    .margin({ bottom: this.useSplitLayoutByWidth ? 20 : 0 })
  }

  // 区域1：分享图片
  @Builder
  ShareImageSectionBuilder() {
    Column() {
      Row() {
        Text($r('app.string.sharepngon'))
          .textAlign(TextAlign.Center)
          .width('55%')
          .margin({ right: 10 })
        Button($r('app.string.choose'))
          .height(50)
          .width('40%')
          .backgroundColor(0xb87cff)
          .onClick(() => {
            this.selectImage();
          })
      }
      .width('100%')
      .height(this.useSplitLayoutByWidth ? undefined : 50)

      Row() {
        TextArea({ placeholder: $r('app.string.sharepng'), text: this.isDefaultBackground(this.sharepng) ? '' : this.sharepng })
          .layoutWeight(1)
          .onChange((sharepng: string) => {
            this.sharepng = sharepng;
            if (this.isValidUrl(sharepng)) {
              // 直接由 Image 组件加载网络图;清掉旧的本地预览像素图
              if (this.backgroundPixelMap) {
                this.backgroundPixelMap.release();
                this.backgroundPixelMap = undefined;
              }
              this.backgroundImagePath = sharepng;
              this.backgroundImageKey = Date.now().toString();
            }
          })
        Row() {
          PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
            .backgroundColor(0xb87cff)
            .height(40)
            .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
              if (PasteButtonOnClickResult.SUCCESS === result) {
                pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                  if (err) {
                    console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                    return;
                  }
                  this.sharepng = pasteData.getPrimaryText();
                  this.safeShowToast({ message: $r('app.string.pastedtishi') });
                });
              }
            })
        }
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 10, bottom: 10 })
    }
    .width('100%')
    .backgroundColor($r('app.color.comp_background_list_card'))
    .borderRadius(8)
    .padding(12)
    .margin({ bottom: 10 })
    .border({ width: 1, color: $r('sys.color.comp_divider') })
  }

  // 区域2：分享内容（含类型切换和5种类型UI）
  @Builder
  ShareContentSectionBuilder() {
    Column() {
      // 分享类型选择胶囊按钮
      Row() {
        Button($r('app.string.link'))
          .fontSize(this.useSplitLayoutByWidth ? 14 : 13)
          .height(this.useSplitLayoutByWidth ? 36 : 32)
          .layoutWeight(this.useSplitLayoutByWidth ? undefined : 1)
          .backgroundColor(this.shareTypeIndex === 0 ? 0x66CCFF : 0xE0E0E0)
          .fontColor(this.shareTypeIndex === 0 ? 0xFFFFFF : 0x000000)
          .borderRadius(this.useSplitLayoutByWidth ? 8 : 6)
          .margin({ right: this.useSplitLayoutByWidth ? 5 : 4 })
          .padding(this.useSplitLayoutByWidth ? undefined : { left: 4, right: 4 })
          .onClick(() => { this.shareTypeIndex = 0; this.updateTitleForShareType(0); })
        Button($r('app.string.text'))
          .fontSize(this.useSplitLayoutByWidth ? 14 : 13)
          .height(this.useSplitLayoutByWidth ? 36 : 32)
          .layoutWeight(this.useSplitLayoutByWidth ? undefined : 1)
          .backgroundColor(this.shareTypeIndex === 1 ? 0x66CCFF : 0xE0E0E0)
          .fontColor(this.shareTypeIndex === 1 ? 0xFFFFFF : 0x000000)
          .borderRadius(this.useSplitLayoutByWidth ? 8 : 6)
          .margin({ right: this.useSplitLayoutByWidth ? 5 : 4 })
          .padding(this.useSplitLayoutByWidth ? undefined : { left: 4, right: 4 })
          .onClick(() => { this.shareTypeIndex = 1; this.updateTitleForShareType(1); })
        Button($r('app.string.image'))
          .fontSize(this.useSplitLayoutByWidth ? 14 : 13)
          .height(this.useSplitLayoutByWidth ? 36 : 32)
          .layoutWeight(this.useSplitLayoutByWidth ? undefined : 1)
          .backgroundColor(this.shareTypeIndex === 2 ? 0x66CCFF : 0xE0E0E0)
          .fontColor(this.shareTypeIndex === 2 ? 0xFFFFFF : 0x000000)
          .borderRadius(this.useSplitLayoutByWidth ? 8 : 6)
          .margin({ right: this.useSplitLayoutByWidth ? 5 : 4 })
          .padding(this.useSplitLayoutByWidth ? undefined : { left: 4, right: 4 })
          .onClick(() => { this.shareTypeIndex = 2; this.updateTitleForShareType(2); })
        Button($r('app.string.video'))
          .fontSize(this.useSplitLayoutByWidth ? 14 : 13)
          .height(this.useSplitLayoutByWidth ? 36 : 32)
          .layoutWeight(this.useSplitLayoutByWidth ? undefined : 1)
          .backgroundColor(this.shareTypeIndex === 3 ? 0x66CCFF : 0xE0E0E0)
          .fontColor(this.shareTypeIndex === 3 ? 0xFFFFFF : 0x000000)
          .borderRadius(this.useSplitLayoutByWidth ? 8 : 6)
          .margin({ right: this.useSplitLayoutByWidth ? 5 : 4 })
          .padding(this.useSplitLayoutByWidth ? undefined : { left: 4, right: 4 })
          .onClick(() => { this.shareTypeIndex = 3; this.updateTitleForShareType(3); })
        Button($r('app.string.file'))
          .fontSize(this.useSplitLayoutByWidth ? 14 : 13)
          .height(this.useSplitLayoutByWidth ? 36 : 32)
          .layoutWeight(this.useSplitLayoutByWidth ? undefined : 1)
          .backgroundColor(this.shareTypeIndex === 4 ? 0x66CCFF : 0xE0E0E0)
          .fontColor(this.shareTypeIndex === 4 ? 0xFFFFFF : 0x000000)
          .borderRadius(this.useSplitLayoutByWidth ? 8 : 6)
          .margin({ right: this.useSplitLayoutByWidth ? 5 : 4 })
          .padding(this.useSplitLayoutByWidth ? undefined : { left: 4, right: 4 })
          .onClick(() => { this.shareTypeIndex = 4; this.updateTitleForShareType(4); })
      }
      .width('100%')
      .justifyContent(this.useSplitLayoutByWidth ? FlexAlign.SpaceEvenly : FlexAlign.SpaceBetween)
      .margin({ bottom: 10 })

      // 根据选择的类型显示不同的内容
      if (this.shareTypeIndex === 0) {
        // 链接分享
        this.LinkShareContentBuilder()
      } else if (this.shareTypeIndex === 1) {
        // 文本分享
        this.TextShareContentBuilder()
      } else if (this.shareTypeIndex === 2) {
        // 图片分享
        this.ImageShareContentBuilder()
      } else if (this.shareTypeIndex === 3) {
        // 视频分享
        this.VideoShareContentBuilder()
      } else if (this.shareTypeIndex === 4) {
        // 文件分享
        this.FileShareContentBuilder()
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.comp_background_list_card'))
    .borderRadius(8)
    .padding(12)
    .margin({ bottom: 10 })
    .border({ width: 1, color: $r('app.color.card_border_color') })
  }

  // 链接分享内容
  @Builder
  LinkShareContentBuilder() {
    Column() {
      if (deviceInfo.deviceType !== '2in1') {
        Row() {
          Text($r('app.string.texton'))
            .textAlign(TextAlign.Center)
            .width('55%')
            .margin({ right: 10 })
          Button(this.useSplitLayoutByWidth ? $r('app.string.scancodelinkpad') : $r('app.string.scancodelink'))
            .height(50)
            .width('40%')
            .backgroundColor(0xFF66CC)
            .onClick(async () => {
              try {
                let options: scanBarcode.ScanOptions = {
                  scanTypes: [scanCore.ScanType.ALL],
                  enableMultiMode: true,
                  enableAlbum: true
                };
                scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
                  const originalValue: string = result.originalValue;
                  this.shareLinkContent = originalValue;
                  this.networkVideoSrc = originalValue;
                  this.safeShowToast({ duration: 10000, message: this.context.resourceManager.getStringSync($r('app.string.scan_success').id) + originalValue });
                }).catch((error: BusinessError) => {
                  hilog.error(0x0001, '[Scan]',
                    `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
                  this.safeShowToast({ message: $r('app.string.scan_cancel_or_failed') });
                });
              } catch (error) {
                this.safeShowToast({ message: $r('app.string.scan_start_failed') });
                hilog.error(0x0001, '[Scan]',
                  `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
              }
            })
        }
        .width('100%')
        .height(50)
        .margin({ bottom: 10 })
      }

      Row() {
        TextArea({ placeholder: $r('app.string.testinput'), text: this.shareLinkContent })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.shareLinkContent = value;
            clearTimeout(this.urlDebounceTimer);
            this.urlDebounceTimer = setTimeout(() => {
              const extractedUrl = this.extractUrlFromText(value);
              if (extractedUrl) {
                this.shareLinkContent = extractedUrl;
                this.networkVideoSrc = extractedUrl;
              } else {
                this.shareLinkContent = value;
                this.networkVideoSrc = value;
              }
              AppStorage.setOrCreate('shareLinkContent', this.shareLinkContent);
              if (!this.useSplitLayoutByWidth) {
                AppStorage.set('networkVideoSrc', this.networkVideoSrc);
              }
            }, 300);
          })
        Row() {
          PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
            .backgroundColor(0xFF66CC)
            .height(40)
            .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
              if (PasteButtonOnClickResult.SUCCESS === result) {
                pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                  if (err) {
                    console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                    return;
                  }
                  this.shareLinkContent = pasteData.getPrimaryText();
                  this.networkVideoSrc = this.shareLinkContent;
                  this.safeShowToast({ message: $r('app.string.pastedtishi') });
                });
              }
            })
        }
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }

  // 文本分享内容
  @Builder
  TextShareContentBuilder() {
    Column() {
      Row() {
        TextArea({ placeholder: $r('app.string.textinput'), text: this.shareTextContent })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.shareTextContent = value;
            AppStorage.setOrCreate('shareLinkContent', value);
          })
        Row() {
          PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
            .backgroundColor(0xFF66CC)
            .height(40)
            .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
              if (PasteButtonOnClickResult.SUCCESS === result) {
                pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                  if (err) {
                    console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                    return;
                  }
                  this.shareTextContent = pasteData.getPrimaryText();
                  this.safeShowToast({ message: $r('app.string.pastedtishi') });
                });
              }
            })
        }
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }

  // 图片分享内容
  @Builder
  ImageShareContentBuilder() {
    Column() {
      Row() {
        Text($r('app.string.pictureon'))
          .textAlign(TextAlign.Center)
          .width('55%')
          .margin({ right: 10 })
        if (this.shareImagePaths.length > 0) {
          // 已选过图片:分成清空+添加两个按钮
          Row({ space: 8 }) {
             Button($r('app.string.clear'))
               .height(50)
               .layoutWeight(1)
               .backgroundColor(0xE0E0E0)
               .fontColor(0x000000)
               .onClick(() => {
                 this.shareImagePaths = [];
                 this.shareImagePath = '';
               })
            Button($r('app.string.choose'))
              .height(50)
              .layoutWeight(1)
              .backgroundColor(0xFF66CC)
              .onClick(() => {
                this.selectShareImage();
              })
          }
          .width('40%')
          .alignItems(VerticalAlign.Center)
        } else {
          Button($r('app.string.choose'))
            .height(50)
            .width('40%')
            .backgroundColor(0xFF66CC)
            .onClick(() => {
              this.selectShareImage();
            })
        }
      }
      .width('100%')
      ForEach(this.shareImagePaths, (item: string, index: number) => {
        Row() {
          TextArea({ placeholder: this.context.resourceManager.getStringSync($r('app.string.image_path_index').id, index + 1), text: item })
            .enabled(false)
            .layoutWeight(1)
          Button($r('app.string.setasbackgroundatthesametime'))
            .height(50)
            .backgroundColor(0xFF66CC)
            .fontSize(12)
            .onClick(() => {
              this.setImageAsBackground(item);
            })
        }
        .width('100%')
        .margin({ top: 5 })
      })
      if (this.shareImagePaths.length > 1) {
        Text(this.context.resourceManager.getStringSync($r('app.string.selected_images_count_label').id, this.shareImagePaths.length))
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 5 })
      }
    }
  }

  // 视频分享内容
  @Builder
  VideoShareContentBuilder() {
    Column() {
      Row() {
        Text($r('app.string.videoon'))
          .textAlign(TextAlign.Center)
          .width('55%')
          .margin({ right: 10 })
        if (this.shareVideoPaths.length > 0) {
          // 已选过视频:分成清空+添加两个按钮
          Row({ space: 8 }) {
             Button($r('app.string.clear'))
               .height(50)
               .layoutWeight(1)
               .backgroundColor(0xE0E0E0)
               .fontColor(0x000000)
               .onClick(() => {
                 this.shareVideoPaths = [];
                 this.shareVideoPath = '';
               })
            Button($r('app.string.choosevideo'))
              .height(50)
              .layoutWeight(1)
              .backgroundColor(0xFF66CC)
              .onClick(async () => {
                await this.selectVideo();
              })
          }
          .width('40%')
          .alignItems(VerticalAlign.Center)
        } else {
          Button($r('app.string.choosevideo'))
            .height(50)
            .width('40%')
            .backgroundColor(0xFF66CC)
            .onClick(async () => {
              await this.selectVideo();
            })
        }
      }
      .width('100%')
      ForEach(this.shareVideoPaths, (item: string, index: number) => {
         TextArea({ placeholder: this.context.resourceManager.getStringSync($r('app.string.video_path_index').id, index + 1), text: item })
          .enabled(false)
          .margin({ top: 5 })
      })
      if (this.shareVideoPaths.length > 1) {
        Text(this.context.resourceManager.getStringSync($r('app.string.selected_videos_count_label').id, this.shareVideoPaths.length))
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 5 })
      }
    }
  }

  // 文件分享内容
  @Builder
  FileShareContentBuilder() {
    Column() {
      Row() {
        Text($r('app.string.share_file_label'))
          .textAlign(TextAlign.Center)
          .width('55%')
          .margin({ right: 10 })
        if (this.shareFilePaths.length > 0) {
          // 已选过文件:分成清空+添加两个按钮
          Row({ space: 8 }) {
             Button($r('app.string.clear'))
               .height(50)
               .layoutWeight(1)
               .backgroundColor(0xE0E0E0)
               .fontColor(0x000000)
               .onClick(() => {
                 this.shareFilePaths = [];
                 this.shareFilePath = '';
               })
             Button($r('app.string.add'))
              .height(50)
              .layoutWeight(1)
              .backgroundColor(0xFF66CC)
              .onClick(async () => {
                await this.selectFile();
              })
          }
          .width('40%')
          .alignItems(VerticalAlign.Center)
        } else {
           Button($r('app.string.select_file'))
            .height(50)
            .width('40%')
            .backgroundColor(0xFF66CC)
            .onClick(async () => {
              await this.selectFile();
            })
        }
      }
      .width('100%')
      ForEach(this.shareFilePaths, (item: string, index: number) => {
         TextArea({ placeholder: this.context.resourceManager.getStringSync($r('app.string.file_path_index').id, index + 1), text: item })
          .enabled(false)
          .margin({ top: 5 })
      })
      if (this.shareFilePaths.length > 1) {
        Text(this.context.resourceManager.getStringSync($r('app.string.selected_files_count_label').id, this.shareFilePaths.length))
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 5 })
      }
  }
  }

  // 区域3：分享标题
  @Builder
  ShareTitleSectionBuilder() {
    Column() {
      Row() {
        Text($r('app.string.pengtitleset'))
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .height(50)

      Row() {
        TextArea({
          placeholder: this.useSplitLayoutByWidth ? $r('app.string.pengyipeng_title') : this.getTitlePlaceholder(),
          text: this.pengtitle
        })
          .layoutWeight(1)
          .onChange((pengtitle: string) => {
            this.pengtitle = pengtitle;
            if (!this.useSplitLayoutByWidth) {
              AppStorage.set('pengtitle', pengtitle);
            }
          })
        Row() {
          PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
            .backgroundColor(0x66CCFF)
            .height(40)
            .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
              if (PasteButtonOnClickResult.SUCCESS === result) {
                pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                  if (err) {
                    console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                    return;
                  }
                  this.pengtitle = pasteData.getPrimaryText();
                  this.safeShowToast({ message: $r('app.string.pastedtishi') });
                });
              }
            })
        }
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 5, bottom: 10 })
    }
    .width('100%')
    .backgroundColor($r('app.color.comp_background_list_card'))
    .borderRadius(8)
    .padding(12)
    .margin({ bottom: 10 })
    .border({ width: 1, color: $r('app.color.card_border_color') })
  }

  // 选择视频（复制到沙箱，确保分享时可被其他应用访问）
  private async selectVideo(): Promise<void> {
    let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    let res: photoAccessHelper.PhotoSelectResult;
    try {
      res = await photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE,
        maxSelectNumber: 500
      });
    } catch (err) {
      let error = err as BusinessError;
      hilog.error(0x0000, 'HomePage', `Failed to select video. code：${error.code}，message：${error.message}`);
      this.safeShowToast({ message: $r('app.string.video_select_failed') });
      return;
    }

    if (!res.photoUris || res.photoUris.length === 0) {
      return;
    }

    let pickerUris = res.photoUris;
    hilog.info(0x0000, 'HomePage', `Selected ${pickerUris.length} videos, copying to sandbox...`);

    // 复制所有视频到沙箱目录（与 selectShareImage 同理，Picker URI 是临时的，不可分享）
    let localVideoPaths: string[] = [];
    try {
      for (let i = 0; i < pickerUris.length; i++) {
        let originalUri = pickerUris[i];
        // 沙箱内保留原始文件名,分享出去不显示成sharevideo_i_时间戳
        let originalName = this.extractFileNameFromUri(originalUri, 'sharevideo_' + i + '_' + Date.now() + '.mp4');
        let targetPath = this.uniqueSandboxPath(context.filesDir + '/share_tmp', originalName);

        hilog.info(0x0000, 'HomePage', `Copying video ${i}: ${originalUri} -> ${targetPath}`);

        // 使用 copyFileSync 复制（更可靠，自动处理权限）
        try {
          fileIo.copyFileSync(originalUri, targetPath);
        } catch (copyErr) {
          hilog.warn(0x0000, 'HomePage', `copyFileSync failed for video ${i}, fallback to manual copy: ${JSON.stringify(copyErr)}`);
          let sourceFile = fileIo.openSync(originalUri, fileIo.OpenMode.READ_ONLY);
          let targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
          let bufferSize = 1024 * 1024;
          let buffer = new ArrayBuffer(bufferSize);
          let readLen: number = 0;
          while ((readLen = fileIo.readSync(sourceFile.fd, buffer)) > 0) {
            fileIo.writeSync(targetFile.fd, buffer, { length: readLen });
          }
          fileIo.closeSync(sourceFile);
          fileIo.closeSync(targetFile);
        }

        let stat = fileIo.statSync(targetPath);
        localVideoPaths.push(toFileUri(targetPath));
        hilog.info(0x0000, 'HomePage', `Video ${i} copied to sandbox: ${targetPath}, size=${stat.size}`);
      }

      // 等待文件系统同步
      await new Promise<void>((resolve) => {
        setTimeout(() => { resolve(); }, 100);
      });

      // 更新路径为沙箱文件URI(追加到已有选择)
      this.shareVideoPaths = this.shareVideoPaths.concat(localVideoPaths);
      this.shareVideoPath = this.shareVideoPaths[0];

      if (pickerUris.length > 1) {
        this.safeShowToast({ message: this.context.resourceManager.getStringSync($r('app.string.added_videos').id, pickerUris.length) });
      } else {
        this.safeShowToast({ message: $r('app.string.video_select_success') });
      }
      hilog.info(0x0000, 'HomePage', `Total videos copied: ${localVideoPaths.length}`);
    } catch (error) {
      hilog.error(0x0000, 'HomePage', `Video copy to sandbox failed: ${JSON.stringify(error)}`);
      // 降级：仍使用原始URI（可能无法分享）
      this.shareVideoPaths = pickerUris;
      this.shareVideoPath = pickerUris[0];
      this.safeShowToast({ message: $r('app.string.video_copy_to_sandbox_failed') });
    }
  }

  // 选择文件（复制到沙箱，确保分享时可被其他应用访问）
  private async selectFile(): Promise<void> {
    try {
      hilog.info(0x0000, 'HomePage', 'Start selecting file');
      const documentPicker = new picker.DocumentViewPicker();
      const options: picker.DocumentSelectOptions = {
        maxSelectNumber: 10,
        fileSuffixFilters: ['.*']
      };
      hilog.info(0x0000, 'HomePage', 'Calling documentPicker.select');
      const result = await documentPicker.select(options);
      hilog.info(0x0000, 'HomePage', `Document picker returned ${result.length} results`);
      if (!result || result.length === 0) {
        hilog.info(0x0000, 'HomePage', 'No file selected or user cancelled');
        return;
      }

      // 复制所有文件到沙箱目录（Picker URI 是临时的，不可分享）
      let localFilePaths: string[] = [];
      try {
        for (let i = 0; i < result.length; i++) {
          let originalUri = result[i];
          // 沙箱内保留原始文件名,分享出去不显示成sharefile_i_时间戳
          let originalName = this.extractFileNameFromUri(originalUri, 'sharefile_' + i + '_' + Date.now());
          let targetPath = this.uniqueSandboxPath(context.filesDir + '/share_tmp', originalName);

          hilog.info(0x0000, 'HomePage', `Copying file ${i}: ${originalUri} -> ${targetPath}`);

          // 使用 copyFileSync 复制（更可靠，自动处理权限）
          try {
            fileIo.copyFileSync(originalUri, targetPath);
          } catch (copyErr) {
            hilog.warn(0x0000, 'HomePage', `copyFileSync failed for file ${i}, fallback to manual copy: ${JSON.stringify(copyErr)}`);
            let sourceFile = fileIo.openSync(originalUri, fileIo.OpenMode.READ_ONLY);
            let targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
            let bufferSize = 1024 * 1024;
            let buffer = new ArrayBuffer(bufferSize);
            let readLen: number = 0;
            while ((readLen = fileIo.readSync(sourceFile.fd, buffer)) > 0) {
              fileIo.writeSync(targetFile.fd, buffer, { length: readLen });
            }
            fileIo.closeSync(sourceFile);
            fileIo.closeSync(targetFile);
          }

          let stat = fileIo.statSync(targetPath);
          localFilePaths.push(toFileUri(targetPath));
          hilog.info(0x0000, 'HomePage', `File ${i} copied to sandbox: ${targetPath}, size=${stat.size}`);
        }

        await new Promise<void>((resolve) => {
          setTimeout(() => { resolve(); }, 100);
        });

        this.shareFilePaths = this.shareFilePaths.concat(localFilePaths);
        this.shareFilePath = localFilePaths[0];

        if (result.length > 1) {
         this.safeShowToast({ message: this.context.resourceManager.getStringSync($r('app.string.added_files').id, result.length) });
        } else {
         this.safeShowToast({ message: $r('app.string.file_select_success') });
        }
      } catch (copyError) {
        hilog.error(0x0000, 'HomePage', `File copy to sandbox failed: ${JSON.stringify(copyError)}`);
        this.shareFilePaths = result;
        this.shareFilePath = result[0];
        this.safeShowToast({ message: $r('app.string.file_copy_to_sandbox_failed') });
      }
    } catch (err) {
      let error = err as BusinessError;
      hilog.error(0x0000, 'HomePage', `Failed to select file. code：${error.code}，message：${error.message}`);
      this.safeShowToast({ message: $r('app.string.file_select_failed') });
    }
  }

}