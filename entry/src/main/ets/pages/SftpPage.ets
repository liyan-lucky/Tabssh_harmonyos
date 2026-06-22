import router from '@ohos.router';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { ConnectionProfile } from '../common/models/ConnectionProfile';
import { NativeSshCore } from '../common/native/NativeSshCore';
import { SftpEntry } from '../common/models/TerminalModels';

@Entry
@Component
struct SftpPage {
  @State entries: SftpEntry[] = [];
  @State currentPath: string = '/';
  @State status: string = 'SFTP Mock 列表，可替换为 libssh2_sftp 实现';

  aboutToAppear(): void {
    this.loadList('/');
  }

  loadList(path: string): void {
    const profiles: ConnectionProfile[] = ProfileRepository.list();
    if (profiles.length === 0) {
      this.status = '没有连接配置';
      return;
    }
    const sessionId: string = NativeSshCore.createSession(profiles[0]);
    NativeSshCore.connect(sessionId);
    this.currentPath = path;
    this.entries = NativeSshCore.sftpList(sessionId, path);
    NativeSshCore.disconnect(sessionId);
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
