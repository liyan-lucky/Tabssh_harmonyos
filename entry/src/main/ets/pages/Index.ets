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
  icon: Resource;
}

@Entry
@Component
struct Index {
  @State profiles: ConnectionProfile[] = [];
  @State nativeVersion: string = '';
  @State activeTab: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;

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
    { title: '工作台', icon: $rawfile('tab_workbench.svg') },
    { title: '连接', icon: $rawfile('tab_connections.svg') },
    { title: '监控', icon: $rawfile('tab_monitor.svg') },
    { title: '我的', icon: $rawfile('tab_profile.svg') }
  ];

  aboutToAppear(): void {
    this.reload();
    this.nativeVersion = NativeSshCore.version();
  }

  onPageShow(): void {
    this.reload();
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
    if (this.activeTab === 2) {
      Row() {
        Column({ space: 2 }) {
          Text('设备监控')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
          Text('0 台设备在线')
            .fontSize(13)
            .fontColor(this.textSecond)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('▣')
          .fontSize(22)
          .fontColor(this.textPrimary)
          .margin({ right: 18 })
        Text('●')
          .fontSize(18)
          .fontColor('#34C759')
          .margin({ right: 16 })
        Text('≡')
          .fontSize(22)
          .fontColor(this.textSecond)
      }
      .width('100%')
      .height(72)
      .padding({ left: 22, right: 22, top: 8 })
    } else {
      Row() {
        Blank()
          .layoutWeight(1)

        Row() {
          if (this.activeTab === 0) {
            Text('☁')
              .fontSize(22)
              .fontColor(this.textPrimary)
              .margin({ right: 8 })
          }
          Text(this.activeTab === 3 ? '设置' : this.tabs[this.activeTab].title)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .layoutWeight(2)

        Row() {
          if (this.activeTab === 0) {
            Text('⚙')
              .fontSize(22)
              .fontColor(this.textPrimary)
              .onClick(() => router.pushUrl({ url: 'pages/SettingsPage' }))
          } else if (this.activeTab === 1) {
            Text('+')
              .fontSize(30)
              .fontColor(this.accentColor)
              .onClick(() => router.pushUrl({ url: 'pages/ConnectionEditPage' }))
          }
        }
        .justifyContent(FlexAlign.End)
        .layoutWeight(1)
      }
      .width('100%')
      .height(64)
      .padding({ left: 22, right: 22, top: 10 })
    }
  }

  @Builder
  SectionLabel(title: string) {
    Text(title)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor('#64748B')
      .width('92%')
      .margin({ top: 14, bottom: 8 })
  }

  @Builder
  CompactOptionRow(icon: string, title: string, subtitle: string, color: string, action: () => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        Row() {
          Text(icon)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(color)
        .borderRadius(10)
        .margin({ right: 12 })

        Column({ space: 2 }) {
          Text(title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary)
            .maxLines(1)
          if (subtitle.length > 0) {
            Text(subtitle)
              .fontSize(12)
              .fontColor(this.textSecond)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('›')
          .fontSize(26)
          .fontColor('#94A3B8')
      }
      .width('100%')
      .height(subtitle.length > 0 ? 62 : 54)
      .padding({ left: 14, right: 14 })
      .onClick(action)

      if (showDivider) {
        Divider()
          .color(this.lineColor)
          .strokeWidth(1)
          .margin({ left: 62 })
      }
    }
    .width('100%')
  }

  @Builder
  ActionRow(item: WorkbenchAction, index: number) {
    Column() {
      Row() {
        Text(item.icon)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.accentColor)
          .width(48)
          .textAlign(TextAlign.Center)

        Text(item.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)
          .layoutWeight(1)

        Text('›')
          .fontSize(28)
          .fontColor('#C9CDD4')
          .margin({ right: 2 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 14, right: 14 })
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
      .borderRadius(18)
      .clip(true)
      .margin({ top: 14 })

      Blank()
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ConnectionPage() {
    Scroll() {
      Column() {
        Stack() {
          Text('01 101 001  SSH  110 010 11')
            .fontSize(16)
            .fontColor('#406A88')
            .width('100%')
            .height('100%')
            .textAlign(TextAlign.Center)

          Column({ space: 7 }) {
            Text('SSH')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#38BDF8')
            Text('安全、稳定、高效的 SSH 连接工具')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
        }
        .width('92%')
        .height(122)
        .backgroundColor('#082F49')
        .borderRadius(18)
        .margin({ top: 10 })

        Text('连接方式')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .width('92%')
          .margin({ top: 16 })
        Text('添加主机、使用 SFTP，或进入本地终端。')
          .fontSize(13)
          .fontColor(this.textSecond)
          .width('92%')
          .margin({ top: 5, bottom: 10 })

        Column() {
          this.CompactOptionRow('▣', 'SSH 主机连接', '新建或管理密码 / 私钥连接', '#0A84FF',
            () => router.pushUrl({ url: 'pages/ConnectionEditPage' }))
          this.CompactOptionRow('■', '通过 SFTP 连接', '复用已认证的 SSH 会话', '#2EA8E5',
            () => router.pushUrl({ url: 'pages/SftpPage' }))
          this.CompactOptionRow('◎', '发现局域网设备', '局域网扫描功能开发中', '#35C7D7',
            () => this.toast('局域网设备发现尚未接入真实扫描'))
          this.CompactOptionRow('>_', '本地终端', '本地 shell 功能开发中', '#38BDF8',
            () => this.toast('本地终端尚未实现'), false)
        }
        .width('92%')
        .backgroundColor(Color.White)
        .borderRadius(18)
        .clip(true)

        this.SectionLabel('已保存主机')
        if (this.profiles.length === 0) {
          Row() {
            Text('暂无主机，点击右上角 + 添加')
              .fontSize(14)
              .fontColor(this.textSecond)
          }
          .width('92%')
          .height(54)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Color.White)
          .borderRadius(16)
        } else {
          Column() {
            ForEach(this.profiles, (profile: ConnectionProfile, index: number) => {
              Column() {
                Row() {
                  Text('▤')
                    .fontSize(22)
                    .fontColor(this.accentColor)
                    .width(38)
                  Column({ space: 2 }) {
                    Text(profile.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.textPrimary)
                    Text(profile.username + '@' + profile.host + ':' + profile.port.toString())
                      .fontSize(12)
                      .fontColor(this.textSecond)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text('连接')
                    .fontSize(13)
                    .fontColor(this.accentColor)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .backgroundColor('#EAF3FF')
                    .borderRadius(10)
                    .onClick(() => router.pushUrl({ url: 'pages/TerminalPage', params: { profileId: profile.id } }))
                }
                .width('100%')
                .height(58)
                .padding({ left: 12, right: 12 })
                if (index < this.profiles.length - 1) {
                  Divider().color(this.lineColor).margin({ left: 50 })
                }
              }
            }, (profile: ConnectionProfile) => profile.id)
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(16)
          .clip(true)
        }

        Button('端口转发')
          .height(40)
          .fontSize(14)
          .fontColor(this.accentColor)
          .backgroundColor('#EAF3FF')
          .borderRadius(12)
          .margin({ top: 12, bottom: 18 })
          .onClick(() => router.pushUrl({ url: 'pages/PortForwardPage' }))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  MonitorPage() {
    Column() {
      Blank()

      Stack() {
        Circle()
          .width(132)
          .height(132)
          .fill('#EEF3FF')
        Text('▣')
          .fontSize(54)
          .fontColor('#D8E1EE')
      }

      Text('暂无监控设备')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .margin({ top: 24 })
      Text('添加第一台设备开始监控')
          .fontSize(15)
          .fontColor(this.textSecond)
          .margin({ top: 10 })

      Button('⊕  添加设备')
        .width(190)
        .height(48)
        .fontSize(16)
        .backgroundColor(this.accentColor)
        .borderRadius(14)
        .margin({ top: 28 })
        .onClick(() => {
          this.activeTab = 1;
          router.pushUrl({ url: 'pages/ConnectionEditPage' });
        })

      Text('ⓘ  查看功能介绍')
        .fontSize(15)
        .fontColor('#64748B')
        .margin({ top: 22 })
        .onClick(() => this.toast('设备在线、CPU、内存、磁盘和网络监控尚未实现'))

      Blank()

      Row() {
        Text('+')
          .fontSize(30)
          .fontColor(Color.White)
      }
      .width(54)
      .height(54)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.accentColor)
      .borderRadius(16)
      .shadow({ radius: 8, color: '#300A84FF', offsetY: 4 })
      .alignSelf(ItemAlign.End)
      .margin({ right: 20, bottom: 16 })
      .onClick(() => router.pushUrl({ url: 'pages/ConnectionEditPage' }))
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MinePage() {
    Scroll() {
      Column() {
        Row() {
          Text('❝')
            .fontSize(26)
            .fontColor('#7757E8')
            .margin({ right: 12 })
          Text('富润屋，德润身，心广体胖。——《大学》')
            .fontSize(14)
            .fontColor(this.textPrimary)
            .layoutWeight(1)
            .maxLines(2)
          Text('↻')
            .fontSize(22)
            .fontColor('#64748B')
            .margin({ left: 8 })
            .onClick(() => this.toast('已更新今日寄语'))
        }
        .width('92%')
        .height(78)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Color.White)
        .borderRadius(18)
        .shadow({ radius: 8, color: '#10000000', offsetY: 3 })
        .margin({ top: 12 })

        this.SectionLabel('终端')
        Column() {
          this.CompactOptionRow('>_', '终端设置', '字体、主题、键盘等完整配置', '#0A84FF',
            () => router.pushUrl({ url: 'pages/TerminalSettingsPage' }), false)
        }
        .width('92%')
        .backgroundColor(Color.White)
        .borderRadius(18)
        .clip(true)

        this.SectionLabel('系统设置')
        Column() {
          this.CompactOptionRow('⚙', '系统设置', '', '#6554D9',
            () => router.pushUrl({ url: 'pages/SettingsPage' }))
          this.CompactOptionRow('⇧', '分享应用', '', '#2FC665',
            () => this.toast('系统分享面板接入中'), false)
        }
        .width('92%')
        .backgroundColor(Color.White)
        .borderRadius(18)
        .clip(true)

        this.SectionLabel('关于')
        Column() {
          this.CompactOptionRow('i', '关于', 'OpenTabSsh 与 Native Core 信息', '#34B7E5',
            () => router.pushUrl({ url: 'pages/AboutPage' }))
          this.CompactOptionRow('∞', '备案信息', '待发布主体确认', '#FF2965',
            () => this.toast('备案信息将在正式发布前配置'), false)
        }
        .width('92%')
        .backgroundColor(Color.White)
        .borderRadius(18)
        .clip(true)
        .margin({ bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
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
        Column({ space: 3 }) {
          Image(tab.icon)
            .width(22)
            .height(22)
            .fillColor(this.activeTab === index ? this.accentColor : '#8D939E')

          Text(tab.title)
            .fontSize(11)
            .fontColor(this.activeTab === index ? this.accentColor : '#8D939E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 4, bottom: 4 })
        .onClick(() => {
          this.activeTab = index;
          if (index === 1) {
            this.reload();
          }
        })
      }, (tab: BottomTabItem) => tab.title)
    }
    .width('100%')
    .height(56)
    .borderRadius(28)
    .backgroundColor('#D9FFFFFF')
    .backgroundBlurStyle(BlurStyle.Thin, {
      colorMode: ThemeColorMode.LIGHT,
      adaptiveColor: AdaptiveColor.AVERAGE
    })
    .border({ width: 1, color: '#50FFFFFF' })
    .shadow({ radius: 8, color: '#18000000', offsetY: 3 })
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.ContentPage()
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 72 })

      Column() {
        this.BottomNavigation()
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .padding({ left: 16, right: 16, bottom: this.avoidNavigationBarHeight + 8 })
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageBg)
  }
}
