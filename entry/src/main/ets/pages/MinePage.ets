import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { bundleManager } from '@kit.AbilityKit';
import { GlobalInfoModel } from '../common/GlobalInfoModel';
import dataPreferences from '@ohos.data.preferences';
import { uiMaterial } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';


@Observed
class SettingMenu {
  public uri?: string;
  public webUrl?: string;
  public id: string;
  public symbol: Resource;
  public text: Resource;
  public des: Resource | string;

  constructor(id: string, symbol: Resource, text: Resource, des: Resource | string, uri?: string, webUrl?: string) {
    this.id = id;
    this.symbol = symbol;
    this.text = text;
    this.des = des;
    this.uri = uri;
    this.webUrl = webUrl;
  }
}

// 应用信息（自 infoPage 搬入）
let bundleName = '';
let versionName = '';
try {
  const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
  bundleName = bundleInfo.name;
  versionName = bundleInfo.versionName;
} catch (err) {
  const error = err as BusinessError;
  console.error(`Failed to get bundle info. Code: ${error.code}, message: ${error.message}`);
  bundleName = 'yylx.hny.qwq';
  versionName = '1.0.0.0';
}
let banbenhao = `${versionName}`

const INVITE_URL = 'https://appgallery.huawei.com/apptest/8q2ifpJx0Qz';

@Entry
@Component
export struct MinePage {
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('isImmersiveTab')
  isImmersiveTab: boolean = false;

  private iconStr: ResourceStr = $r("app.media.CIcon");

  private preferences: dataPreferences.Preferences | null = null;

  // 沉浸式Tab栏样式开关（自 infoPage 挪入）
  async saveImmersiveTabSetting(value: boolean): Promise<void> {
    try {
      if (!this.preferences) {
        const context = getContext(this) as common.UIAbilityContext;
        this.preferences = await dataPreferences.getPreferences(context, 'app_settings');
      }
      await this.preferences.put('isImmersiveTab', value);
      await this.preferences.flush();
      this.isImmersiveTab = value;
      AppStorage.setOrCreate('isImmersiveTab', value);
    } catch (err) {
      console.error('Failed to save immersive tab setting:', err);
    }
  }

  private createUiMaterial(): uiMaterial.Material | undefined {
    try {
      return new uiMaterial.Material();
    } catch (err) {
      return undefined;
    }
  }

  private copyToClipboard(text: string): void {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(pasteData).then(() => {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copied_id') });
    }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_failed') });
    });
  }

  @Builder
  ImmersiveTabToggle() {
    Row() {
      Text($r('app.string.immersive_tab_style'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.font_color_info'))
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.isImmersiveTab })
        .selectedColor('#0A59F7')
        .onChange((isOn: boolean) => {
          this.saveImmersiveTabSetting(isOn);
        })
        .systemMaterial(this.createUiMaterial())
        .switchPointColor(Color.White)
    }
    .width('90%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .borderRadius(16)
    .backgroundColor($r('app.color.mine'))
  }

  @State menuGroup: SettingMenu[] = [
    new SettingMenu('invite', $r('sys.symbol.person_badge_plus'), $r('app.string.mine2'), INVITE_URL),
  ];

  @Builder
  MyMenu() {
    Menu() {
      MenuItem({ startIcon: this.iconStr, content: $r('app.string.meow') })
        .onClick(() => {
          let want: Want = {
            "action": "ohos.want.action.viewData",
            "entities": ["entity.system.browsable"],
            uri: 'https://www.chuckfang.com/MeoW/appLinking?channelId=0fd24620b27a4943bfe36e42b71df88d',
          }
          let context = getContext(this) as common.UIAbilityContext;
          context.startAbility(want)
          console.info(`MenuItem2 ability succeed`)
        })
    }
  }

  @Builder
  MyPreview() {
    Column() {
      Image($r('app.media.CIcon'))
        .width(200)
        .height(200)
    }
  }

  @Builder
  UserCard() {
    Row() {
      Row() {
        Image($r('app.media.CIcon'))
          .width(48)
          .height(48)
          .borderRadius(12)
          .bindContextMenu(this.MyMenu, ResponseType.LongPress,
            {
              preview: this.MyPreview,
              previewAnimationOptions: {
                hoverScale: [1.0, 0.95]
              }
            })
        Column() {
          Text($r('app.string.appname'))
            .fontWeight(700)
            .fontSize(16)
            .fontColor($r('app.color.font_color_info'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
           Text(banbenhao)
            .fontWeight(400)
            .fontSize(12)
            .fontColor($r('app.color.font_secondary'))
            .margin({ top: 2 })
        }
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .layoutWeight(1)

    }
    .width('90%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .borderRadius(16)
    .backgroundColor($r('app.color.mine'))
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Scroll() {
      Column() {
        Column() {
          this.UserCard()
          this.ImmersiveTabToggle()
        }
        .width('100%')
        .padding({ top: 8 })
        .alignItems(HorizontalAlign.Center)

        Column() {
          Row() {
            List() {
              ForEach(this.menuGroup,
                (item: SettingMenu) => {
                  ListItem() {
                    SettingItemView({ symbol: item.symbol, text: item.text, des: item.des,
                      subDes: item.id === 'invite' ? INVITE_URL : '' });
                  }
                  .width('100%')
                  .onClick(() => {
                    // 邀请测试:点击复制链接
                    this.copyToClipboard(INVITE_URL);
                  })
                },
                (item: SettingMenu) => item.id.toString());
            }
            .scrollBar(BarState.Auto)
            .divider({
              strokeWidth: $r('app.float.stroke_width'),
              color: $r('app.color.font_color_00000'),
              startMargin: $r('app.integer.layout_size_46'),
              endMargin: $r('app.integer.layout_size_24')
            });
          }
          .padding({ bottom: $r('app.integer.layout_size_5'), top: $r('app.integer.layout_size_5') })
          .width('90%')
          .borderRadius($r('app.integer.layout_size_24'))
          .alignItems(VerticalAlign.Center)
          .margin({ top: 20, bottom: 30 })
          .backgroundColor($r('app.color.mine'))
        }
        .width('100%');

        Column() {
          Text() {
            Span($r('app.string.appysxy'))
              .onClick(() => {
                // 元服务内暂无法跳转隐私协议页
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.privacy_jump_unavailable') });
              })
              .fontColor(Color.Blue)
              .fontSize(12);
          };

          Text($r('app.string.copyright'))
            .fontSize(12);
          Text() {
            Span('蜀ICP备2025142744号-3K')
              .onClick(() => {
                try {
                  let want: Want = {
                    "action": "ohos.want.action.viewData",
                    "entities": ["entity.system.browsable"],
                    uri: 'https://beian.miit.gov.cn',
                    "type": "text/plain"
                  }
                  let context = getContext(this) as common.UIAbilityContext;
                  context.startAbility(want)
                  console.info(`explicit start ability succeed`)
                } catch (error) {
                  console.info(`explicit start ability failed with ${error.code}`)
                }
              })
              .fontColor(Color.Blue)
              .fontSize(12);
          }
        }
        .width('100%')
        .height(80)
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 10, right: 10 });
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ top: Math.max(30 + px2vp(this.topRectHeight), 50), bottom: this.isImmersiveTab ? 84 : px2vp(this.bottomRectHeight) })
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }
}

@Component
export struct SettingItemView {
  @Prop symbol: Resource;
  @Prop text: string | Resource;
  @Prop des: string | Resource;
  @Prop subDes: string = '';

  build() {
    Row() {
      Row() {
        SymbolGlyph(this.symbol)
          .fontSize($r('app.integer.layout_size_22'))
          .fontColor([$r('sys.color.icon_primary')]);
        Column() {
          Text(this.text)
            .fontSize($r('app.integer.layout_size_16'))
            .fontWeight(400)
            .fontFamily('HarmonyHeiTi')
            .fontColor($r('sys.color.font_primary'))
            .lineHeight($r('app.integer.layout_size_22'));
          if (this.subDes.length > 0) {
            Text(this.subDes)
              .fontSize(11)
              .fontWeight(400)
              .fontFamily('HarmonyHeiTi')
              .fontColor($r('sys.color.font_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: $r('app.integer.layout_size_12') })
        .layoutWeight(1);

        Text(this.des)
          .opacity($r('app.float.opacity'))
          .fontSize($r('app.integer.layout_size_14'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('sys.color.font_secondary'))
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
    .alignSelf(ItemAlign.Center);
  }
}
