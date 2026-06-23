import router from '@ohos.router';
import { PortForwardRule, TerminalTab } from '../common/models/TerminalModels';
import { NativeSshCore } from '../common/native/NativeSshCore';
import { PortForwardManager } from '../common/services/PortForwardManager';
import { TerminalSessionManager } from '../common/services/TerminalSessionManager';
import { createIconColorFilter } from '../common/IconUtils';

@Entry
@Component
struct PortForwardPage {
  @State status: string = '请选择转发类型；所有本地监听仅绑定 127.0.0.1。';
  @State localPort: string = '8080';
  @State remoteHost: string = '127.0.0.1';
  @State remotePort: string = '80';
  @State localHost: string = '127.0.0.1';
  @State forwardType: number = 0;
  @State busy: boolean = false;
  @State rules: PortForwardRule[] = [];
  @State selectedSessionId: string = '';

  private readonly accentColor: string = '#0A84FF';
  private readonly pageBg: string = '#F3F7FF';
  private readonly textPrimary: string = '#111827';
  private readonly textSecond: string = '#64748B';

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    this.reload();
  }

  private reload(): void {
    this.rules = PortForwardManager.list();
    const tabs: TerminalTab[] = this.connectedTabs();
    if (tabs.find((tab: TerminalTab) => tab.sessionId === this.selectedSessionId) === undefined) {
      this.selectedSessionId = tabs.length > 0 ? tabs[0].sessionId : '';
    }
  }

  private connectedTabs(): TerminalTab[] {
    return TerminalSessionManager.listTabs().filter((tab: TerminalTab) => tab.connected);
  }

  private activeTab(): TerminalTab | undefined {
    const exact: TerminalTab | undefined = this.connectedTabs()
      .find((tab: TerminalTab) => tab.sessionId === this.selectedSessionId);
    return exact === undefined ? this.connectedTabs()[0] : exact;
  }

  private parsePort(value: string): number {
    const port: number = Number(value);
    if (!Number.isInteger(port) || port < 1 || port > 65535) return 0;
    return port;
  }

  private async startForward(): Promise<void> {
    if (this.busy) return;
    if (NativeSshCore.version().toLowerCase().indexOf('mock') >= 0) {
      this.status = 'Mock Core 不会创建伪转发；请安装真实 libssh2 Core。';
      return;
    }
    const tab: TerminalTab | undefined = this.activeTab();
    if (tab === undefined) {
      this.status = '请先完成 HostKey 核对与 SSH 认证，再创建转发。';
      return;
    }
    const localPort: number = this.parsePort(this.localPort);
    const remotePort: number = this.parsePort(this.remotePort);
    if (localPort === 0 || (this.forwardType !== 2 && remotePort === 0)) {
      this.status = '端口必须是 1–65535 的整数。';
      return;
    }
    if (this.forwardType === 0 && this.remoteHost.trim().length === 0) {
      this.status = '本地转发需要远端目标主机。';
      return;
    }
    if (this.forwardType === 1 && this.localHost.trim().length === 0) {
      this.status = '远程转发需要本机目标主机。';
      return;
    }

    this.busy = true;
    this.status = '正在建立真实 SSH 转发…';
    try {
      let rule: PortForwardRule | undefined = undefined;
      if (this.forwardType === 0) {
        rule = await PortForwardManager.addLocal(tab.sessionId, localPort, this.remoteHost.trim(), remotePort);
      } else if (this.forwardType === 1) {
        rule = await PortForwardManager.addRemote(tab.sessionId, remotePort, this.localHost.trim(), localPort);
      } else {
        rule = await PortForwardManager.addDynamic(tab.sessionId, localPort);
      }
      if (rule === undefined) {
        this.status = '转发建立失败：请检查端口占用、sshd 转发策略和目标地址。';
        return;
      }
      this.reload();
      this.status = '真实转发已启动；断开 SSH 时会自动释放。';
    } catch (error) {
      this.status = '转发建立异常，未创建 Mock 成功状态。';
    } finally {
      this.busy = false;
    }
  }

  private async stopForward(rule: PortForwardRule): Promise<void> {
    if (this.busy) return;
    this.busy = true;
    this.status = '正在停止转发并释放资源…';
    try {
      const result = await PortForwardManager.remove(rule.id);
      this.reload();
      this.status = result.ok ? '转发已停止，监听端口和 SSH channel 已释放。' : '停止转发失败：' + result.message;
    } catch (error) {
      this.status = '停止转发异常。';
    } finally {
      this.busy = false;
    }
  }

  private typeTitle(rule: PortForwardRule): string {
    if (rule.type === 'local') return '本地转发 -L';
    if (rule.type === 'remote') return '远程转发 -R';
    return '动态 SOCKS5 -D';
  }

  private ruleDetail(rule: PortForwardRule): string {
    if (rule.type === 'local') {
      return '127.0.0.1:' + rule.localPort.toString() + ' -> ' + rule.remoteHost + ':' + rule.remotePort.toString();
    }
    if (rule.type === 'remote') {
      return '服务器 127.0.0.1:' + rule.remotePort.toString() + ' -> ' + rule.localHost + ':' + rule.localPort.toString();
    }
    return 'SOCKS5 127.0.0.1:' + rule.localPort.toString();
  }

  @Builder
  TypeSelector() {
    Row({ space: 6 }) {
      Button('本地 -L')
        .layoutWeight(1).height(38).fontSize(13)
        .fontColor(this.forwardType === 0 ? Color.White : this.textSecond)
        .backgroundColor(this.forwardType === 0 ? this.accentColor : '#E8EEF8')
        .onClick(() => this.forwardType = 0)
      Button('远程 -R')
        .layoutWeight(1).height(38).fontSize(13)
        .fontColor(this.forwardType === 1 ? Color.White : this.textSecond)
        .backgroundColor(this.forwardType === 1 ? this.accentColor : '#E8EEF8')
        .onClick(() => this.forwardType = 1)
      Button('SOCKS5 -D')
        .layoutWeight(1).height(38).fontSize(13)
        .fontColor(this.forwardType === 2 ? Color.White : this.textSecond)
        .backgroundColor(this.forwardType === 2 ? this.accentColor : '#E8EEF8')
        .onClick(() => this.forwardType = 2)
    }
    .width('100%')
  }

  @Builder
  SessionSelector() {
    Column({ space: 6 }) {
      Text('已认证 SSH 会话').fontSize(12).fontColor(this.textSecond).width('100%')
      if (this.connectedTabs().length === 0) {
        Text('无可用会话').fontSize(13).fontColor('#D92D20').width('100%')
      } else {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.connectedTabs(), (tab: TerminalTab) => {
            Button(tab.title)
              .height(34).fontSize(12).margin({ right: 6, bottom: 4 })
              .fontColor(this.selectedSessionId === tab.sessionId ? Color.White : this.textSecond)
              .backgroundColor(this.selectedSessionId === tab.sessionId ? this.accentColor : '#E8EEF8')
              .onClick(() => this.selectedSessionId = tab.sessionId)
          }, (tab: TerminalTab) => tab.id)
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      Row() {
        Image($rawfile('ft_back.svg')).width(24).height(24).margin({ left: 10, right: 10 })
          .colorFilter(createIconColorFilter(this.textPrimary)).onClick(() => router.back())
        Text('端口转发').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.textPrimary)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(44)
      }
      .width('100%').height(64).padding({ left: 14, right: 14, top: 8 })

      Scroll() {
        Column() {
          Column({ space: 10 }) {
            this.SessionSelector()
            this.TypeSelector()
            if (this.forwardType === 0) {
              TextInput({ text: this.localPort, placeholder: '本地监听端口' })
                .height(42).type(InputType.Number).onChange((value: string) => this.localPort = value)
              TextInput({ text: this.remoteHost, placeholder: '远端目标主机' })
                .height(42).onChange((value: string) => this.remoteHost = value)
              TextInput({ text: this.remotePort, placeholder: '远端目标端口' })
                .height(42).type(InputType.Number).onChange((value: string) => this.remotePort = value)
            } else if (this.forwardType === 1) {
              TextInput({ text: this.remotePort, placeholder: '服务器监听端口' })
                .height(42).type(InputType.Number).onChange((value: string) => this.remotePort = value)
              TextInput({ text: this.localHost, placeholder: '本机目标主机' })
                .height(42).onChange((value: string) => this.localHost = value)
              TextInput({ text: this.localPort, placeholder: '本机目标端口' })
                .height(42).type(InputType.Number).onChange((value: string) => this.localPort = value)
            } else {
              TextInput({ text: this.localPort, placeholder: '本地 SOCKS5 端口' })
                .height(42).type(InputType.Number).onChange((value: string) => this.localPort = value)
              Text('SOCKS5 支持 IPv4、IPv6 和域名 CONNECT；不接受用户名/密码认证。')
                .fontSize(12).fontColor(this.textSecond).width('100%')
            }
            Button(this.busy ? '处理中…' : '启动真实转发')
              .width('100%').height(42).enabled(!this.busy).backgroundColor(this.accentColor)
              .onClick(() => this.startForward())
          }
          .width('92%').padding(14).backgroundColor(Color.White).borderRadius(16).margin({ top: 8 })

          Text(this.status)
            .fontColor(this.textSecond).fontSize(12).width('88%').margin({ top: 10, bottom: 12 })

          Text('活动转发').fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.textSecond)
            .width('92%').margin({ bottom: 8 })
          if (this.rules.length === 0) {
            Text('暂无活动转发')
              .fontSize(14).fontColor(this.textSecond).width('92%').height(54)
              .textAlign(TextAlign.Center).backgroundColor(Color.White).borderRadius(14)
          } else {
            Column({ space: 8 }) {
              ForEach(this.rules, (rule: PortForwardRule) => {
                Row() {
                  Row() {
                    Image($rawfile('settings_router.svg')).width(21).height(21)
                      .colorFilter(createIconColorFilter('#FFFFFF'))
                  }
                  .width(36).height(36).justifyContent(FlexAlign.Center)
                  .backgroundColor(rule.type === 'remote' ? '#6554D9' : this.accentColor).borderRadius(10)
                  Column({ space: 2 }) {
                    Text(this.typeTitle(rule)).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.textPrimary)
                    Text(this.ruleDetail(rule)).fontSize(11).fontColor(this.textSecond).maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 10 })
                  Button('停止').height(34).fontSize(12).enabled(!this.busy).backgroundColor('#D92D20')
                    .onClick(() => this.stopForward(rule))
                }
                .width('100%').height(58).padding({ left: 10, right: 10 })
                .backgroundColor(Color.White).borderRadius(14)
              }, (rule: PortForwardRule) => rule.id)
            }
            .width('92%')
          }

          Text('安全说明：本地与 SOCKS 监听强制绑定 127.0.0.1；远程监听请求服务器回环地址，避免默认暴露到局域网。')
            .fontSize(11).fontColor(this.textSecond).width('88%').margin({ top: 12, bottom: 24 })
        }
        .width('100%').alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1).width('100%')
    }
    .width('100%').height('100%').backgroundColor(this.pageBg)
  }
}
