import { ListDataConstants } from '../constants/ListDataConstants';
import GridComponent from '../model/GridComponent';
import GridItemComponent from '../model/GridItemComponent';
import { featureGridData, GridData, GridItemInfo, otherGridDataList, getFeatureGridDataByUsage } from '../model/GridListDataSources';
import { navigationManager } from '../common/NavigationManager';
import { UsageTracker } from '../common/utils/UsageTracker';
import { common } from '@kit.AbilityKit';
import { TextToSpeechPage } from '../XHTB/TextToSpeechPage';
import { QRCodePage } from '../XHTB/QRCodePage';
import { Internet } from '../XHTB/Internet';
import { WordCountPage } from '../XHTB/TextTools/WordCountPage';
import { EncryptPage } from '../XHTB/TextTools/EncryptPage';
import { JsonFormatPage } from '../XHTB/TextTools/JsonFormatPage';
import { ImageCompressPage } from '../XHTB/ImageTools/ImageCompressPage';
import { ImageConvertPage } from '../XHTB/ImageTools/ImageConvertPage';
import { ImageInfoPage } from '../XHTB/ImageTools/ImageInfoPage';
import { IPQueryPage } from '../XHTB/NetTools/IPQueryPage';
import { LatencyTestPage } from '../XHTB/NetTools/LatencyTestPage';
import { HttpStatusPage } from '../XHTB/NetTools/HttpStatusPage';
import { PasswordGeneratorPage } from '../XHTB/Utils/PasswordGeneratorPage';
import { ColorPickerPage } from '../XHTB/Utils/ColorPickerPage';
import { StopwatchPage } from '../XHTB/Utils/StopwatchPage';
import { HomePlaceholderPage } from '../XHTB/HomePlaceholderPage';

const PLACEHOLDER_NAME = 'XHTB/HomePlaceholder';

@Component
struct SecondPageContent {
  @State currentIndex: number = 0;
  @State scrollPosition: number = 0;
  @State listPosition: number = 0;
  @Watch('onUsageUpdate')
  @StorageLink('usageVersion') usageVersion: number = 0;
  @StorageProp('currentWidthBreakpoint') currentWidthBreakpoint: string = 'sm';
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @State dynamicFeatureData: GridData = featureGridData;
  private scrollerForScroll: Scroller = new Scroller();
  private scrollerForList: Scroller = new Scroller();
  private titleScroller: Scroller = new Scroller();
  private isTabClicking: boolean = false;

  private bottomInset(): number {
    const split = this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl';
    return this.isImmersiveTab && !split ? 96 : 0;
  }

  onUsageUpdate(): void {
    this.dynamicFeatureData = getFeatureGridDataByUsage();
  }

  aboutToAppear(): void {
    this.dynamicFeatureData = getFeatureGridDataByUsage();
  }

  @Builder
  CategoryTabBar() {
    Row() {
      List({ space: 16, scroller: this.titleScroller }) {
        ForEach(ListDataConstants.TITLE_LIST, (item: string, index: number) => {
          ListItem() {
            Column() {
              Text(item)
                .fontColor(this.currentIndex === index ? $r('app.color.isChick_title_color') :
                  $r('app.color.noChick_title_color'))
                .fontSize(16)
                .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .margin({ top: 12 })

              if (this.currentIndex === index) {
                Divider()
                  .color($r('app.color.isChick_title_color'))
                  .strokeWidth(2)
                  .width(28)
                  .margin({ top: 7 })
              }
            }
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.isTabClicking = true;
              this.currentIndex = index;
              this.scrollerForList.scrollToIndex(index, true, ScrollAlign.START);
              this.scrollerForScroll.scrollEdge(Edge.Bottom);
              this.titleScroller.scrollToIndex(index, true, ScrollAlign.CENTER);
              setTimeout(() => {
                this.isTabClicking = false;
              }, 500);
            })
          }
        }, (item: string, index: number) => index + JSON.stringify(item))
      }
      .width('100%')
      .height(56)
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
    }
    .margin({ top: 12 })
    .padding({ left: 28, right: 28 })
  }

  build() {
    Column() {
      if (this.isImmersiveTab) {
        Blank().height(px2vp(this.topRectHeight)).width('100%')
      }
      Row() {
        Text($r('app.string.page_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
      }
      .width('100%')
      .height(44)
      .justifyContent(FlexAlign.Center)

      Stack({ alignContent: Alignment.Top }) {
        Scroll(this.scrollerForScroll) {
          Column() {
            Column() {
              Text($r('app.string.common_features'))
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.font_primary'))
                .margin({ top: 12, bottom: 8 })
                .padding({ left: 16, right: 16 })
                .width('100%')

              GridComponent({ gridData: this.dynamicFeatureData, columns: 4, itemH: 84, iconSize: 22, titleSize: 14, showTitle: false })
            }
            .width('100%')

            this.CategoryTabBar();

            List({ scroller: this.scrollerForList }) {
              ForEach(otherGridDataList, (item: GridData, index: number) => {
                ListItem() {
                  GridComponent({ gridData: item, columns: 2, itemH: 92, iconSize: 24, titleSize: 14, showTitle: true, isLastItem: index === otherGridDataList.length - 1 })
                }
              }, (item: GridData, index: number) => index + JSON.stringify(item))
              if (this.bottomInset() > 0) {
                ListItem() {
                  Column().height(this.bottomInset())
                }
              }
            }
            .width('100%')
            .edgeEffect(EdgeEffect.None)
            .scrollBar(BarState.Off)
            .onReachStart(() => {
              this.listPosition = 0;
            })
            .onReachEnd(() => {
              this.listPosition = 2;
            })
            .onScrollIndex((start: number) => {
              if (this.isTabClicking) {
                return;
              }
              const count = otherGridDataList.length;
              if (count === 0) {
                return;
              }
              const active = Math.min(Math.max(start, 0), count - 1);
              if (active !== this.currentIndex) {
                this.currentIndex = active;
                this.titleScroller.scrollToIndex(active, true, ScrollAlign.CENTER);
              }
            })
            .onScrollFrameBegin((offset: number) => {
              if (this.currentIndex === ListDataConstants.TITLE_LIST.length - 1 && offset > 0) {
                return { offsetRemain: 0 };
              }
              if (!((this.listPosition === 0 && offset < 0) ||
                (this.listPosition === 2 && offset > 0))) {
                this.listPosition = 1;
              }
              if (this.scrollPosition === 2 &&
                (this.listPosition !== 0 || offset > 0)) {
                return { offsetRemain: offset };
              } else {
                this.scrollerForScroll.scrollBy(0, offset);
                return { offsetRemain: offset };
              }
            })
            .width('100%')
            .height('calc(100% - 56vp)')
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .height('100%')
        .onWillScroll((yOffset: number) => {
          if (!((this.scrollPosition === 0 && yOffset < 0) ||
            (this.scrollPosition === 2 && yOffset > 0))) {
            this.scrollPosition = 1;
          }
        })
        .onScrollEdge((side: Edge) => {
          if (side === Edge.Top) {
            this.scrollPosition = 0;
          } else if (side === Edge.Bottom) {
            this.scrollPosition = 2;
          }
        })
        .onScrollFrameBegin((offset: number) => {
          if (this.scrollPosition === 2) {
            return { offsetRemain: 0 };
          } else {
            return { offsetRemain: offset };
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.White'))
  }
}

@Entry
@Component
export struct SecondPage {
  @Watch('onBreakpointChange')
  @StorageProp('currentWidthBreakpoint') currentBreakpoint: string = 'sm';
  // 工具页栈变化信号(NavDestination onHidden 触发),用于在栈清空后恢复分栏占位页
  @Watch('onToolStackChanged')
  @StorageProp('toolPageSyncTick') toolPageSyncTick: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  // 设置的沉浸开关:开启时Navigation不再整体避让状态栏,由工具列表与功能页标题栏自行避让
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  private pathStack: NavPathStack = new NavPathStack();

  private isSplitMode(): boolean {
    return this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl';
  }

  aboutToAppear() {
    let ctx = getContext(this) as common.UIAbilityContext;
    UsageTracker.getInstance().init(ctx);
    AppStorage.setOrCreate<number>('usageVersion', 0);
    navigationManager.setNavPathStack(this.pathStack);
    navigationManager.setUseNavigation(true);
    this.ensurePlaceholder();
    this.consumePendingNavDestination();
  }

  onBreakpointChange(): void {
    if (this.isSplitMode()) {
      this.ensurePlaceholder();
    } else if (this.pathStack.getAllPathName().includes(PLACEHOLDER_NAME)) {
      this.pathStack.removeByName(PLACEHOLDER_NAME);
    }
  }

  onToolStackChanged(): void {
    this.ensurePlaceholder();
  }

  // 分栏模式下栈为空时在右侧压入占位页,避免空白
  private ensurePlaceholder(): void {
    if (!this.isSplitMode()) {
      return;
    }
    const names = this.pathStack.getAllPathName();
    if (names.includes(PLACEHOLDER_NAME) || names.length > 0) {
      return;
    }
    this.pathStack.pushPathByName(PLACEHOLDER_NAME, '');
  }

  private consumePendingNavDestination(): void {
    let pending = AppStorage.get<string>('pendingNavDestination');
    if (pending) {
      AppStorage.delete('pendingNavDestination');
      AppStorage.delete('isContinuation');
      this.pathStack.pushPathByName(pending, '');
    }
  }

  build() {
    Navigation(this.pathStack) {
      SecondPageContent()
    }
    .mode(this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl'
      ? NavigationMode.Split : NavigationMode.Stack)
    .navBarWidth('40%')
    .navBarWidthRange([280, 520])
    .minContentWidth(320)
    .hideTitleBar(true)
    .hideBackButton(true)
    .navDestination(this.pageMap)
    .width('100%')
    .height('100%')
    // 沉浸光感标题栏必需:宿主Navigation忽略顶部安全区,工具页标题栏才能延伸到状态栏下(hny验收配方)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    // 沉浸开关开启时内容直达屏幕顶部,状态栏避让由页面标题栏自行处理
    .padding({ top: this.isImmersiveTab ? 0 : px2vp(this.topRectHeight) })
  }

  @Builder
  pageMap(name: string) {
    if (name === PLACEHOLDER_NAME) {
      HomePlaceholderPage()
    } else if (name === 'XHTB/TextToSpeechPage') {
      TextToSpeechPage()
    } else if (name === 'XHTB/QRCodePage') {
      QRCodePage()
   } else if (name === 'XHTB/Internet') {
      Internet()
    } else if (name === 'XHTB/TextTools/WordCountPage') {
      WordCountPage()
    } else if (name === 'XHTB/TextTools/EncryptPage') {
      EncryptPage()
    } else if (name === 'XHTB/TextTools/JsonFormatPage') {
      JsonFormatPage()
    } else if (name === 'XHTB/ImageTools/ImageCompressPage') {
      ImageCompressPage()
    } else if (name === 'XHTB/ImageTools/ImageConvertPage') {
      ImageConvertPage()
    } else if (name === 'XHTB/ImageTools/ImageInfoPage') {
      ImageInfoPage()
   } else if (name === 'XHTB/NetTools/IPQueryPage') {
      IPQueryPage()
    } else if (name === 'XHTB/NetTools/LatencyTestPage') {
      LatencyTestPage()
    } else if (name === 'XHTB/NetTools/HttpStatusPage') {
      HttpStatusPage()
    } else if (name === 'XHTB/Utils/PasswordGeneratorPage') {
      PasswordGeneratorPage()
    } else if (name === 'XHTB/Utils/ColorPickerPage') {
      ColorPickerPage()
    } else if (name === 'XHTB/Utils/StopwatchPage') {
      StopwatchPage()
    }
  }
}
