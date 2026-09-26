import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { ToolNavTitleBar } from '../../components/ToolNavTitleBar';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalInfoModel } from '../../common/GlobalInfoModel';

@Component
export struct PasswordGeneratorPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State passwordLength: number = 16;
  @State includeUppercase: boolean = true;
  @State includeLowercase: boolean = true;
  @State includeNumbers: boolean = true;
  @State includeSymbols: boolean = true;
  @State generatedPassword: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/Utils/PasswordGeneratorPage');
    AppStorage.delete('currentRouteParams');
    this.generatePassword();
  }

  private async generatePassword(): Promise<void> {
    let chars = '';
    if (this.includeLowercase) {
      chars += 'abcdefghijklmnopqrstuvwxyz';
    }
    if (this.includeUppercase) {
      chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    }
    if (this.includeNumbers) {
      chars += '0123456789';
    }
    if (this.includeSymbols) {
      chars += '!@#$%^&*()_+-=[]{}|;:,.<>?';
    }
    if (chars.length === 0) {
      this.generatedPassword = '';
      return;
    }
    try {
      let random = cryptoFramework.createRandom();
      let result = await random.generateRandom(this.passwordLength);
      let randomBytes = result.data;
      let password = '';
      for (let i = 0; i < this.passwordLength; i++) {
        let idx = randomBytes[i] % chars.length;
        password += chars[idx];
      }
      this.generatedPassword = password;
    } catch (e) {
      let err = e as BusinessError;
      let password = '';
      for (let i = 0; i < this.passwordLength; i++) {
        let idx = Math.floor(Math.random() * chars.length);
        password += chars[idx];
      }
      this.generatedPassword = password;
    }
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
      Scroll(this.scroller) {
        Column({ space: 16 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolNavTitleBar({ title: $r('app.string.sub_title7_value1') })
          if (this.generatedPassword) {
            Text(this.generatedPassword)
              .fontSize(18)
              .fontFamily('monospace')
              .copyOption(CopyOptions.LocalDevice)
              .padding(16)
              .borderRadius(12)
              .backgroundColor($r('app.color.second'))
              .width('90%')
              .textAlign(TextAlign.Center)
              .wordBreak(WordBreak.BREAK_ALL)
          }

          Column({ space: 8 }) {
            Text(getContext(this).resourceManager.getStringSync($r('app.string.password_gen_length')) + ': ' + this.passwordLength)
              .fontSize(14)
            Slider({
              value: this.passwordLength,
              min: 4,
              max: 64,
              step: 1,
              style: SliderStyle.InSet
            })
              .width('100%')
              .onChange((value: number) => { this.passwordLength = value; })
          }
          .width('90%')

          Column({ space: 8 }) {
            Row() {
              Text($r('app.string.password_gen_uppercase'))
                .fontSize(14)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.includeUppercase })
                .onChange((isOn: boolean) => { this.includeUppercase = isOn; })
            }
            .width('100%')
            Row() {
              Text($r('app.string.password_gen_lowercase'))
                .fontSize(14)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.includeLowercase })
                .onChange((isOn: boolean) => { this.includeLowercase = isOn; })
            }
            .width('100%')
            Row() {
              Text($r('app.string.password_gen_numbers'))
                .fontSize(14)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.includeNumbers })
                .onChange((isOn: boolean) => { this.includeNumbers = isOn; })
            }
            .width('100%')
            Row() {
              Text($r('app.string.password_gen_symbols'))
                .fontSize(14)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.includeSymbols })
                .onChange((isOn: boolean) => { this.includeSymbols = isOn; })
            }
            .width('100%')
          }
          .width('90%')
          .padding(16)
          .borderRadius(12)
          .backgroundColor($r('app.color.second'))

          Button($r('app.string.password_gen_execute'))
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.brand'))
            .fontColor(Color.White)
            .width('90%')
            .onClick(() => { this.generatePassword(); })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      }
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .onShown(() => { AppStorage.setOrCreate('toolPageActive', true); })
    .onHidden(() => { AppStorage.setOrCreate('toolPageSyncTick', Date.now()); })
  }
}
