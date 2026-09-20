import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import dataPreferences from '@ohos.data.preferences';
import { bundleManager } from '@kit.AbilityKit';

import { deviceInfo } from '@kit.BasicServicesKit';

import { promptAction, LengthMetrics } from '@kit.ArkUI';
import { createUiMaterial } from '../common/utils/UIMaterialUtil';
import { GlobalInfoModel } from '../common/GlobalInfoModel';

// 获取应用信息
let bundleName = '';
let versionCode = 0;
let versionName = '';
try {
  const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
  bundleName = bundleInfo.name;
  versionCode = bundleInfo.versionCode;
  versionName = bundleInfo.versionName;
} catch (err) {
  const error = err as BusinessError;
  console.error(`Failed to get bundle info. Code: ${error.code}, message: ${error.message}`);
  // 提供默认值
  bundleName = 'yylx.hny.qwq';
  versionCode = 10000000;
  versionName = '1.0.0.0';
}

let baoming = `${bundleName}`
let banbenhao = `${versionName}（${versionCode}）`

// MINI模式标题栏固定高度（HDS规范值），沉浸式布局下内容需避让状态栏+标题栏
const TITLE_BAR_HEIGHT_MINI: number = 56;

let productModelInfo: string = deviceInfo.productModel;
// 输出结果：the value of the productModel is :TAS-AL00
console.info('the value of the deviceInfo productModel is :' + productModelInfo);

let sdkApiVersion: number = deviceInfo.sdkApiVersion;
// 输出结果：the value of the deviceInfo sdkApiVersion is :12
console.info('the value of the deviceInfo sdkApiVersion is :' + sdkApiVersion);


@Observed
  //设置条目信息构造
class FirstMenu {
  public uri?: string;
  public id: string; // 唯一id
  public title: Resource; // 标题文本
  public text: string; // 菜单文本
  public des: Resource; //后缀文本

  constructor(id: string, title: Resource, text: string, des: Resource) {
    this.id = id;
    this.title = title;
    this.text = text;
    this.des = des;
  }
}

@Entry
@Component
export struct infoPage {
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  @State isImmersiveTab: boolean = true; // 沉浸式Tab栏样式状态
  @State showNewYearCard: boolean = false; // 春节卡片开关状态，默认关闭
  @State isPhoneMultiDevice: boolean = true; // 手机多设备选择开关，默认开启
  private preferences: dataPreferences.Preferences | null = null;
  private scroller: Scroller = new Scroller();
  //设置条目信息数组
  @State FirstMenuGroup: FirstMenu[] = [
    new FirstMenu('two', $r('app.string.info2'), productModelInfo, $r('app.string.void'))
  ];

  // 系统能力信息数组
  @State SystemCapabilityMenuGroup: FirstMenu[] = [
    new FirstMenu('api_version', $r('app.string.api_version'), sdkApiVersion.toString(), $r('app.string.void'))
  ];

  aboutToAppear(): void {
    // 保存当前页面信息到 AppStorage,供接续功能使用
    AppStorage.setOrCreate('currentPageUrl', 'pages/infoPage');
    AppStorage.delete('currentRouteParams');

    // 加载沉浸式tab栏设置
    this.loadImmersiveTabSetting();
    // 加载春节卡片设置
    this.loadNewYearCardSetting();
    // 加载手机多设备选择设置
    this.loadPhoneMultiDeviceSetting();
  }

  async loadImmersiveTabSetting() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.preferences = await dataPreferences.getPreferences(context, 'app_settings');

      // 检查是否已经设置过
      const hasKey = await this.preferences.has('isImmersiveTab');

      // 读取保存的值
      let savedValue = false;
      if (hasKey) {
        savedValue = await this.preferences.get('isImmersiveTab', false) as boolean;
      }

      if (!hasKey) {
        // 首次运行，默认为true（沉浸式模式）
        savedValue = true;
        await this.preferences.put('isImmersiveTab', true);
        await this.preferences.flush();
        console.info('infoPage: 首次运行，默认使用沉浸式Tab栏');
      }

      // 读取保存的值
      this.isImmersiveTab = savedValue;
      // 同步到AppStorage，供Home页面使用
      AppStorage.setOrCreate('isImmersiveTab', this.isImmersiveTab);
    } catch (err) {
      console.error('Failed to load loadImmersiveTabSetting setting:', err);
    }
  }

  async loadNewYearCardSetting() {
    try {
      if (!this.preferences) {
        const context = getContext(this) as common.UIAbilityContext;
        this.preferences = await dataPreferences.getPreferences(context, 'app_settings');
      }

      // 检查是否已经设置过,如果没有则设置默认值为false
      const hasKey = await this.preferences.has('showNewYearCard');
      if (!hasKey) {
        await this.preferences.put('showNewYearCard', false);
        await this.preferences.flush();
      }

      // 读取保存的值
      this.showNewYearCard = await this.preferences.get('showNewYearCard', false) as boolean;
      // 同步到AppStorage，供Home页面使用
      AppStorage.setOrCreate('showNewYearCard', this.showNewYearCard);
    } catch (err) {
      console.error('Failed to load new year card setting:', err);
    }
  }

  async saveImmersiveTabSetting(value: boolean) {
    try {
      if (this.preferences) {
        await this.preferences.put('isImmersiveTab', value);
        await this.preferences.flush();
        this.isImmersiveTab = value;
        // 同步到AppStorage，供Home页面使用
        AppStorage.setOrCreate('isImmersiveTab', value);
      }
    } catch (err) {
      console.error('Failed to save immersive tab setting:', err);
    }
  }

  async saveNewYearCardSetting(value: boolean) {
    try {
      if (this.preferences) {
        await this.preferences.put('showNewYearCard', value);
        await this.preferences.flush();
        this.showNewYearCard = value;
        // 同步到AppStorage，供Home页面使用
        AppStorage.setOrCreate('showNewYearCard', value);
        console.info('Saved new year card setting:', value);
      }
    } catch (err) {
      console.error('Failed to save new year card setting:', err);
    }
  }

  async loadPhoneMultiDeviceSetting() {
    try {
      if (!this.preferences) {
        const context = getContext(this) as common.UIAbilityContext;
        this.preferences = await dataPreferences.getPreferences(context, 'app_settings');
      }

      const hasKey = await this.preferences.has('isPhoneMultiDevice');
      if (!hasKey) {
        // 首次运行，默认开启
        await this.preferences.put('isPhoneMultiDevice', true);
        await this.preferences.flush();
      }

      this.isPhoneMultiDevice = await this.preferences.get('isPhoneMultiDevice', true) as boolean;
      // 同步到AppStorage，供其他页面使用
      AppStorage.setOrCreate('isPhoneMultiDevice', this.isPhoneMultiDevice);
    } catch (err) {
      console.error('Failed to load phone multi-device setting:', err);
    }
  }

  async savePhoneMultiDeviceSetting(value: boolean) {
    try {
      if (this.preferences) {
        await this.preferences.put('isPhoneMultiDevice', value);
        await this.preferences.flush();
        this.isPhoneMultiDevice = value;
        // 同步到AppStorage，供其他页面使用
        AppStorage.setOrCreate('isPhoneMultiDevice', value);
        console.info('Saved phone multi-device setting:', value);
      }
    } catch (err) {
      console.error('Failed to save phone multi-device setting:', err);
    }
  }

  getTabStyleDescription(): string {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return this.isImmersiveTab
      ? context.resourceManager.getStringSync($r('app.string.immersive_style_on').id)
      : context.resourceManager.getStringSync($r('app.string.immersive_style_off').id);
  }

  getNewYearCardDescription(): string {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return this.showNewYearCard
      ? context.resourceManager.getStringSync($r('app.string.new_year_card_on').id)
      : context.resourceManager.getStringSync($r('app.string.new_year_card_off').id);
  }

  getPhoneMultiDeviceDescription(): string {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return this.isPhoneMultiDevice
      ? context.resourceManager.getStringSync($r('app.string.phone_multi_device_on').id)
      : context.resourceManager.getStringSync($r('app.string.phone_multi_device_off').id);
  }

  private openUrl(url: string, webUrl?: string): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      this.openWebUrl(url);
      return;
    }
    try {
      const canOpen: boolean = bundleManager.canOpenLink(url);
      if (canOpen) {
        ctx.openLink(url, { appLinkingOnly: false }).catch(() => {
          if (webUrl) { this.openWebUrl(webUrl); }
        });
      } else {
        if (webUrl) { this.openWebUrl(webUrl); }
      }
    } catch (e) {
      if (webUrl) { this.openWebUrl(webUrl); }
    }
  }

  private openWebUrl(url: string): void {
    const context = getContext(this) as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    };
    context.startAbility(want).catch((e: BusinessError) => {
      console.error(`网页跳转失败: ${e.code}`, e.message);
    });
  }

  build() {
    Column() {
      // 沉浸式Tab栏样式
      if (this.isImmersiveTab) {
        // 沉浸式模式：使用高版本 Material Design 3 API
        this.immersiveNavigation()
      } else {
        // 传统模式：不使用高版本 API
        this.traditionalNavigation()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }

  @Builder
  immersiveNavigation() {
    Navigation() {
      Scroll(this.scroller) {
        this.pageContent()
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
    .title($r('app.string.infopagetitle'))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    // 沉浸开关开启时内容直达屏幕顶部
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
  }
  @Builder
  traditionalNavigation() {
    Navigation() {
      Scroll(this.scroller) {
        this.pageContent()
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .title($r('app.string.infopagetitle'))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
  }

  @Builder
  pageContent() {
      Column() {
          Blank().height(px2vp(this.topRectHeight) + TITLE_BAR_HEIGHT_MINI).width('100%')
          Stack() {
            Row() {
              Image($r('app.media.harmonyos'))
                //.width('1100px')
                .height('1500px')
                .width('90%')
                .margin({ left: '5%', right: '5%' })
                .margin({ bottom: '3%' }) // 图片下方留白
                .draggable(false)
            }
            .clip(true) // 如这里不设置clip为true，则Row组件的圆角不会限制其中的Image组件，Image组件的四个角会超出Row
            .borderRadius(20)

            Column() {
              Image($r('app.media.CIcon'))
                .width(60)
                .height(60)
                .draggable(false)
              /*Text(versionSegsr)
                .fontWeight(700)
                .fontSize('16fp')
                .margin({ top: 10 })*/
              Text(banbenhao)
                .fontWeight(600)
                .fontSize('20fp')
                .margin({ top: 10 })
                .opacity(0.7)
                .fontColor($r('app.color.version_color_182431'))
            }
            .alignItems(HorizontalAlign.Center)

          }
          .width('100%')
          .height(300)

          // 沉浸式Tab栏样式 & 手机多设备选择
          Column() {
            // 第一行：沉浸式Tab栏样式开关
            Row() {
              Text($r('app.string.immersive_tab_style'))
                .fontSize($r('app.integer.layout_size_16'))
                .fontWeight(FontWeight.Bold)
                .fontFamily('HarmonyOS Sans')
                .fontColor($r('app.color.font_color_info'))
                .margin({ left: $r('app.integer.layout_size_5') })
                .layoutWeight(1)
                .lineHeight($r('app.integer.layout_size_22'));
              Text(this.getTabStyleDescription())
                .fontSize($r('app.integer.layout_size_14'))
                .fontColor($r('app.float.opacity'))
                .opacity(0.6)
                .margin({ right: 8 });
              Toggle({ type: ToggleType.Switch, isOn: this.isImmersiveTab })
                .selectedColor('#0A59F7')
                .onChange((isOn: boolean) => {
                  this.saveImmersiveTabSetting(isOn);
                })
                .systemMaterial(createUiMaterial())
                .switchPointColor(Color.White)
            }
            .width('100%')
            .height($r('app.integer.tabbar_height'))
            .padding({
              left: $r('app.integer.layout_size_22'),
              right: $r('app.integer.layout_size_12')
            })
            .alignItems(VerticalAlign.Center);

            Divider()
              .color($r('app.color.font_color_00000'))
              .strokeWidth(0.5)
              .margin({ left: $r('app.integer.layout_size_22'), right: $r('app.integer.layout_size_12') })

            // 第二行：手机多设备选择开关
            Row() {
              Text($r('app.string.phone_multi_device'))
                .fontSize($r('app.integer.layout_size_16'))
                .fontWeight(FontWeight.Bold)
                .fontFamily('HarmonyOS Sans')
                .fontColor($r('app.color.font_color_info'))
                .margin({ left: $r('app.integer.layout_size_5') })
                .layoutWeight(1)
                .lineHeight($r('app.integer.layout_size_22'));
              Text(this.getPhoneMultiDeviceDescription())
                .fontSize($r('app.integer.layout_size_14'))
                .fontColor($r('app.float.opacity'))
                .opacity(0.6)
                .margin({ right: 8 });
              Toggle({ type: ToggleType.Switch, isOn: this.isPhoneMultiDevice })
                .selectedColor('#0A59F7')
                .onChange((isOn: boolean) => {
                  this.savePhoneMultiDeviceSetting(isOn);
                })
                .systemMaterial(createUiMaterial())
                .switchPointColor(Color.White)
            }
            .width('100%')
            .height($r('app.integer.tabbar_height'))
            .padding({
              left: $r('app.integer.layout_size_22'),
              right: $r('app.integer.layout_size_12')
            })
            .alignItems(VerticalAlign.Center);
          }
          .width('90%')
          .alignSelf(ItemAlign.Center)
          .margin({
            top: $r('app.integer.layout_size_12'),
            bottom: $r('app.integer.layout_size_12')
          })
          .borderRadius($r('app.integer.layout_size_24'))
          .backgroundColor($r('app.color.info'));

          // 系统能力信息
          Column() {
            Row() {
              List() {
                ForEach(this.SystemCapabilityMenuGroup, (item: FirstMenu) => {
                  ListItem() {
                    SettingItemView({ text: item.title, des: item.text })
                  }
                  .width('100%')
                },
                  (item: FirstMenu) => item.id.toString());
              }
              .divider({
                strokeWidth: $r('app.float.stroke_width'),
                color: $r('app.color.font_color_00000'),
                startMargin: $r('app.integer.layout_size_24'),
                endMargin: $r('app.integer.layout_size_24')
              });
            }
            .padding({ bottom: $r('app.integer.layout_size_5'), top: $r('app.integer.layout_size_5') })
            .width('90%')
            .borderRadius($r('app.integer.layout_size_24'))
            .alignItems(VerticalAlign.Center)
            .margin({
              bottom: $r('app.integer.layout_size_12')
            })
            .backgroundColor($r('app.color.info'));
          }

          Column() {
            Row() {
              List() {
                ForEach(this.FirstMenuGroup, (item: FirstMenu) => {
                  ListItem() {
                    SettingItemView({ text: item.title, des: item.text })
                  }
                  .width('100%')
                },
                  (item: FirstMenu) => item.id.toString());
              }
              .divider({
                strokeWidth: $r('app.float.stroke_width'),
                color: $r('app.color.font_color_00000'),
                startMargin: $r('app.integer.layout_size_24'),
                endMargin: $r('app.integer.layout_size_24')
              });
            }
            .padding({ bottom: $r('app.integer.layout_size_5'), top: $r('app.integer.layout_size_5') })
            .width('90%')
            .borderRadius($r('app.integer.layout_size_24'))
            .alignItems(VerticalAlign.Center)
            .margin({
              bottom: $r('app.integer.layout_size_12')
            })
            .backgroundColor($r('app.color.info'));
          }
          .width('100%');

          // 春节卡片开关
          Row() {
            Row() {
              Text($r('app.string.show_newyear_card'))
                .fontSize($r('app.integer.layout_size_16'))
                .fontWeight(FontWeight.Bold)
                .fontFamily('HarmonyOS Sans')
                .fontColor($r('app.color.font_color_info'))
                .margin({ left: $r('app.integer.layout_size_5') })
                .layoutWeight(1)
                .lineHeight($r('app.integer.layout_size_22'));
              Text(this.getNewYearCardDescription())
                .fontSize($r('app.integer.layout_size_14'))
                .fontColor($r('app.float.opacity'))
                .opacity(0.6)
                .margin({ right: 8 });
              Toggle({ type: ToggleType.Switch, isOn: this.showNewYearCard })
                .selectedColor('#0A59F7')
                .onChange((isOn: boolean) => {
                  this.saveNewYearCardSetting(isOn);
                })
                .systemMaterial(createUiMaterial())
                .switchPointColor(Color.White)
            }
            .width('100%')
            .height($r('app.integer.tabbar_height'))
            .padding({
              left: $r('app.integer.layout_size_22'),
              right: $r('app.integer.layout_size_12')
            })
            .alignItems(VerticalAlign.Center);
          }
          .width('90%')
          .height($r('app.integer.layout_size_48'))
          .alignSelf(ItemAlign.Center)
          .margin({
            bottom: $r('app.integer.layout_size_12')
          })
          .borderRadius($r('app.integer.layout_size_24'))
          .backgroundColor($r('app.color.info'));


          Column() {
            Text(baoming)
              .fontSize(12);
          }
          .width('100%')
          .height(60)
          .alignItems(HorizontalAlign.Center)
          .margin({ top: $r('app.integer.layout_size_12') })
          .padding({ bottom: px2vp(this.bottomRectHeight) })
        }
        .width('100%')
        .padding({ bottom: 20 })
  }
}

@Component
//设置条目布局
struct SettingItemView {
  @Prop text: string | Resource = ''; // 设置名称
  @Prop des: string | Resource = ''; //后面的文本

  build() {
    Row() {
      Row() {
        Text(this.text)
          .fontSize($r('app.integer.layout_size_16'))
          .fontWeight(400)
          .fontFamily('HarmonyOS Sans')
          .fontColor($r('app.color.font_color_info'))
          .margin({ left: $r('app.integer.layout_size_5') })
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .lineHeight($r('app.integer.layout_size_22'));
        Text(this.des)
          .opacity($r('app.float.opacity'))
          .fontSize($r('app.integer.layout_size_14'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('app.color.font_color_info'))
          .margin({ right: $r('app.integer.layout_size_12') })
          .lineHeight($r('app.integer.layout_size_19'));
      }
      .width('100%')
      .height($r('app.integer.tabbar_height'))
      .padding({
        left: $r('app.integer.layout_size_22'),
        right: $r('app.integer.layout_size_12')
      })
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .height($r('app.integer.layout_size_48'))
    .alignSelf(ItemAlign.Center);
  }
}