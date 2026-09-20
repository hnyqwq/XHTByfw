import { common, Want, bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { navigationManager } from '../common/NavigationManager';
import { GlobalInfoModel } from '../common/GlobalInfoModel';


@Observed
class SettingMenu {
  public uri?: string;
  public webUrl?: string;
  public id: string;
  public symbol: Resource;
  public text: Resource;
  public des: Resource;

  constructor(id: string, symbol: Resource, text: Resource, des: Resource, uri?: string, webUrl?: string) {
    this.id = id;
    this.symbol = symbol;
    this.text = text;
    this.des = des;
    this.uri = uri;
    this.webUrl = webUrl;
  }
}

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

  private openUrl(url: string, webUrl?: string, context?: common.UIAbilityContext): void {
    const ctx = context || getContext(this) as common.UIAbilityContext;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: url
      };
      ctx.startAbility(want).catch((e: BusinessError) => {
        console.error(`网页跳转失败: ${e.code}`, e.message);
      });
      return;
    }

    try {
      const canOpen: boolean = bundleManager.canOpenLink(url);
      if (canOpen) {
        ctx.openLink(url, { appLinkingOnly: false }).catch(() => {
          if (webUrl) {
            this.openWebUrl(webUrl, ctx);
          }
        });
      } else {
        if (webUrl) {
          this.openWebUrl(webUrl, ctx);
        } else {
          console.warn(`无法打开URL: ${url}，且无备用网页`);
        }
      }
    } catch (e) {
      console.error(`URL跳转异常:`, e);
      if (webUrl) {
        this.openWebUrl(webUrl, ctx);
      }
    }
  }

  private openWebUrl(url: string, context: common.UIAbilityContext): void {
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    };
    context.startAbility(want).catch((e: BusinessError) => {
      console.error(`网页跳转失败: ${e.code}`, e.message);
    });
  }

  private iconStr: ResourceStr = $r("app.media.CIcon");

  @State menuGroup: SettingMenu[] = [
    new SettingMenu('setting', $r('sys.symbol.gearshape'), $r('app.string.mine1'), $r('app.string.void')),
    new SettingMenu('vipownsetting', $r('sys.symbol.person_badge_plus'), $r('app.string.mine2'), $r('app.string.void'),
      'https://appgallery.huawei.com/apptest/8q2ifpJx0Qz'),
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
           Text($r('app.string.login_hint'))
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
                    SettingItemView({ symbol: item.symbol, text: item.text, des: item.des });
                  }
                  .width('100%')
                  .onClick(() => {
                    const context = getContext(this) as common.UIAbilityContext;
                    if (item.id === 'setting') {
                      navigationManager.pushPath('pages/infoPage');
                      return;
                    }
                    if (item.uri) {
                      this.openUrl(item.uri, item.webUrl, context);
                    }
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
                try {
                  let want: Want = {
                    "action": "ohos.want.action.viewData",
                    "entities": ["entity.system.browsable"],
                    uri: 'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=2033827646390939584',
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
          };

          Text($r('app.string.copyright'))
            .fontSize(12);
          Text() {
            Span('蜀ICP备2025142744号-2A')
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
    .padding({ top: 30 + px2vp(this.topRectHeight), bottom: px2vp(this.bottomRectHeight) + (this.isImmersiveTab ? 84 : 0) })
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

  build() {
    Row() {
      Row() {
        SymbolGlyph(this.symbol)
          .fontSize($r('app.integer.layout_size_22'))
          .fontColor([$r('sys.color.icon_primary')]);
        Text(this.text)
          .fontSize($r('app.integer.layout_size_16'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('sys.color.font_primary'))
          .margin({ left: $r('app.integer.layout_size_12') })
          .layoutWeight(1)
          .lineHeight($r('app.integer.layout_size_22'));

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
    .height($r('app.integer.layout_size_48'))
    .alignSelf(ItemAlign.Center);
  }
}
