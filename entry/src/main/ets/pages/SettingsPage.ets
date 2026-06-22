import router from '@ohos.router';
import { NativeSshCore } from '../common/native/NativeSshCore';

@Entry
@Component
struct SettingsPage {
  @State nativeVersion: string = '';

  aboutToAppear(): void {
    this.nativeVersion = NativeSshCore.version();
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
        Text('当前包默认使用 Mock Native Core，保证项目可先导入和构建。真实 SSH 实现请按 docs/LIBSSH2_COMPILE_GUIDE.md 编译 libssh2 后切换 CMake。')
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
