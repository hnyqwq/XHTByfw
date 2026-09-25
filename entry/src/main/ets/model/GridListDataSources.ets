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
  new GridItemInfo($r('app.string.sub_title1_value2'), 'XHTB/QRCodePage', undefined, $r('sys.symbol.wifi_router')),
];

export function getFeatureGridDataByUsage(): GridData {
  let tracker = UsageTracker.getInstance();
  if (!tracker.hasAnyUsage()) {
    return new GridData($r('app.string.sub_title1'), defaultFeatureItems);
  }
  let sorted = allToolItems.slice();
  sorted.sort((a: GridItemInfo, b: GridItemInfo): number => {
    let countA = tracker.getUsageCount(a.pageUrl);
    let countB = tracker.getUsageCount(b.pageUrl);
    return countB - countA;
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
