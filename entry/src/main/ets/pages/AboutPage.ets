import router from '@ohos.router';
import { NativeSshCore } from '../common/native/NativeSshCore';

@Entry
@Component
struct AboutPage {
  @State nativeVersion: string = '';

  aboutToAppear(): void {
    this.nativeVersion = NativeSshCore.version();
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(34).fontColor('#111827').width(44).onClick(() => router.back())
        Text('关于').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#111827')
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(44)
      }
      .width('100%').height(64).padding({ left: 14, right: 14, top: 8 })

      Column({ space: 8 }) {
        Text('OpenTabSsh').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#111827')
        Text('HarmonyOS 原生 SSH 工具').fontSize(15).fontColor('#64748B')
        Text(this.nativeVersion).fontSize(12).fontColor('#0A84FF').margin({ top: 4 })
      }
      .width('92%').padding(20).backgroundColor(Color.White).borderRadius(18).margin({ top: 12 })

      Column({ space: 10 }) {
        Text('开发目标').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#111827').width('100%')
        Text('对齐 TabSSH Android 的多标签终端、HostKey 验证、密码/私钥认证、SFTP、端口转发、重连与安全清理。')
          .fontSize(14).fontColor('#64748B').width('100%')
        Text('当前仍未完成：SFTP 写操作、三类端口转发、完整 xterm 渲染、重连退避和 arm64 真机验证。')
          .fontSize(13).fontColor('#D97706').width('100%')
      }
      .width('92%').padding(18).backgroundColor(Color.White).borderRadius(18).margin({ top: 12 })
      Blank()
    }
    .width('100%').height('100%').alignItems(HorizontalAlign.Center).backgroundColor('#F3F7FF')
  }
}
