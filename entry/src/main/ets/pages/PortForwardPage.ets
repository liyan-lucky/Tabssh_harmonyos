import router from '@ohos.router';

@Entry
@Component
struct PortForwardPage {
  @State status: string = '未启动';
  @State localPort: string = '8080';
  @State remoteHost: string = '127.0.0.1';
  @State remotePort: string = '80';

  startLocalForward(): void {
    this.status = '尚未实现真实流量链路：不会创建 Mock 转发。完成 local/remote/dynamic worker 与流量验证后才会启用。';
  }

  build() {
    Column() {
      Row() {
        Button('返回').onClick(() => router.back())
        Text('端口转发')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ left: 12 })
      }
      .padding(16)
      .width('100%')

      Column() {
        Text('Local Forward')
          .fontColor(Color.White)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: 10 })
        TextInput({ text: this.localPort, placeholder: '本地端口' })
          .type(InputType.Number)
          .onChange((value: string) => this.localPort = value)
          .margin({ bottom: 10 })
        TextInput({ text: this.remoteHost, placeholder: '远端主机' })
          .onChange((value: string) => this.remoteHost = value)
          .margin({ bottom: 10 })
        TextInput({ text: this.remotePort, placeholder: '远端端口' })
          .type(InputType.Number)
          .onChange((value: string) => this.remotePort = value)
          .margin({ bottom: 10 })
        Button('本地转发开发中')
          .width('100%')
          .onClick(() => this.startLocalForward())
      }
      .padding(16)
      .margin({ left: 16, right: 16 })
      .backgroundColor('#172033')
      .borderRadius(14)

      Text(this.status)
        .fontColor('#38BDF8')
        .fontSize(13)
        .padding(16)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B1020')
  }
}
