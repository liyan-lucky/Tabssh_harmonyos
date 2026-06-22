import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ConnectionProfile } from '../common/models/ConnectionProfile';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { NativeSshCore } from '../common/native/NativeSshCore';

interface WorkbenchAction {
  title: string;
  icon: string;
  type: string;
}

interface BottomTabItem {
  title: string;
  icon: string;
}

@Entry
@Component
struct Index {
  @State profiles: ConnectionProfile[] = [];
  @State nativeVersion: string = '';
  @State activeTab: number = 0;

  private readonly accentColor: string = '#0A84FF';
  private readonly pageBg: string = '#F3F7FF';
  private readonly textPrimary: string = '#111827';
  private readonly textSecond: string = '#8A8F99';
  private readonly lineColor: string = '#ECEEF3';

  private actions: WorkbenchAction[] = [
    { title: '主机列表', icon: '▤', type: 'hosts' },
    { title: '钥匙串', icon: '⚿', type: 'keys' },
    { title: 'Redis连接', icon: '▦', type: 'redis' },
    { title: 'SFTP连接', icon: '▱', type: 'sftp' },
    { title: '文件管理', icon: '□', type: 'files' },
    { title: '局域网传输', icon: '⌯', type: 'lan' },
    { title: '访问日志', icon: '◷', type: 'logs' },
    { title: '运维笔记', icon: '◰', type: 'notes' }
  ];

  private tabs: BottomTabItem[] = [
    { title: '工作台', icon: '●●●' },
    { title: '连接', icon: '↔' },
    { title: '监控', icon: '▰' },
    { title: '我的', icon: '♙' }
  ];

  aboutToAppear(): void {
    this.reload();
    this.nativeVersion = NativeSshCore.version();
  }

  reload(): void {
    this.profiles = ProfileRepository.list();
  }

  private toast(message: string): void {
    promptAction.showToast({ message: message, duration: 1800 });
  }

  private handleAction(item: WorkbenchAction): void {
    if (item.type === 'hosts') {
      this.activeTab = 1;
      return;
    }
    if (item.type === 'sftp') {
      router.pushUrl({ url: 'pages/SftpPage' });
      return;
    }
    if (item.type === 'keys') {
      this.toast('钥匙串页面已预留，后续接入 HUKS / 本地加密密钥管理');
      return;
    }
    if (item.type === 'redis') {
      this.toast('Redis 连接页面已预留，后续可接入 TCP/RESP 客户端');
      return;
    }
    if (item.type === 'files') {
      this.toast('文件管理页面已预留，可对接 SFTP / 本地沙箱文件');
      return;
    }
    if (item.type === 'lan') {
      this.toast('局域网传输页面已预留');
      return;
    }
    if (item.type === 'logs') {
      this.toast('访问日志页面已预留');
      return;
    }
    if (item.type === 'notes') {
      this.toast('运维笔记页面已预留');
      return;
    }
  }

  @Builder
  Header() {
    Row() {
      Blank()
        .layoutWeight(1)

      Row() {
        Text('☁')
          .fontSize(26)
          .fontColor(this.textPrimary)
          .margin({ right: 10 })
        Text(this.tabs[this.activeTab].title)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .layoutWeight(2)

      Row() {
        Text('🔧')
          .fontSize(28)
          .fontColor(this.textPrimary)
          .onClick(() => router.pushUrl({ url: 'pages/SettingsPage' }))
      }
      .justifyContent(FlexAlign.End)
      .layoutWeight(1)
    }
    .width('100%')
    .height(76)
    .padding({ left: 26, right: 26, top: 16 })
  }

  @Builder
  ActionRow(item: WorkbenchAction, index: number) {
    Column() {
      Row() {
        Text(item.icon)
          .fontSize(34)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.accentColor)
          .width(70)
          .textAlign(TextAlign.Center)

        Text(item.title)
          .fontSize(29)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)
          .layoutWeight(1)

        Text('›')
          .fontSize(42)
          .fontColor('#C9CDD4')
          .margin({ right: 6 })
      }
      .width('100%')
      .height(92)
      .padding({ left: 20, right: 18 })
      .onClick(() => this.handleAction(item))

      if (index < this.actions.length - 1) {
        Divider()
          .color(this.lineColor)
          .strokeWidth(1)
          .margin({ left: 0, right: 0 })
      }
    }
    .width('100%')
  }

  @Builder
  WorkbenchPage() {
    Column() {
      Column() {
        ForEach(this.actions, (item: WorkbenchAction, index: number) => {
          this.ActionRow(item, index)
        }, (item: WorkbenchAction) => item.title)
      }
      .width('92%')
      .backgroundColor(Color.White)
      .borderRadius(24)
      .clip(true)
      .margin({ top: 22 })

      Blank()
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ConnectionPage() {
    Column() {
      Row() {
        Button('+ 新建连接')
          .height(44)
          .fontSize(16)
          .backgroundColor(this.accentColor)
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => router.pushUrl({ url: 'pages/ConnectionEditPage' }))

        Button('端口转发')
          .height(44)
          .fontSize(16)
          .backgroundColor('#EAF3FF')
          .fontColor(this.accentColor)
          .borderRadius(12)
          .margin({ left: 10 })
          .onClick(() => router.pushUrl({ url: 'pages/PortForwardPage' }))
      }
      .width('92%')
      .margin({ top: 20, bottom: 12 })

      if (this.profiles.length === 0) {
        Column() {
          Text('暂无主机')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
          Text('点击“新建连接”添加 SSH 主机')
            .fontSize(15)
            .fontColor(this.textSecond)
            .margin({ top: 8 })
        }
        .width('92%')
        .height(150)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .borderRadius(22)
        .margin({ top: 10 })
      } else {
        List() {
          ForEach(this.profiles, (profile: ConnectionProfile) => {
            ListItem() {
              Column() {
                Row() {
                  Text('▤')
                    .fontSize(30)
                    .fontColor(this.accentColor)
                    .width(48)
                  Column() {
                    Text(profile.name)
                      .fontSize(21)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.textPrimary)
                    Text(profile.username + '@' + profile.host + ':' + profile.port.toString())
                      .fontSize(14)
                      .fontColor(this.textSecond)
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text('连接')
                    .fontSize(16)
                    .fontColor(this.accentColor)
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                    .backgroundColor('#EAF3FF')
                    .borderRadius(12)
                    .onClick(() => router.pushUrl({ url: 'pages/TerminalPage', params: { profileId: profile.id } }))
                }
                .width('100%')
                .padding(18)
              }
              .backgroundColor(Color.White)
              .borderRadius(18)
            }
            .margin({ left: 16, right: 16, bottom: 10 })
          }, (profile: ConnectionProfile) => profile.id)
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MonitorPage() {
    Column() {
      Column() {
        Text('监控')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text('主机状态、CPU、内存、磁盘、网络速率页面已预留')
          .fontSize(16)
          .fontColor(this.textSecond)
          .margin({ top: 8 })
        Text('Native: ' + this.nativeVersion)
          .fontSize(13)
          .fontColor(this.accentColor)
          .margin({ top: 14 })
      }
      .width('92%')
      .padding(22)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(Color.White)
      .borderRadius(22)
      .margin({ top: 22 })

      Blank()
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MinePage() {
    Column() {
      Column() {
        Text('OpenTabSsh')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text('ArkTS + ArkUI + Native C++ SSH Core')
          .fontSize(15)
          .fontColor(this.textSecond)
          .margin({ top: 8 })
        Button('关于项目')
          .height(42)
          .fontSize(16)
          .backgroundColor(this.accentColor)
          .borderRadius(12)
          .margin({ top: 18 })
          .onClick(() => router.pushUrl({ url: 'pages/AboutPage' }))
      }
      .width('92%')
      .padding(22)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(Color.White)
      .borderRadius(22)
      .margin({ top: 22 })

      Blank()
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ContentPage() {
    if (this.activeTab === 0) {
      this.WorkbenchPage()
    } else if (this.activeTab === 1) {
      this.ConnectionPage()
    } else if (this.activeTab === 2) {
      this.MonitorPage()
    } else {
      this.MinePage()
    }
  }

  @Builder
  BottomNavigation() {
    Row() {
      ForEach(this.tabs, (tab: BottomTabItem, index: number) => {
        Column() {
          Text(tab.icon)
            .fontSize(index === 0 ? 28 : 26)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.activeTab === index ? this.accentColor : '#8D939E')
            .height(32)
            .textAlign(TextAlign.Center)

          Text(tab.title)
            .fontSize(18)
            .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.activeTab === index ? this.accentColor : '#8D939E')
            .margin({ top: 2 })

          if (this.activeTab === index) {
            Row()
              .width(36)
              .height(4)
              .backgroundColor(this.accentColor)
              .borderRadius(2)
              .margin({ top: 6 })
          } else {
            Row()
              .width(36)
              .height(4)
              .backgroundColor(Color.Transparent)
              .margin({ top: 6 })
          }
        }
        .layoutWeight(1)
        .height(76)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.activeTab = index;
          if (index === 1) {
            this.reload();
          }
        })
      }, (tab: BottomTabItem) => tab.title)
    }
    .width('100%')
    .height(92)
    .padding({ left: 18, right: 18, bottom: 8 })
    .backgroundColor(Color.White)
  }

  build() {
    Column() {
      this.Header()
      this.ContentPage()
      this.BottomNavigation()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageBg)
  }
}
