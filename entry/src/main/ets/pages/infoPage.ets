import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import router from '@ohos.router';

import { deviceInfo } from '@kit.BasicServicesKit';

import userAuth from '@ohos.userIAM.userAuth';
import { promptAction } from '@kit.ArkUI';

const TAG = 'User_Auth';

let deviceTypeInfo: string = deviceInfo.deviceType;
// 输出结果：the value of the deviceType is :wearable
console.info('the value of the deviceType is :' + deviceTypeInfo);

let brandInfo: string = deviceInfo.brand;
// 输出结果：the value of the brand is :HUAWEI
console.info('the value of the device brand is :' + brandInfo);

let productModelInfo: string = deviceInfo.productModel;
// 输出结果：the value of the productModel is :TAS-AL00
console.info('the value of the deviceInfo productModel is :' + productModelInfo);

let productModelAliasInfo: string = deviceInfo.productModelAlias;
console.info('the value of the deviceInfo productModelAlias is :' + productModelAliasInfo);

let osFullNameInfo: string = deviceInfo.osFullName;
// 输出结果：the value of the osFullName is :OpenHarmony-5.0.0.1
console.info('the value of the deviceInfo osFullName is :' + osFullNameInfo);

let sdkApiVersionInfo: number = deviceInfo.sdkApiVersion;
// 输出结果：the value of the sdkApiVersion is :12
console.info('the value of the deviceInfo sdkApiVersion is :' + sdkApiVersionInfo);

@Observed
  //设置条目信息构造
class FirstMenu {
  public uri?: string;
  public id: string; // 唯一id
  public title: string; // 标题文本
  public text: string; // 菜单文本
  public des: Resource; //后缀文本

  constructor(id: string, title: string, text: string, des: Resource) {
    this.id = id;
    this.title = title;
    this.text = text;
    this.des = des;
  }
}

@Observed
  //设置条目信息构造
class SecondMenu {
  public uri?: string;
  public id: string; // 唯一id
  public title: string; // 标题文本
  public text: string; // 菜单文本
  public des: Resource; //后缀文本

  constructor(id: string, title: string, text: string, des: Resource) {
    this.id = id;
    this.title = title;
    this.text = text;
    this.des = des;
  }
}

@Entry
@Component
export struct infoPage {
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  //设置条目信息数组
  @State FirstMenuGroup: FirstMenu[] = [
    //new FirstMenu('one', '型号名称', marketNameInfo, $r('app.string.void')),
    new FirstMenu('two', '型号代码', productModelInfo, $r('app.string.void')),
    //new FirstMenu('three', 'HarmonyOS 版本',distributionOSVersion, $r('app.string.void')),
    //new FirstMenu('four', '软件版本',fullVersionsr, $r('app.string.void')),
  //new FirstMenu('five', '序列号', '前往个人博客', $r('app.string.void'))
  ];
  @State SecondMenuGroup: SecondMenu[] = [
    //new SecondMenu('one', '型号名称', marketNameInfo, $r('app.string.void')),
    new SecondMenu('two', '型号代码', productModelInfo, $r('app.string.void')),
    //new SecondMenu('three', 'HarmonyOS 版本', distributionOSVersion, $r('app.string.void')),
    //new SecondMenu('four', '软件版本', fullVersionsr, $r('app.string.void')),
  //new SecondMenu('five', '序列号', '前往个人博客', $r('app.string.void'))
  ];
  @State message: string = '用户认证'
  @State userAuthResult?: userAuth.UserAuthResult = undefined

  build() {
    Scroll() {
      Column() {
        Navigation() {
          Stack() {
            Row() {
              Image($r('app.media.harmonyos'))
                .width('1100px')
                .height('1500px')
                .margin({ bottom: '3%' }) // 图片下方留白
            }
            .clip(true) // 如这里不设置clip为true，则Row组件的圆角不会限制其中的Image组件，Image组件的四个角会超出Row
            .borderRadius(20)

            Button('检查更新')
            //.type(ButtonType.Capsule)
              .width('50%')
              .height(40)
              .margin({ top: 220 })
              .onClick(() => {
                promptAction.showToast({ message: '切，让你点到爽 (ᗜ ˰ ᗜ)' });
              })

            Column() {
              Image($r('app.media.startIcon'))
                .width(60)
                .height(60)
              /*Text('hvideo')
                .fontWeight(700)
                .fontSize('16fp')
                .margin({ top: 10 })*/
              /*Text(versionSegsr)
                .fontWeight(600)
                .fontSize('20fp')
                .margin({ top: 10 })
                .opacity(0.7)
                .fontColor($r('app.color.version_color_182431'))*/
            }
            .alignItems(HorizontalAlign.Center)

          }
          .width('100%')
          .height(300)

          Column() {
            Row() {
              List() {
                ForEach(this.FirstMenuGroup, (item: FirstMenu) => {
                  ListItem() {
                    SettingItemView({ text: item.title, des: item.text });
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
              top: $r('app.integer.layout_size_12'), // 增加顶部间距
              bottom: $r('app.integer.layout_size_12')
            })
            .backgroundColor($r('app.color.color_info'));

            /*Row() {
              List() {
                ForEach(this.FirstMenuGroup, (item: FirstMenu) => {
                  ListItem() {
                    SettingItemView({ text: item.title, des: item.text });
                  }
                  .width('100%')
                },
                  (item: FirstMenu) => item.id.toString());
              }
              .divider({
                strokeWidth: $r('app.float.stroke_width'),
                color: $r('app.color.font_color_00000'),
                startMargin: $r('app.integer.layout_size_12'),
                endMargin: $r('app.integer.layout_size_24')
              });
            }
            .padding({ bottom: $r('app.integer.layout_size_5'), top: $r('app.integer.layout_size_5') })
            .width('90%')
            .borderRadius($r('app.integer.layout_size_24'))
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: $r('app.integer.layout_size_12') })
            .backgroundColor($r('app.color.font_color_FFFFFF'));*/
          }
          .width('100%')
          .layoutWeight(1);

          Column() {
            Text($r('app.string.copyright'))
              .fontSize(12);
          }
          .width('100%')
          .height(60);
        }
        .height('100%')
        .title($r('app.string.infopagetitle'))
        .titleMode(NavigationTitleMode.Mini)
        //.backgroundColor($r('app.color.listColor'))
        .backgroundColor($r('app.color.start_window_background'))
        .padding({ top: 50 })
      }
    }
    .scrollable(ScrollDirection.Vertical) // 设置垂直滚动方向
    .height('100%') // 必须设置高度为100%以撑满父容器
  }
}


@Component
  //设置条目布局
export struct SettingItemView {
  private text: string | Resource = ''; // 设置名称
  private des: string | Resource = ''; //后面的文本

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