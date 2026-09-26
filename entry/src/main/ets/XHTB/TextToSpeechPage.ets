import { textToSpeech } from '@kit.CoreSpeechKit';//语音
import { ToolNavTitleBar } from '../components/ToolNavTitleBar';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalInfoModel } from '../common/GlobalInfoModel';
import { KeyboardLiftScroll } from '../common/utils/KeyboardLiftScroll';

let ttsEngine: textToSpeech.TextToSpeechEngine;

@Component
export struct TextToSpeechPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State originalText: string = ''; //语音
  @State createCount: number = 0;
  @State result: boolean = false;
  @State voiceInfo: string = '';
  @State text: string = '';
  @State textContent: string = '';
  @State utteranceId: string = '123456'
  @State illegalText: string = '';
  @StorageLink('isPlaying') isPlaying: boolean = false;
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    // 保存当前页面信息到 AppStorage,供接续功能使用
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/TextToSpeechPage');
    AppStorage.delete('currentRouteParams');
  }

  aboutToDisappear() {
    try {
      const isBusy = ttsEngine?.isBusy();
      if (isBusy) {
        ttsEngine?.stop();
        AppStorage.setOrCreate('isPlaying', false);
        ttsEngine?.shutdown();
      }
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`The ttsEngine invoke error, the code is ${error.code}, the message is ${error.message}`);
    }
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {

      KeyboardLiftScroll({ scroller: this.scroller, topAlign: true }) {
      Column({ space: 20 }) {
        // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
        ToolNavTitleBar({ title: $r('app.string.sub_title2_value1') })
        TextArea({ placeholder: $r('app.string.speak'), text: this.networkVideoSrc })
          .id('kbLiftInput')
          .margin({
            left: $r('sys.float.padding_level16'),
            right: $r('sys.float.padding_level16'),
          })
          .onChange((networkVideoSrc: string) => {
            this.networkVideoSrc = networkVideoSrc;
            AppStorage.set('networkVideoSrc', networkVideoSrc);
          })
        Text($r('app.string.ai_core_speech_support'))
          .padding({ top: 2 , left: 24, right: 24 })
          .fontSize(11)
          .maxFontScale(1.75)
          .width('100%')
          .fontColor($r('app.color.font_secondary'))
          .fontFamily('HarmonyHeiTi')
          .textAlign(TextAlign.Center)
        Row({ space: 40 }) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause') : $r('sys.symbol.play'))
              .fontSize(24)
              .fontColor([$r('sys.color.icon_primary')])
          }
            .margin({ top: 10 })
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              try {
                this.createByCallback();
              } catch (err) {
                const error: BusinessError = err as BusinessError;
                console.error(`CreateEngine error, the code is ${error.code}, the message is ${error.message}`);
              }
            })
            .width('40vp')

          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(24)
              .fontColor([$r('sys.color.icon_primary')])
          }
            .margin({ top: 10 })
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              try {
                ttsEngine?.stop();
                ttsEngine?.shutdown();
              } catch (err) {
                const error: BusinessError = err as BusinessError;
                console.error(`The ttsEngine invoke error, the code is ${error.code}, the message is ${error.message}`);
              }
              AppStorage.setOrCreate('isPlaying', false);
            })
            .width('40vp')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .constraintSize({ minHeight: '100%' })
      }
      }
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }

  createByCallback() {
      let extraParam: Record<string, string> = { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EngineName' };
      let initParamsInfo: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 0,
        online: 1,
        extraParams: extraParam
      };
      textToSpeech.createEngine(initParamsInfo,
        (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => {
          if (!err) {
            ttsEngine = textToSpeechEngine;
            this.createCount++;
            this.speak();
          } else {
            console.log('Fail to createEngine.');
          }
        });
  }

  speak() {
    let speakListener: textToSpeech.SpeakListener = {
      onStart(requestId: string, response: textToSpeech.StartResponse) {
        console.log('onStart');
        AppStorage.setOrCreate('isPlaying', true);
      },
      onComplete(requestId: string, response: textToSpeech.CompleteResponse) {
        console.log('onComplete');
        AppStorage.setOrCreate('isPlaying', true);
      },
      onStop(requestId: string, response: textToSpeech.StopResponse) {
        console.log('onStop');
        AppStorage.setOrCreate('isPlaying', false);
        ttsEngine?.shutdown();
      },
      onData(requestId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) {
        console.log('onData');
      },
      onError(requestId: string, errorCode: number, errorMessage: string) {
        console.log('onError');
        AppStorage.setOrCreate('isPlaying', false);
        ttsEngine?.shutdown();
      }
    };
    ttsEngine?.setListener(speakListener);
    let extraParam: Record<string, string | number> = {
      'queueMode': 0,
      'speed': 1,
      'volume': 2,
      'pitch': 1,
      'languageContext': 'zh-CN',
      'audioType': 'pcm',
      'soundChannel': 3,
      'playType': 1
    }
    let speakParams: textToSpeech.SpeakParams = {
      requestId: '123456-a',
      extraParams: extraParam
    };
      let aiPrefix: string = getContext(this).resourceManager.getStringSync($r('app.string.audio_generated_by_ai').id);
    let speakText: string = aiPrefix + this.networkVideoSrc;
    ttsEngine?.speak(speakText, speakParams);
  };
}