import { TabDataModel } from '../model/TabDataModel';
import { TabViewModel } from '../viewmodel/TabViewModel';
import { HomePage } from '../pages/HomePage';
import { SecondPage } from '../pages/SecondPage';
import { MinePage } from '../pages/MinePage';
import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { common as abilityCommon } from '@kit.AbilityKit';

// 传统模式Home组件 - 不导入UIDesignKit，兼容所有API版本
@Component
export struct Home {
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = 'sm';
  @StorageLink('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageLink('currentTabIndex') firstLevelIndex: number = 0;
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @State secondLevelIndex: number = 0;
  @State tabViewModel: TabViewModel = new TabViewModel();
  @State tabData: TabDataModel = this.tabViewModel.getTabMap();
  private preferences: preferences.Preferences | null = null;
  private shortcutNavigateCallback = (url: string) => {
    console.info('Home: 收到快捷方式导航事件, url=', url);
    router.pushUrl({ url: url }).catch((err: Error) => {
      console.error('Failed to navigate to shortcut page:', err);
    });
  };

  aboutToAppear(): void {
    // 订阅快捷方式导航事件
    try {
      const context = getContext(this) as abilityCommon.UIAbilityContext;
      context.eventHub.on('shortcutNavigate', this.shortcutNavigateCallback);
    } catch (e) {
      console.error('Home: Failed to subscribe shortcutNavigate event:', e);
    }

    // 传统模式，强制设置isImmersiveTab为false
    AppStorage.setOrCreate('isImmersiveTab', false);
    console.info('Home: 传统模式 - isImmersiveTab = false');

    // 初始化当前Tab索引
    AppStorage.setOrCreate('currentTabIndex', 0);

    const initialTabIndex = AppStorage.get<number>('initialTabIndex');
    if (initialTabIndex !== undefined && initialTabIndex !== null) {
      AppStorage.setOrCreate('currentTabIndex', initialTabIndex);
      AppStorage.delete('initialTabIndex');
    }

    // 快捷方式跳转
    this.checkShortcutNavigation();

    // 接续跳转
    this.checkContinuationNavigation();
  }

  aboutToDisappear(): void {
    try {
      const context = getContext(this) as abilityCommon.UIAbilityContext;
      context.eventHub.off('shortcutNavigate', this.shortcutNavigateCallback);
    } catch (e) {
      console.error('Home: Failed to unsubscribe shortcutNavigate event:', e);
    }
  }

  checkShortcutNavigation(): void {
    const shortCutPage = AppStorage.get<string>('ShortCutPage');
    if (shortCutPage !== undefined && shortCutPage !== null && shortCutPage !== '') {
      console.info('Home: 准备跳转到快捷方式页面, url=', shortCutPage);
      setTimeout(() => {
        router.pushUrl({ url: shortCutPage }).catch((err: Error) => {
          console.error('Failed to navigate to shortcut page:', err);
        });
        AppStorage.delete('ShortCutPage');
      }, 100);
    }
  }

  checkContinuationNavigation(): void {
    const continuationPageUrl = AppStorage.get<string>('continuationPageUrl');
    if (continuationPageUrl !== undefined && continuationPageUrl !== null && continuationPageUrl !== '') {
      const continuationRouteParams = AppStorage.get<string>('continuationRouteParams');
      let params: Object | undefined = undefined;
      if (continuationRouteParams) {
        try {
          params = JSON.parse(continuationRouteParams);
        } catch (e) {
          console.error('Failed to parse continuation route params:', e);
        }
      }

      if (continuationPageUrl.startsWith('XHTB/')) {
        // XHTB 功能页已迁移到 Navigation，切换到工具页并由 SecondPage 消费恢复
        AppStorage.setOrCreate('currentTabIndex', 0);
        AppStorage.setOrCreate('pendingNavDestination', continuationPageUrl);
        AppStorage.delete('continuationPageUrl');
        AppStorage.delete('continuationRouteParams');
        return;
      }

      AppStorage.setOrCreate('isContinuation', true);

      setTimeout(() => {
        router.pushUrl({ url: continuationPageUrl, params: params }).catch((err: Error) => {
          console.error('Failed to navigate to continuation page:', err);
        });
        AppStorage.delete('continuationPageUrl');
        AppStorage.delete('continuationRouteParams');
      }, 100);
    }
  }

  getTabSymbol(index: number): Resource {
    switch (index) {
      case 0:
        return $r('sys.symbol.square_grid_2x2');
      case 1:
        return $r('sys.symbol.share');
      case 2:
        return $r('sys.symbol.person');
      default:
        return $r('sys.symbol.house');
    }
  }

  @Builder
  tabBuilder(name: string, index: number) {
    Column() {
      SymbolGlyph(this.getTabSymbol(index))
        .fontSize(24)
        .fontColor([index === this.firstLevelIndex ? $r('sys.color.brand') : $r('sys.color.icon_secondary')])
      Text(name)
        .fontSize(10)
        .fontWeight(500)
        .fontColor(index === this.firstLevelIndex ? '#0A59F7' : '#999999')
        .margin({ top: 4 })
    }
    .padding({
      bottom: (this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl') ? 24 : 0,
      left: 0,
      right: 0
    })
    .height((this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl') ? 100 : '100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    if (this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl') {
      // 平板模式：使用左侧垂直Tab栏
      Tabs({
        barPosition: BarPosition.Start,
        index: this.firstLevelIndex
      }) {
        TabContent() {
          SecondPage()
        }
        .tabBar(this.tabBuilder(this.tabData.getFirstList()[0], 0))

        TabContent() {
          HomePage()
        }
        .tabBar(this.tabBuilder(this.tabData.getFirstList()[1], 1))

        TabContent() {
          MinePage()
        }
        .tabBar(this.tabBuilder(this.tabData.getFirstList()[2], 2))
      }
      .barBackgroundColor($r('app.color.barBackgroundColor'))
      .barWidth(96)
      .barHeight('100%')
      .barMode(BarMode.Scrollable, { nonScrollableLayoutStyle: LayoutStyle.ALWAYS_CENTER })
      .barBackgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      .vertical(true)
      .onChange((index: number) => {
        this.firstLevelIndex = index;
        AppStorage.setOrCreate('currentTabIndex', index);
      })
      .scrollable(false)
      .height('100%')
      .width('100%')
    } else {
      // 手机模式：使用传统式底部Tab栏
      Tabs({
        barPosition: BarPosition.End,
        index: this.firstLevelIndex
      }) {
        TabContent() {
          SecondPage()
        }
        .tabBar(this.tabBuilder(this.tabData.getFirstList()[0], 0))

        TabContent() {
          HomePage()
        }
        .tabBar(this.tabBuilder(this.tabData.getFirstList()[1], 1))

        TabContent() {
          MinePage()
        }
        .tabBar(this.tabBuilder(this.tabData.getFirstList()[2], 2))
      }
      .barPosition(BarPosition.End)
      .vertical(false)
      .onChange((index: number) => {
        this.firstLevelIndex = index;
        AppStorage.setOrCreate('currentTabIndex', index);
      })
      .scrollable(false)
      .height('100%')
      .width('100%')
      .padding({ bottom: px2vp(this.bottomRectHeight) })
    }
  }
}
