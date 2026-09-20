import { TITLE_BAR_HEIGHT_MINI } from '../common/utils/HdsToolNavUtil';

/**
 * 功能页沉浸式标题栏占位
 * 标题栏本体由HdsNavDestination的titleBar(HDS沉浸式渐变模糊)渲染,浮动于内容区之上,
 * 滚动内容从标题栏下方穿过;本组件放在滚动内容顶部,负责初始避让:
 * 沉浸开:状态栏高度+标题栏高度(宿主Navigation不避让状态栏,标题栏自行避让)
 * 沉浸关:仅标题栏高度(HDS标题栏默认浮动于内容区之上,内容同样会滚过标题栏)
 */
@Component
export struct ToolPageTitleBar {
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @Prop title: ResourceStr = '';

  build() {
    Blank()
      .height(this.isImmersiveTab ? px2vp(this.topRectHeight) + TITLE_BAR_HEIGHT_MINI : TITLE_BAR_HEIGHT_MINI)
      .width('100%')
  }
}
