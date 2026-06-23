import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ConnectionProfile } from '../common/models/ConnectionProfile';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { NativeSshCore } from '../common/native/NativeSshCore';
import { createIconColorFilter } from '../common/IconUtils';

interface WorkbenchAction {
  title: string;
  icon: Resource;
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
    { title: '主机列表', icon: $rawfile('settings_server.svg'), type: 'hosts' },
    { title: '钥匙串', icon: $rawfile('settings_shield.svg'), type: 'keys' },
    { title: 'Redis连接', icon: $rawfile('settings_cpu.svg'), type: 'redis' },
    { title: 'SFTP连接', icon: $rawfile('ft_remote.svg'), type: 'sftp' },
    { title: '文件管理', icon: $rawfile('settings_folder.svg'), type: 'files' },
    { title: '局域网传输', icon: $rawfile('settings_network.svg'), type: 'lan' },
    { title: '访问日志', icon: $rawfile('settings_timer.svg'), type: 'logs' },
    { title: '运维笔记', icon: $rawfile('settings_privacy.svg'), type: 'notes' }
  ];

  private tabs: BottomTabItem[] = [
    { title: '工作台', icon: $rawfile('settings_tune.svg') },
    { title: '连接', icon: $rawfile('settings_network.svg') },
    { title: '监控', icon: $rawfile('settings_monitor.svg') },
    { title: '我的', icon: $rawfile('settings_person.svg') }
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

        Image($rawfile('settings_terminal.svg'))
          .width(22)
          .height(22)
          .colorFilter(createIconColorFilter(this.textPrimary))
          .margin({ right: 18 })
        Circle()
          .width(14)
          .height(14)
          .fill('#34C759')
          .margin({ right: 16 })
        Image($rawfile('ft_sort.svg'))
          .width(22)
          .height(22)
          .colorFilter(createIconColorFilter(this.textSecond))
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
            Image($rawfile('settings_server.svg'))
              .width(21)
              .height(21)
              .colorFilter(createIconColorFilter(this.textPrimary))
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
            Image($rawfile('settings_tune.svg'))
              .width(22)
              .height(22)
              .colorFilter(createIconColorFilter(this.textPrimary))
              .onClick(() => router.pushUrl({ url: 'pages/SettingsPage' }))
          } else if (this.activeTab === 1) {
            Image($rawfile('ft_new_folder.svg'))
              .width(26)
              .height(26)
              .colorFilter(createIconColorFilter(this.accentColor))
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
  CompactOptionRow(icon: Resource, title: string, subtitle: string, color: string, action: () => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        Row() {
          Image(icon)
            .width(21)
            .height(21)
            .colorFilter(createIconColorFilter('#FFFFFF'))
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

        Image($rawfile('ft_up.svg'))
          .width(18)
          .height(18)
          .rotate({ angle: 90 })
          .colorFilter(createIconColorFilter('#94A3B8'))
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
        Image(item.icon)
          .width(22)
          .height(22)
          .colorFilter(createIconColorFilter(this.accentColor))
          .margin({ left: 13, right: 13 })

        Text(item.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)
          .layoutWeight(1)

        Image($rawfile('ft_up.svg'))
          .width(18)
          .height(18)
          .rotate({ angle: 90 })
          .colorFilter(createIconColorFilter('#C9CDD4'))
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
          this.CompactOptionRow($rawfile('settings_server.svg'), 'SSH 主机连接', '新建或管理密码 / 私钥连接', '#0A84FF',
            () => router.pushUrl({ url: 'pages/ConnectionEditPage' }))
          this.CompactOptionRow($rawfile('ft_folder.svg'), '通过 SFTP 连接', '复用已认证的 SSH 会话', '#2EA8E5',
            () => router.pushUrl({ url: 'pages/SftpPage' }))
          this.CompactOptionRow($rawfile('settings_network.svg'), '发现局域网设备', '局域网扫描功能开发中', '#35C7D7',
            () => this.toast('局域网设备发现尚未接入真实扫描'))
          this.CompactOptionRow($rawfile('settings_terminal.svg'), '本地终端', '本地 shell 功能开发中', '#38BDF8',
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
                  Image($rawfile('settings_server.svg'))
                    .width(22)
                    .height(22)
                    .colorFilter(createIconColorFilter(this.accentColor))
                    .margin({ left: 8, right: 8 })
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
        Image($rawfile('settings_monitor.svg'))
          .width(58)
          .height(58)
          .colorFilter(createIconColorFilter('#D8E1EE'))
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

      Button() {
        Row({ space: 9 }) {
          Image($rawfile('ft_new_folder.svg'))
            .width(21)
            .height(21)
            .colorFilter(createIconColorFilter('#FFFFFF'))
          Text('添加设备').fontSize(16).fontColor(Color.White)
        }
      }
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

      Row({ space: 8 }) {
        Image($rawfile('settings_info.svg'))
          .width(19)
          .height(19)
          .colorFilter(createIconColorFilter('#64748B'))
        Text('查看功能介绍').fontSize(15).fontColor('#64748B')
      }
        .margin({ top: 22 })
        .onClick(() => this.toast('设备在线、CPU、内存、磁盘和网络监控尚未实现'))

      Blank()

      Row() {
        Image($rawfile('ft_new_folder.svg'))
          .width(26)
          .height(26)
          .colorFilter(createIconColorFilter('#FFFFFF'))
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
          Image($rawfile('settings_remark.svg'))
            .width(26)
            .height(26)
            .colorFilter(createIconColorFilter('#7757E8'))
            .margin({ right: 12 })
          Text('富润屋，德润身，心广体胖。——《大学》')
            .fontSize(14)
            .fontColor(this.textPrimary)
            .layoutWeight(1)
            .maxLines(2)
          Image($rawfile('refresh.svg'))
            .width(22)
            .height(22)
            .colorFilter(createIconColorFilter('#64748B'))
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
          this.CompactOptionRow($rawfile('settings_terminal.svg'), '终端设置', '字体、主题、键盘等完整配置', '#0A84FF',
            () => router.pushUrl({ url: 'pages/TerminalSettingsPage' }), false)
        }
        .width('92%')
        .backgroundColor(Color.White)
        .borderRadius(18)
        .clip(true)

        this.SectionLabel('系统设置')
        Column() {
          this.CompactOptionRow($rawfile('settings_tune.svg'), '系统设置', '', '#6554D9',
            () => router.pushUrl({ url: 'pages/SettingsPage' }))
          this.CompactOptionRow($rawfile('settings_network.svg'), '分享应用', '', '#2FC665',
            () => this.toast('系统分享面板接入中'), false)
        }
        .width('92%')
        .backgroundColor(Color.White)
        .borderRadius(18)
        .clip(true)

        this.SectionLabel('关于')
        Column() {
          this.CompactOptionRow($rawfile('settings_info.svg'), '关于', 'OpenTabSsh 与 Native Core 信息', '#34B7E5',
            () => router.pushUrl({ url: 'pages/AboutPage' }))
          this.CompactOptionRow($rawfile('settings_privacy.svg'), '备案信息', '待发布主体确认', '#FF2965',
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
            .colorFilter(createIconColorFilter(this.activeTab === index ? this.accentColor : '#8D939E'))

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
