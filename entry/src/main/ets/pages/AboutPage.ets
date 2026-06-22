import router from '@ohos.router';

@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      Row() {
        Button('返回').onClick(() => router.back())
        Text('关于')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ left: 12 })
      }
      .padding(16)
      .width('100%')

      Text('OpenTabSsh 是 TabSSH Android 功能方向的 HarmonyOS 原生复刻工程骨架。')
        .fontColor(Color.White)
        .fontSize(16)
        .padding(16)
      Text('目标模块：多标签终端、SSH 密码/私钥登录、HostKey 验证、SFTP、端口转发、跳板机、代理、连接后脚本、tmux/screen/zellij 自动启动。')
        .fontColor('#94A3B8')
        .fontSize(14)
        .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B1020')
  }
}
