import router from '@ohos.router';
import { NativeSshCore } from '../common/native/NativeSshCore';
import { SftpEntry, TerminalTab } from '../common/models/TerminalModels';
import { TerminalSessionManager } from '../common/services/TerminalSessionManager';

@Entry
@Component
struct SftpPage {
  @State entries: SftpEntry[] = [];
  @State currentPath: string = '/';
  @State status: string = '需要一个已认证的 SSH 会话';
  @State tabId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== undefined && params['tabId'] !== undefined) {
      this.tabId = params['tabId'];
    }
    this.loadList('/');
  }

  async loadList(path: string): Promise<void> {
    let active: TerminalTab | undefined = undefined;
    if (this.tabId.length > 0) {
      active = TerminalSessionManager.getTab(this.tabId);
    }
    if (active === undefined) {
      active = TerminalSessionManager.listTabs().find((tab: TerminalTab) => tab.connected);
    }
    if (active === undefined) {
      this.status = '请先打开终端并完成 HostKey 核对与 SSH 认证';
      return;
    }
    this.currentPath = path;
    this.status = '正在读取 SFTP 目录…';
    try {
      this.entries = await NativeSshCore.sftpList(active.sessionId, path);
      this.status = NativeSshCore.version().indexOf('mock') >= 0 ? 'SFTP Mock 列表（非真实文件）' : '真实 SFTP 目录';
    } catch (error) {
      this.entries = [];
      this.status = 'SFTP 目录读取失败';
    }
  }

  build() {
    Column() {
      Row() {
        Button('返回').onClick(() => router.back())
        Text('SFTP 文件')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ left: 12 })
      }
      .padding(16)
      .width('100%')

      Text(this.status)
        .fontColor('#94A3B8')
        .fontSize(13)
        .padding({ left: 16, right: 16, bottom: 8 })

      Text('当前路径：' + this.currentPath)
        .fontColor('#38BDF8')
        .fontSize(13)
        .padding({ left: 16, right: 16, bottom: 8 })

      List() {
        ForEach(this.entries, (entry: SftpEntry) => {
          ListItem() {
            Row() {
              Text(entry.type === 'dir' ? '📁' : '📄')
                .fontSize(20)
              Column() {
                Text(entry.name)
                  .fontColor(Color.White)
                  .fontSize(16)
                Text(entry.path + '  ' + entry.size.toString() + ' bytes')
                  .fontColor('#94A3B8')
                  .fontSize(12)
                  .margin({ top: 4 })
              }
              .margin({ left: 10 })
            }
            .padding(14)
            .width('100%')
            .backgroundColor('#172033')
            .borderRadius(12)
            .onClick(() => {
              if (entry.type === 'dir') {
                this.loadList(entry.path);
              }
            })
          }
          .margin({ left: 16, right: 16, bottom: 10 })
        }, (entry: SftpEntry) => entry.path)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B1020')
  }
}
