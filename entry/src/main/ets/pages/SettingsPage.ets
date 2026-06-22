import router from '@ohos.router';
import { NativeSshCore } from '../common/native/NativeSshCore';

@Entry
@Component
struct SettingsPage {
  @State nativeVersion: string = '';
  @State coreDescription: string = '';

  aboutToAppear(): void {
    this.nativeVersion = NativeSshCore.version();
    this.coreDescription = this.nativeVersion.indexOf('real-ssh') >= 0 ?
      '当前包已加载真实 libssh2 Core。HostKey、认证、shell、SFTP 和转发仍分别以端到端证据为准。' :
      '当前包使用明确的 Mock fallback，仅用于 UI/N-API 构建验证，不进行 SSH 网络连接。';
  }

  build() {
    Column() {
      Row() {
        Button('返回').onClick(() => router.back())
        Text('设置')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ left: 12 })
      }
      .padding(16)
      .width('100%')

      Column() {
        Text('Native Core')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width('100%')
        Text(this.nativeVersion)
          .fontColor('#38BDF8')
          .fontSize(13)
          .margin({ top: 8 })
          .width('100%')
        Text(this.coreDescription)
          .fontColor('#94A3B8')
          .fontSize(13)
          .margin({ top: 10 })
      }
      .padding(16)
      .margin({ left: 16, right: 16 })
      .backgroundColor('#172033')
      .borderRadius(14)

      Button('关于 OpenTabSsh')
        .margin(16)
        .onClick(() => router.pushUrl({ url: 'pages/AboutPage' }))
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B1020')
  }
}
