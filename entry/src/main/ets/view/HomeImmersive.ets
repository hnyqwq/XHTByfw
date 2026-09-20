import { TabDataModel } from '../model/TabDataModel';
import { TabViewModel } from '../viewmodel/TabViewModel';
import { HomePage } from '../pages/HomePage';
import { SecondPage } from '../pages/SecondPage';
import { MinePage } from '../pages/MinePage';
import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import type { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { common as abilityCommon } from '@kit.AbilityKit';
import { navigationManager } from '../common/NavigationManager';

const PREFERENCES_NAME = 'app_settings'; // 与 infoPage.ets 保持一致
const PLACEHOLDER_NAME = 'XHTB/HomePlaceholder';

@Component
export struct HomeImmersive {
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = 'sm';
  @Watch('onImmersiveTabChange')
  @StorageLink('isImmersiveTab') isImmersiveTab: boolean = true;
  @StorageLink('currentTabIndex') firstLevelIndex: number = 0;
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @State secondLevelIndex: number = 0;
  @State tabViewModel: TabViewModel = new TabViewModel();
  @State tabData: TabDataModel = this.tabViewModel.getTabMap();
  // 工具页(NavDestination)打开时隐藏底部悬浮Tab栏
  @StorageProp('toolPageActive') toolPageActive: boolean = false;
  // 工具页 onHidden 发出的栈变化信号,驱动重新计算 toolPageActive
  @Watch('onToolPageSyncTick')
  @StorageProp('toolPageSyncTick') toolPageSyncTick: number = 0;
  // 键盘弹出时隐藏悬浮Tab栏,页面避让交回系统默认OFFSET
  @StorageProp('keyboardVisible') keyboardVisible: boolean = false;
  private toolPageSyncTimer: number = -1;
  private controller: TabsController = new TabsController();
  private preferences: preferences.Preferences | null = null;
  private shortcutNavigateCallback = (url: string) => {
    console.info('HomeImmersive: 收到快捷方式导航事件, url=', url);
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
      console.error('HomeImmersive: Failed to subscribe shortcutNavigate event:', e);
    }

    // 从 Preferences 读取沉浸式Tab开关状态
    this.loadImmersiveTabSetting();

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

  // 从 Preferences 加载沉浸式Tab设置
  private async loadImmersiveTabSetting(): Promise<void> {
    try {
      const context = getContext(this) as abilityCommon.UIAbilityContext;
      this.preferences = await preferences.getPreferences(context, PREFERENCES_NAME);
      const savedValue = await this.preferences.get('isImmersiveTab', true) as boolean; // 默认开启沉浸式Tab
      this.isImmersiveTab = savedValue;
      AppStorage.setOrCreate('isImmersiveTab', savedValue);
      console.info('HomeImmersive: 从Preferences加载isImmersiveTab =', savedValue);
    } catch (err) {
      console.error('HomeImmersive: Failed to load immersive tab setting:', err);
      // 加载失败时使用默认值
      this.isImmersiveTab = true;
      AppStorage.setOrCreate('isImmersiveTab', true);
    }
  }

  aboutToDisappear(): void {
    try {
      const context = getContext(this) as abilityCommon.UIAbilityContext;
      context.eventHub.off('shortcutNavigate', this.shortcutNavigateCallback);
    } catch (e) {
      console.error('HomeImmersive: Failed to unsubscribe shortcutNavigate event:', e);
    }
  }

  checkShortcutNavigation(): void {
    const shortCutPage = AppStorage.get<string>('ShortCutPage');
    if (shortCutPage !== undefined && shortCutPage !== null && shortCutPage !== '') {
      console.info('HomeImmersive: 准备跳转到快捷方式页面, url=', shortCutPage);
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

  // 是否为平板模式（lg/xl断点）
  private isTabletMode(): boolean {
    return this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl';
  }

  onToolPageSyncTick(): void {
    this.scheduleToolPageSync();
  }

  // 沉浸开关切换会整树重建Tabs与SecondPage(NavPathStack变为新空栈),需重算toolPageActive避免悬浮Tab被旧标志收起
  onImmersiveTabChange(): void {
    console.info(`HomeImmersive: isImmersiveTab=${this.isImmersiveTab}, toolPageActive=${AppStorage.get<boolean>('toolPageActive')}, keyboardVisible=${AppStorage.get<boolean>('keyboardVisible')}, tablet=${this.isTabletMode()}`);
    this.scheduleToolPageSync();
  }

  // 防抖后按 NavPathStack 栈顶 + 当前Tab重算 toolPageActive,
  // 避免 push/pop 事件顺序不确定导致的标志位抖动
  private scheduleToolPageSync(): void {
    if (this.toolPageSyncTimer !== -1) {
      clearTimeout(this.toolPageSyncTimer);
    }
    this.toolPageSyncTimer = setTimeout(() => {
      this.toolPageSyncTimer = -1;
      this.syncToolPageActive();
    }, 60) as number;
  }

  private syncToolPageActive(): void {
    const stack = navigationManager.getNavPathStack();
    const names = stack ? stack.getAllPathName() : [];
    const top = names.length > 0 ? names[names.length - 1] : '';
    const tabIndex = AppStorage.get<number>('currentTabIndex') ?? 0;
    const active = top.length > 0 && top !== PLACEHOLDER_NAME && tabIndex === 0;
    AppStorage.setOrCreate('toolPageActive', active);
    console.info(`HomeImmersive: syncToolPageActive top=${top}, tab=${tabIndex}, active=${active}`);
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
    .width('100%')
    .height(!this.isImmersiveTab && this.isTabletMode() ? 100 : '100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    if (this.isImmersiveTab) {
      // 沉浸式Tab模式
      Tabs({ controller: this.controller, index: this.firstLevelIndex }) {
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
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .vertical(false)
      // 工具页打开时收起悬浮Tab栏(高度0),返回后恢复;键盘弹出时Tab栏浮在键盘上方;平板分栏工具列表常驻左栏,Tab保持可见
      .barHeight(this.toolPageActive && !this.isTabletMode() ? 0 : 56)
      .onChange((index: number) => {
        this.firstLevelIndex = index;
        AppStorage.setOrCreate('currentTabIndex', index);
        // 切出工具页所在Tab时立即恢复Tab栏,切回时按栈顶重新计算
        if (index !== 0) {
          AppStorage.setOrCreate('toolPageActive', false);
        } else {
          this.scheduleToolPageSync();
        }
      })
      .scrollable(false)
      .height('100%')
      .width('100%')
    } else if (this.isTabletMode()) {
      // 传统Tab模式 - 平板：左侧垂直Tab栏
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
      // 传统Tab模式 - 手机：底部Tab栏
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
