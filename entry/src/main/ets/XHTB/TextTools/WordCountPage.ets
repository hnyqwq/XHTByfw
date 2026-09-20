import { GlobalInfoModel } from '../../common/GlobalInfoModel';
import { ToolPageTitleBar } from '../../components/ToolPageTitleBar';
import { KeyboardLiftScroll } from '../../common/utils/KeyboardLiftScroll';

interface WordCountResult {
  totalChars: number;
  charsNoSpace: number;
  chineseChars: number;
  englishWords: number;
  lines: number;
  paragraphs: number;
}

interface WordCountStatItem {
  label: ResourceStr;
  value: number;
}

@Component
export struct WordCountPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State inputText: string = '';
  @State countResult: WordCountResult = {
    totalChars: 0,
    charsNoSpace: 0,
    chineseChars: 0,
    englishWords: 0,
    lines: 0,
    paragraphs: 0
  };
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/TextTools/WordCountPage');
    AppStorage.delete('currentRouteParams');
  }

  private countWords(): void {
    let text = this.inputText;
    let totalChars = text.length;
    let charsNoSpace = text.replace(new RegExp('\\s', 'g'), '').length;
    let chineseMatch = text.match(new RegExp('[\\u4e00-\\u9fff]', 'g'));
    let chineseChars = chineseMatch !== null ? chineseMatch.length : 0;
    let englishText = text.replace(new RegExp('[\\u4e00-\\u9fff]', 'g'), ' ');
    let englishWords = 0;
    let englishMatch = englishText.match(new RegExp('[a-zA-Z]+', 'g'));
    if (englishMatch !== null) {
      englishWords = englishMatch.length;
    }
    let lines = text.length === 0 ? 0 : text.split(new RegExp('\\n')).length;
    let paras = text.length === 0 ? 0 : text.split(new RegExp('\\n\\s*\\n')).filter((s: string): boolean => s.trim().length > 0).length;
    if (paras === 0 && text.trim().length > 0) {
      paras = 1;
    }
    this.countResult = {
      totalChars: totalChars,
      charsNoSpace: charsNoSpace,
      chineseChars: chineseChars,
      englishWords: englishWords,
      lines: lines,
      paragraphs: paras
    };
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
      KeyboardLiftScroll({ scroller: this.scroller }) {
        Column({ space: 16 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolPageTitleBar({ title: $r('app.string.sub_title4_value1') })
          TextArea({ placeholder: $r('app.string.word_count_hint'), text: this.inputText })
            .id('kbLiftInput')
            .width('90%')
            .height(180)
            .onChange((value: string) => {
              this.inputText = value;
              this.countWords();
            })

          Column({ space: 12 }) {
            // 注意:@Builder必须按引用传递(对象字面量),按值传递不会随状态刷新
            this.statItem({ label: $r('app.string.word_count_total_chars'), value: this.countResult.totalChars })
            this.statItem({ label: $r('app.string.word_count_chars_no_space'), value: this.countResult.charsNoSpace })
            this.statItem({ label: $r('app.string.word_count_chinese'), value: this.countResult.chineseChars })
            this.statItem({ label: $r('app.string.word_count_english'), value: this.countResult.englishWords })
            this.statItem({ label: $r('app.string.word_count_lines'), value: this.countResult.lines })
            this.statItem({ label: $r('app.string.word_count_paragraphs'), value: this.countResult.paragraphs })
          }
          .width('90%')
          .padding(16)
          .borderRadius(12)
          .backgroundColor($r('app.color.second'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      }
      .height('100%')
    }
    .title($r('app.string.sub_title4_value1'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }

  @Builder
  statItem(item: WordCountStatItem) {
    Row() {
      Text(item.label)
        .fontSize(15)
        .fontColor($r('app.color.font_secondary'))
      Blank()
      Text(item.value.toString())
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
  }
}
