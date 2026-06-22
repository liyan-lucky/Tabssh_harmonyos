import router from '@ohos.router';
import { ConnectionProfile, createEmptyConnectionProfile, AUTH_PASSWORD, AUTH_PRIVATE_KEY } from '../common/models/ConnectionProfile';
import { ProfileRepository } from '../common/storage/ProfileRepository';

@Entry
@Component
struct ConnectionEditPage {
  @State profile: ConnectionProfile = createEmptyConnectionProfile();
  @State title: string = '新建连接';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== undefined && params['profileId'] !== undefined) {
      const found = ProfileRepository.get(params['profileId']);
      if (found !== undefined) {
        this.profile = found;
        this.title = '编辑连接';
      }
    }
  }

  save(): void {
    ProfileRepository.save(this.profile);
    router.back();
  }

  build() {
    Column() {
      Row() {
        Button('返回').onClick(() => router.back())
        Text(this.title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ left: 12 })
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column() {
          TextInput({ text: this.profile.name, placeholder: '连接名称' })
            .onChange((value: string) => this.profile.name = value)
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.host, placeholder: '主机地址 / IP' })
            .onChange((value: string) => this.profile.host = value)
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.port.toString(), placeholder: '端口，默认 22' })
            .type(InputType.Number)
            .onChange((value: string) => this.profile.port = Number(value))
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.username, placeholder: '用户名' })
            .onChange((value: string) => this.profile.username = value)
            .margin({ bottom: 10 })

          Row() {
            Button(this.profile.authType === AUTH_PASSWORD ? '✓ 密码' : '密码')
              .layoutWeight(1)
              .onClick(() => this.profile.authType = AUTH_PASSWORD)
            Button(this.profile.authType === AUTH_PRIVATE_KEY ? '✓ 私钥' : '私钥')
              .layoutWeight(1)
              .margin({ left: 8 })
              .onClick(() => this.profile.authType = AUTH_PRIVATE_KEY)
          }
          .margin({ bottom: 10 })

          if (this.profile.authType === AUTH_PASSWORD) {
            TextInput({ text: this.profile.password, placeholder: '密码，测试工程可留空' })
              .type(InputType.Password)
              .onChange((value: string) => this.profile.password = value)
              .margin({ bottom: 10 })
          } else {
            TextInput({ text: this.profile.privateKeyPath, placeholder: '私钥文件路径 / 后续接入文件选择器' })
              .onChange((value: string) => this.profile.privateKeyPath = value)
              .margin({ bottom: 10 })
          }

          TextInput({ text: this.profile.terminalType, placeholder: '终端类型，例如 xterm-256color' })
            .onChange((value: string) => this.profile.terminalType = value)
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.postConnectScript, placeholder: '连接后脚本，可选' })
            .onChange((value: string) => this.profile.postConnectScript = value)
            .margin({ bottom: 10 })

          Button('保存')
            .width('100%')
            .height(44)
            .onClick(() => this.save())
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B1020')
  }
}
