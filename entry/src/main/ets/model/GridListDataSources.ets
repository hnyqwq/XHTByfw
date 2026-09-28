import { UsageTracker } from '../common/utils/UsageTracker';

export class GridItemInfo {
  name: ResourceStr = '';
  pageUrl: string = '';
  symbol?: Resource;
  icon?: Resource;

  constructor(name: ResourceStr, pageUrl: string = '', icon?: Resource, symbol?: Resource) {
    this.name = name;
    this.pageUrl = pageUrl;
    this.icon = icon;
    this.symbol = symbol;
  }
}

export class GridData {
  groupName: ResourceStr = '';
  gridItemList: GridItemInfo[] = [];

  constructor(groupName: ResourceStr, gridItemList: GridItemInfo[]) {
    this.groupName = groupName;
    this.gridItemList = gridItemList;
  }
}

const allToolItems: GridItemInfo[] = [
  new GridItemInfo($r('app.string.sub_title2_value1'), 'XHTB/TextToSpeechPage', undefined, $r('sys.symbol.speaker_wave_2')),
  new GridItemInfo($r('app.string.sub_title2_value2'), 'XHTB/QRCodePage', undefined, $r('sys.symbol.qrcode')),
  new GridItemInfo($r('app.string.sub_title4_value1'), 'XHTB/TextTools/WordCountPage', undefined, $r('sys.symbol.doc_text')),
  new GridItemInfo($r('app.string.sub_title4_value2'), 'XHTB/TextTools/EncryptPage', undefined, $r('sys.symbol.lock')),
  new GridItemInfo($r('app.string.sub_title4_value3'), 'XHTB/TextTools/JsonFormatPage', undefined, $r('sys.symbol.list_square_bill')),
        new GridItemInfo($r('app.string.sub_title5_value1'), 'XHTB/ImageTools/ImageCompressPage', undefined, $r('sys.symbol.arrow_down')),
  new GridItemInfo($r('app.string.sub_title5_value2'), 'XHTB/ImageTools/ImageConvertPage', undefined, $r('sys.symbol.arrow_left_arrow_right')),
  new GridItemInfo($r('app.string.sub_title5_value3'), 'XHTB/ImageTools/ImageInfoPage', undefined, $r('sys.symbol.info_circle')),
  new GridItemInfo($r('app.string.sub_title7_value1'), 'XHTB/Utils/PasswordGeneratorPage', undefined, $r('sys.symbol.key')),
  new GridItemInfo($r('app.string.sub_title7_value2'), 'XHTB/Utils/ColorPickerPage', undefined, $r('sys.symbol.paintbrush')),
  new GridItemInfo($r('app.string.sub_title7_value3'), 'XHTB/Utils/StopwatchPage', undefined, $r('sys.symbol.stopwatch')),
];

const defaultFeatureItems: GridItemInfo[] = [
  new GridItemInfo($r('app.string.sub_title1_value1'), 'XHTB/TextToSpeechPage', undefined, $r('sys.symbol.speaker_wave_2')),
  // 名称/图标/路由必须一致:原先显示"网络认证工具"(sub_title1_value2)+wifi_router 图标但路由是 QRCodePage,
  // 且该功能并不存在于工具列表(AGC 审核问题),现改为真实存在的"生成二维码"
  new GridItemInfo($r('app.string.sub_title2_value2'), 'XHTB/QRCodePage', undefined, $r('sys.symbol.qrcode')),
];

export function getFeatureGridDataByUsage(): GridData {
  let tracker = UsageTracker.getInstance();
  if (!tracker.hasAnyUsage()) {
    return new GridData($r('app.string.sub_title1'), defaultFeatureItems);
  }
  let sorted = allToolItems.slice();
  // 常用功能按最近使用时间倒序:刚点的工具立即排到最左,只保留最近 4 个,
  // 更早使用的自动被挤掉(超出 4 个就去掉之前的)
  sorted.sort((a: GridItemInfo, b: GridItemInfo): number => {
    let tsA = tracker.getLastUsedTime(a.pageUrl);
    let tsB = tracker.getLastUsedTime(b.pageUrl);
    if (tsA !== tsB) {
      return tsB - tsA;
    }
    // 兜底:都没有时间戳时(旧版本数据)按使用次数排,行为与老版本一致
    return tracker.getUsageCount(b.pageUrl) - tracker.getUsageCount(a.pageUrl);
  });
  let topItems: GridItemInfo[] = [];
  for (let i = 0; i < sorted.length; i++) {
    if (tracker.getUsageCount(sorted[i].pageUrl) > 0 && topItems.length < 4) {
      topItems.push(sorted[i]);
    }
  }
  if (topItems.length === 0) {
    return new GridData($r('app.string.sub_title1'), defaultFeatureItems);
  }
  return new GridData($r('app.string.sub_title1'), topItems);
}

export const featureGridData: GridData = new GridData($r('app.string.sub_title1'), defaultFeatureItems);

export const
  otherGridDataList: GridData[] = [
    new GridData($r('app.string.sub_title2'),
      [
        new GridItemInfo($r('app.string.sub_title2_value1'), 'XHTB/TextToSpeechPage', undefined, $r('sys.symbol.speaker_wave_2')),
        new GridItemInfo($r('app.string.sub_title2_value2'), 'XHTB/QRCodePage', undefined, $r('sys.symbol.qrcode')),
        new GridItemInfo($r('app.string.sub_title4_value1'), 'XHTB/TextTools/WordCountPage', undefined, $r('sys.symbol.doc_text')),
        new GridItemInfo($r('app.string.sub_title4_value2'), 'XHTB/TextTools/EncryptPage', undefined, $r('sys.symbol.lock')),
        new GridItemInfo($r('app.string.sub_title4_value3'), 'XHTB/TextTools/JsonFormatPage', undefined, $r('sys.symbol.list_square_bill')),
      ]),
    new GridData($r('app.string.sub_title5'),
      [
  new GridItemInfo($r('app.string.sub_title5_value1'), 'XHTB/ImageTools/ImageCompressPage', undefined, $r('sys.symbol.arrow_down')),
        new GridItemInfo($r('app.string.sub_title5_value2'), 'XHTB/ImageTools/ImageConvertPage', undefined, $r('sys.symbol.arrow_left_arrow_right')),
        new GridItemInfo($r('app.string.sub_title5_value3'), 'XHTB/ImageTools/ImageInfoPage', undefined, $r('sys.symbol.info_circle')),
      ]),
    new GridData($r('app.string.sub_title7'),
      [
        new GridItemInfo($r('app.string.sub_title7_value1'), 'XHTB/Utils/PasswordGeneratorPage', undefined, $r('sys.symbol.key')),
        new GridItemInfo($r('app.string.sub_title7_value2'), 'XHTB/Utils/ColorPickerPage', undefined, $r('sys.symbol.paintbrush')),
        new GridItemInfo($r('app.string.sub_title7_value3'), 'XHTB/Utils/StopwatchPage', undefined, $r('sys.symbol.stopwatch')),
      ]),
  ];
