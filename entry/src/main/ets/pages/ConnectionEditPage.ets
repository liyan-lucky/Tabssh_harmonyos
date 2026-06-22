import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { ConnectionProfile, createEmptyConnectionProfile, AUTH_PASSWORD, AUTH_PRIVATE_KEY } from '../common/models/ConnectionProfile';
import { ProfileRepository } from '../common/storage/ProfileRepository';

@Entry
@Component
struct ConnectionEditPage {
  @State profile: ConnectionProfile = createEmptyConnectionProfile();
  @State title: string = '新建连接';
  @State privateKeyStatus: string = '';

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
    if (this.profile.host.trim().length === 0 || this.profile.username.trim().length === 0 ||
      this.profile.port < 1 || this.profile.port > 65535) {
      promptAction.showToast({ message: '请填写有效的主机、端口和用户名', duration: 2200 });
      return;
    }
    if (this.profile.authType === AUTH_PRIVATE_KEY && this.profile.privateKeyPath.length === 0) {
      promptAction.showToast({ message: '请先从系统文件选择器导入私钥', duration: 2200 });
      return;
    }
    ProfileRepository.save(this.profile);
    router.back();
  }

  async importPrivateKey(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      const selectedUris: Array<string> = await documentPicker.select(options);
      if (selectedUris.length === 0) {
        return;
      }

      const keyDirectory: string = context.filesDir + '/ssh_keys';
      if (!fs.accessSync(keyDirectory)) {
        fs.mkdirSync(keyDirectory);
      }
      const destination: string = keyDirectory + '/profile_' + this.profile.id + '.key';
      const source: fs.File = fs.openSync(selectedUris[0], fs.OpenMode.READ_ONLY);
      try {
        fs.copyFileSync(source.fd, destination);
      } finally {
        fs.closeSync(source);
      }

      this.profile.privateKeyPath = destination;
      this.privateKeyStatus = '私钥已导入应用私有目录；不会写入工程、日志或普通配置。';
      promptAction.showToast({ message: '私钥导入成功', duration: 1800 });
    } catch (error) {
      this.privateKeyStatus = '私钥导入未完成。';
      promptAction.showToast({ message: '私钥导入失败或已取消', duration: 2200 });
    }
  }

  clearPrivateKey(): void {
    const path: string = this.profile.privateKeyPath;
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const privateDirectoryPrefix: string = context.filesDir + '/ssh_keys/';
    if (path.startsWith(privateDirectoryPrefix) && fs.accessSync(path)) {
      try {
        fs.unlinkSync(path);
      } catch (error) {
        this.privateKeyStatus = '私钥文件删除失败，请稍后重试。';
        return;
      }
    }
    this.profile.privateKeyPath = '';
    this.profile.privateKeyPassphrase = '';
    this.privateKeyStatus = '已清除当前连接的私钥。';
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
            TextInput({ text: this.profile.password, placeholder: '密码（仅保留在本次运行内存）' })
              .type(InputType.Password)
              .onChange((value: string) => this.profile.password = value)
              .margin({ bottom: 10 })
          } else {
            Button(this.profile.privateKeyPath.length > 0 ? '重新导入私钥' : '从文件中导入私钥')
              .width('100%')
              .onClick(() => this.importPrivateKey())
              .margin({ bottom: 8 })
            TextInput({ text: this.profile.privateKeyPath, placeholder: '尚未导入私钥' })
              .enabled(false)
              .margin({ bottom: 10 })
            if (this.profile.privateKeyPath.length > 0) {
              Button('删除已导入私钥')
                .width('100%')
                .onClick(() => this.clearPrivateKey())
                .margin({ bottom: 8 })
            }
            if (this.privateKeyStatus.length > 0) {
              Text(this.privateKeyStatus)
                .fontSize(12)
                .fontColor('#94A3B8')
                .width('100%')
                .margin({ bottom: 8 })
            }
            TextInput({ text: this.profile.privateKeyPassphrase, placeholder: '私钥口令（仅保留在本次运行内存）' })
              .type(InputType.Password)
              .onChange((value: string) => this.profile.privateKeyPassphrase = value)
              .margin({ bottom: 10 })
          }

          Text('凭据不会写入源码、日志或普通持久化存储；应用重启后需重新输入。')
            .fontSize(12)
            .fontColor('#F59E0B')
            .width('100%')
            .margin({ bottom: 10 })

          if (this.profile.hostKeyFingerprint.length > 0) {
            Column() {
              Text('已信任 HostKey')
                .fontSize(13)
                .fontColor('#94A3B8')
                .width('100%')
              Text(this.profile.hostKeyFingerprint)
                .fontSize(12)
                .fontColor('#38BDF8')
                .width('100%')
                .margin({ top: 4, bottom: 6 })
              Button('清除信任，下次重新核对')
                .onClick(() => this.profile.hostKeyFingerprint = '')
            }
            .width('100%')
            .margin({ bottom: 10 })
          }

          TextInput({ text: this.profile.terminalType, placeholder: '终端类型，例如 xterm-256color' })
            .onChange((value: string) => this.profile.terminalType = value)
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.postConnectScript, placeholder: '连接后脚本，可选' })
            .onChange((value: string) => this.profile.postConnectScript = value)
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.timeoutMilliseconds.toString(), placeholder: '连接超时（毫秒）' })
            .type(InputType.Number)
            .onChange((value: string) => this.profile.timeoutMilliseconds = Number(value))
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
