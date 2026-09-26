import { GlobalInfoModel } from '../../common/GlobalInfoModel';
import { ToolNavTitleBar } from '../../components/ToolNavTitleBar';
import { KeyboardLiftScroll } from '../../common/utils/KeyboardLiftScroll';

interface LapRecord {
  index: number;
  elapsed: number;
}

@Component
export struct StopwatchPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State isCountdown: boolean = false;
  @State countdownMinutes: number = 5;
  @State countdownSeconds: number = 0;
  @State elapsedMs: number = 0;
  @State isRunning: boolean = false;
  @State laps: LapRecord[] = [];
  private timerId: number = -1;
  private startTimestamp: number = 0;
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/Utils/StopwatchPage');
    AppStorage.delete('currentRouteParams');
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
  }

  private startTimer(): void {
    this.startTimestamp = Date.now() - this.elapsedMs;
    this.isRunning = true;
    this.timerId = setInterval(() => {
      this.elapsedMs = Date.now() - this.startTimestamp;
      if (this.isCountdown) {
        let totalMs = (this.countdownMinutes * 60 + this.countdownSeconds) * 1000;
        let remaining = totalMs - this.elapsedMs;
        if (remaining <= 0) {
          this.elapsedMs = totalMs;
          this.stopTimer();
        }
      }
    }, 50);
  }

  private stopTimer(): void {
    this.isRunning = false;
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private resetTimer(): void {
    this.stopTimer();
    this.elapsedMs = 0;
    this.laps = [];
  }

  private addLap(): void {
    this.laps = [{ index: this.laps.length + 1, elapsed: this.elapsedMs }, ...this.laps];
  }

  private formatTime(ms: number): string {
    let totalSeconds = Math.floor(ms / 1000);
    let minutes = Math.floor(totalSeconds / 60);
    let seconds = totalSeconds % 60;
    let centiseconds = Math.floor((ms % 1000) / 10);
    return minutes.toString().padStart(2, '0') + ':' + seconds.toString().padStart(2, '0') + '.' + centiseconds.toString().padStart(2, '0');
  }

  private getDisplayTime(): number {
    if (this.isCountdown) {
      let totalMs = (this.countdownMinutes * 60 + this.countdownSeconds) * 1000;
      let remaining = totalMs - this.elapsedMs;
      return remaining > 0 ? remaining : 0;
    }
    return this.elapsedMs;
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
      KeyboardLiftScroll({ scroller: this.scroller, topAlign: true }) {
      Column({ space: 20 }) {
        // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
        ToolNavTitleBar({ title: $r('app.string.sub_title7_value3') })
        Row({ space: 12 }) {
          Button($r('app.string.stopwatch_countup'))
            .type(ButtonType.Capsule)
            .backgroundColor(!this.isCountdown ? $r('app.color.brand') : Color.Gray)
            .fontColor(Color.White)
            .onClick(() => { this.resetTimer(); this.isCountdown = false; })
          Button($r('app.string.stopwatch_countdown'))
            .type(ButtonType.Capsule)
            .backgroundColor(this.isCountdown ? $r('app.color.brand') : Color.Gray)
            .fontColor(Color.White)
            .onClick(() => { this.resetTimer(); this.isCountdown = true; })
        }

        if (this.isCountdown && !this.isRunning && this.elapsedMs === 0) {
          Row({ space: 8 }) {
            Column() {
              Text($r('app.string.stopwatch_minutes'))
                .fontSize(12)
                .fontColor($r('app.color.font_secondary'))
              TextInput({ text: this.countdownMinutes.toString() })
                .id('kbLiftInput')
                .type(InputType.Number)
                .width(80)
                .textAlign(TextAlign.Center)
                .onChange((v: string) => { this.countdownMinutes = parseInt(v) || 0; })
            }
            Text(':')
              .fontSize(24)
              .margin({ top: 16 })
            Column() {
              Text($r('app.string.stopwatch_seconds'))
                .fontSize(12)
                .fontColor($r('app.color.font_secondary'))
              TextInput({ text: this.countdownSeconds.toString() })
                .type(InputType.Number)
                .width(80)
                .textAlign(TextAlign.Center)
                .onChange((v: string) => { this.countdownSeconds = parseInt(v) || 0; })
            }
          }
        }

        Text(this.formatTime(this.getDisplayTime()))
          .fontSize(56)
          .fontWeight(FontWeight.Bold)
          .fontFamily('monospace')

        Row({ space: 16 }) {
          if (!this.isRunning) {
            Button($r('app.string.stopwatch_start'))
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.brand'))
              .fontColor(Color.White)
              .onClick(() => { this.startTimer(); })
          } else {
            Button($r('app.string.stopwatch_stop'))
              .type(ButtonType.Capsule)
              .backgroundColor(Color.Red)
              .fontColor(Color.White)
              .onClick(() => { this.stopTimer(); })
          }
          Button($r('app.string.stopwatch_reset'))
            .type(ButtonType.Capsule)
            .backgroundColor(Color.Gray)
            .fontColor(Color.White)
            .onClick(() => { this.resetTimer(); })
          if (this.isRunning && !this.isCountdown) {
            Button($r('app.string.stopwatch_lap'))
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.brand'))
              .fontColor(Color.White)
              .onClick(() => { this.addLap(); })
          }
        }

        if (this.laps.length > 0) {
          Column({ space: 4 }) {
            ForEach(this.laps, (item: LapRecord) => {
              Row() {
                Text($r('app.string.stopwatch_lap'))
                  .fontSize(14)
                  .fontColor($r('app.color.font_secondary'))
                Text(' ' + item.index.toString())
                  .fontSize(14)
                  .fontColor($r('app.color.font_secondary'))
                Blank()
                Text(this.formatTime(item.elapsed))
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontFamily('monospace')
              }
              .width('100%')
              .padding({ top: 6, bottom: 6 })
            }, (item: LapRecord) => item.index.toString())
          }
          .width('90%')
          .padding(16)
          .borderRadius(12)
          .backgroundColor($r('app.color.second'))
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      }
      }
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }
}
