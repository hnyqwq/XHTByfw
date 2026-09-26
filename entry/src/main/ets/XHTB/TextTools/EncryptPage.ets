import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { ToolNavTitleBar } from '../../components/ToolNavTitleBar';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalInfoModel } from '../../common/GlobalInfoModel';
import { KeyboardLiftScroll } from '../../common/utils/KeyboardLiftScroll';

@Component
export struct EncryptPage {
  @StorageProp('isImmersiveTab') isImmersiveTab: boolean = false;
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State inputText: string = '';
  @State secretKey: string = '';
  @State resultText: string = '';
  @State isEncryptMode: boolean = true;
  @State isProcessing: boolean = false;
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/TextTools/EncryptPage');
    AppStorage.delete('currentRouteParams');
  }

  private async processText(): Promise<void> {
    if (!this.inputText || !this.secretKey) {
      this.resultText = '';
      return;
    }
    this.isProcessing = true;
    try {
      let textEncoder = new util.TextEncoder('utf-8');
      let inputBytes = textEncoder.encodeInto(this.inputText);
      let keyBytes = textEncoder.encodeInto(this.secretKey);
      let symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
      let keyLen = keyBytes.length;
      let paddedKey = new Uint8Array(32);
      for (let i = 0; i < 32; i++) {
        paddedKey[i] = i < keyLen ? keyBytes[i] : 0;
      }
      let keyBlob: cryptoFramework.DataBlob = { data: paddedKey };
      let symKey = await symKeyGenerator.convertKey(keyBlob);
      let cipher = cryptoFramework.createCipher('AES256|ECB|PKCS7');
      if (this.isEncryptMode) {
        await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, null);
        let inputBlob: cryptoFramework.DataBlob = { data: inputBytes };
        let output = await cipher.doFinal(inputBlob);
        let base64 = new util.Base64Helper();
        this.resultText = base64.encodeToStringSync(output.data);
      } else {
        await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, null);
        let base64 = new util.Base64Helper();
        let encryptedBytes = base64.decodeSync(this.inputText);
        let inputBlob: cryptoFramework.DataBlob = { data: encryptedBytes };
        let output = await cipher.doFinal(inputBlob);
        let textDecoder = new util.TextDecoder('utf-8');
        this.resultText = textDecoder.decodeToString(output.data);
      }
    } catch (e) {
      let err = e as BusinessError;
      this.resultText = $r('app.string.encrypt_error').toString() + ': ' + err.message;
    } finally {
      this.isProcessing = false;
    }
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
      KeyboardLiftScroll({ scroller: this.scroller }) {
        Column({ space: 16 }) {
          // HDS沉浸式标题栏占位:内容从标题栏下方滚过,此处留出初始避让空间
          ToolNavTitleBar({ title: $r('app.string.sub_title4_value2') })
          Row({ space: 12 }) {
            Button($r('app.string.encrypt_mode_encrypt'))
              .type(ButtonType.Capsule)
              .backgroundColor(this.isEncryptMode ? $r('app.color.brand') : Color.Gray)
              .fontColor(Color.White)
              .onClick(() => { this.isEncryptMode = true; this.resultText = ''; })
            Button($r('app.string.encrypt_mode_decrypt'))
              .type(ButtonType.Capsule)
              .backgroundColor(!this.isEncryptMode ? $r('app.color.brand') : Color.Gray)
              .fontColor(Color.White)
              .onClick(() => { this.isEncryptMode = false; this.resultText = ''; })
          }

          TextArea({ placeholder: $r('app.string.encrypt_input_hint'), text: this.inputText })
            .id('kbLiftInput')
            .width('90%')
            .height(120)
            .onChange((value: string) => { this.inputText = value; })

          TextInput({ placeholder: $r('app.string.encrypt_key_hint'), text: this.secretKey })
            .type(InputType.Password)
            .width('90%')
            .onChange((value: string) => { this.secretKey = value; })

          Button($r('app.string.encrypt_execute'))
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.brand'))
            .fontColor(Color.White)
            .width('90%')
            .enabled(!this.isProcessing)
            .onClick(() => { this.processText(); })

          if (this.resultText) {
            Column() {
              Text($r('app.string.encrypt_result'))
                .fontSize(14)
                .fontColor($r('app.color.font_secondary'))
                .margin({ bottom: 8 })
              Text(this.resultText)
                .fontSize(14)
                .copyOption(CopyOptions.LocalDevice)
                .width('100%')
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
