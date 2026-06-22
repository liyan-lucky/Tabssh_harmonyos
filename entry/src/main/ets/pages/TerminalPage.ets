import router from '@ohos.router';
import { ConnectionProfile } from '../common/models/ConnectionProfile';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { TerminalTab } from '../common/models/TerminalModels';
import { TerminalSessionManager } from '../common/services/TerminalSessionManager';

@Entry
@Component
struct TerminalPage {
  @State tabId: string = '';
  @State title: string = '终端';
  @State terminalText: string = '';
  @State command: string = '';
  @State status: string = '未连接';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    let profile: ConnectionProfile | undefined = undefined;
    if (params !== undefined && params['profileId'] !== undefined) {
      profile = ProfileRepository.get(params['profileId']);
    }
    if (profile === undefined) {
      const list: ConnectionProfile[] = ProfileRepository.list();
      if (list.length > 0) {
        profile = list[0];
      }
    }
    if (profile !== undefined) {
      const tab: TerminalTab = TerminalSessionManager.createTab(profile);
      this.tabId = tab.id;
      this.title = tab.title;
      this.terminalText = tab.buffer;
      this.status = tab.connected ? '已连接' : '连接失败 / Mock 模式';
    } else {
      this.terminalText = '没有连接配置，请先返回首页新建连接。';
    }
  }

  sendCommand(): void {
    if (this.command.trim().length === 0) {
      return;
    }
    const updated: TerminalTab | undefined = TerminalSessionManager.write(this.tabId, this.command);
    if (updated !== undefined) {
      this.terminalText = updated.buffer;
    }
    this.command = '';
  }

  closeAndBack(): void {
    if (this.tabId.length > 0) {
      TerminalSessionManager.close(this.tabId);
    }
    router.back();
  }

  build() {
    Column() {
      Row() {
        Button('关闭').onClick(() => this.closeAndBack())
        Column() {
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(this.status)
            .fontSize(12)
            .fontColor('#38BDF8')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#111827')

      Scroll() {
        Text(this.terminalText)
          .fontFamily('monospace')
          .fontSize(14)
          .fontColor('#D1FAE5')
          .width('100%')
          .padding(12)
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#020617')

      Row() {
        TextInput({ text: this.command, placeholder: '输入命令，例如 ls -la' })
          .layoutWeight(1)
          .onChange((value: string) => this.command = value)
        Button('发送')
          .margin({ left: 8 })
          .onClick(() => this.sendCommand())
      }
      .padding(10)
      .backgroundColor('#111827')
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#020617')
  }
}
