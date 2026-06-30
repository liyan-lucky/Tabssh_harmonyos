import router from '@ohos.router';
import { PortForwardRule, TerminalTab } from '../common/models/TerminalModels';
import { NativeSshCore } from '../common/native/NativeSshCore';
import { PortForwardManager } from '../common/services/PortForwardManager';
import { TerminalSessionManager } from '../common/services/TerminalSessionManager';
import { createIconColorFilter } from '../common/IconUtils';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';

@Entry
@Component
struct PortForwardPage {
  @State status: string = '';
  @State localPort: string = '8080';
  @State remoteHost: string = '127.0.0.1';
  @State remotePort: string = '80';
  @State localHost: string = '127.0.0.1';
  @State forwardType: number = 0;
  @State busy: boolean = false;
  @State rules: PortForwardRule[] = [];
  @State selectedSessionId: string = '';
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;

  private readonly accentColor: string = '#0A84FF';

  private t(key: string): string {
    return I18n.t(this.language, key);
  }

  private pageBg(): string {
    return AppTheme.pageBg(this.themeMode);
  }

  private cardBg(): string {
    return AppTheme.cardBg(this.themeMode);
  }

  private textPrimary(): string {
    return AppTheme.textPrimary(this.themeMode);
  }

  private textSecond(): string {
    return AppTheme.textSecond(this.themeMode);
  }

  private chipBg(): string {
    return AppTheme.chipBg(this.themeMode);
  }

  aboutToAppear(): void {
    if (this.status.length === 0) {
      this.status = this.t('forward.initialStatus');
    }
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
      this.status = this.t('forward.mockStatus');
      return;
    }
    const tab: TerminalTab | undefined = this.activeTab();
    if (tab === undefined) {
      this.status = this.t('forward.authFirst');
      return;
    }
    const localPort: number = this.parsePort(this.localPort);
    const remotePort: number = this.parsePort(this.remotePort);
    if (localPort === 0 || (this.forwardType !== 2 && remotePort === 0)) {
      this.status = this.t('forward.invalidPort');
      return;
    }
    if (this.forwardType === 0 && this.remoteHost.trim().length === 0) {
      this.status = this.t('forward.localHostRequired');
      return;
    }
    if (this.forwardType === 1 && this.localHost.trim().length === 0) {
      this.status = this.t('forward.remoteLocalRequired');
      return;
    }

    this.busy = true;
    this.status = this.t('forward.starting');
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
        this.status = this.t('forward.failedStart');
        return;
      }
      this.reload();
      this.status = this.t('forward.started');
    } catch (error) {
      this.status = this.t('forward.exception');
    } finally {
      this.busy = false;
    }
  }

  private async stopForward(rule: PortForwardRule): Promise<void> {
    if (this.busy) return;
    this.busy = true;
    this.status = this.t('forward.stopping');
    try {
      const result = await PortForwardManager.remove(rule.id);
      this.reload();
      this.status = result.ok ? this.t('forward.stopped') : this.t('forward.stopFailedPrefix') + result.message;
    } catch (error) {
      this.status = this.t('forward.stopException');
    } finally {
      this.busy = false;
    }
  }

  private typeTitle(rule: PortForwardRule): string {
    if (rule.type === 'local') return this.t('forward.typeLocal');
    if (rule.type === 'remote') return this.t('forward.typeRemote');
    return this.t('forward.typeDynamic');
  }

  private ruleDetail(rule: PortForwardRule): string {
    if (rule.type === 'local') {
      return '127.0.0.1:' + rule.localPort.toString() + ' -> ' + rule.remoteHost + ':' + rule.remotePort.toString();
    }
    if (rule.type === 'remote') {
      return this.t('forward.serverLoopback') + rule.remotePort.toString() + ' -> ' + rule.localHost + ':' + rule.localPort.toString();
    }
    return 'SOCKS5 127.0.0.1:' + rule.localPort.toString();
  }

  @Builder
  TypeSelector() {
    Row({ space: 6 }) {
      Button(this.t('forward.localL'))
        .layoutWeight(1).height(38).fontSize(13)
        .fontColor(this.forwardType === 0 ? Color.White : this.textSecond())
        .backgroundColor(this.forwardType === 0 ? this.accentColor : this.chipBg())
        .onClick(() => this.forwardType = 0)
      Button(this.t('forward.remoteR'))
        .layoutWeight(1).height(38).fontSize(13)
        .fontColor(this.forwardType === 1 ? Color.White : this.textSecond())
        .backgroundColor(this.forwardType === 1 ? this.accentColor : this.chipBg())
        .onClick(() => this.forwardType = 1)
      Button(this.t('forward.socksD'))
        .layoutWeight(1).height(38).fontSize(13)
        .fontColor(this.forwardType === 2 ? Color.White : this.textSecond())
        .backgroundColor(this.forwardType === 2 ? this.accentColor : this.chipBg())
        .onClick(() => this.forwardType = 2)
    }
    .width('100%')
  }

  @Builder
  SessionSelector() {
    Column({ space: 6 }) {
      Text(this.t('forward.sessionTitle')).fontSize(12).fontColor(this.textSecond()).width('100%')
      if (this.connectedTabs().length === 0) {
        Text(this.t('forward.noSession')).fontSize(13).fontColor('#D92D20').width('100%')
      } else {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.connectedTabs(), (tab: TerminalTab) => {
            Button(tab.title)
              .height(34).fontSize(12).margin({ right: 6, bottom: 4 })
              .fontColor(this.selectedSessionId === tab.sessionId ? Color.White : this.textSecond())
              .backgroundColor(this.selectedSessionId === tab.sessionId ? this.accentColor : this.chipBg())
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
          .colorFilter(createIconColorFilter(this.textPrimary())).onClick(() => router.back())
        Text(this.t('forward.title')).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.textPrimary())
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
              TextInput({ text: this.localPort, placeholder: this.t('forward.localPort') })
                .height(42).type(InputType.Number).onChange((value: string) => this.localPort = value)
              TextInput({ text: this.remoteHost, placeholder: this.t('forward.remoteHost') })
                .height(42).onChange((value: string) => this.remoteHost = value)
              TextInput({ text: this.remotePort, placeholder: this.t('forward.remotePort') })
                .height(42).type(InputType.Number).onChange((value: string) => this.remotePort = value)
            } else if (this.forwardType === 1) {
              TextInput({ text: this.remotePort, placeholder: this.t('forward.serverPort') })
                .height(42).type(InputType.Number).onChange((value: string) => this.remotePort = value)
              TextInput({ text: this.localHost, placeholder: this.t('forward.localHost') })
                .height(42).onChange((value: string) => this.localHost = value)
              TextInput({ text: this.localPort, placeholder: this.t('forward.localTargetPort') })
                .height(42).type(InputType.Number).onChange((value: string) => this.localPort = value)
            } else {
              TextInput({ text: this.localPort, placeholder: this.t('forward.socksPort') })
                .height(42).type(InputType.Number).onChange((value: string) => this.localPort = value)
              Text(this.t('forward.socksNote'))
                .fontSize(12).fontColor(this.textSecond()).width('100%')
            }
            Button(this.busy ? this.t('forward.busy') : this.t('forward.start'))
              .width('100%').height(42).enabled(!this.busy).backgroundColor(this.accentColor)
              .onClick(() => this.startForward())
          }
          .width('92%').padding(14).backgroundColor(this.cardBg()).borderRadius(16).margin({ top: 8 })

          Text(this.status)
            .fontColor(this.textSecond()).fontSize(12).width('88%').margin({ top: 10, bottom: 12 })

          Text(this.t('forward.active')).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.textSecond())
            .width('92%').margin({ bottom: 8 })
          if (this.rules.length === 0) {
            Text(this.t('forward.empty'))
              .fontSize(14).fontColor(this.textSecond()).width('92%').height(54)
              .textAlign(TextAlign.Center).backgroundColor(this.cardBg()).borderRadius(14)
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
                    Text(this.typeTitle(rule)).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.textPrimary())
                    Text(this.ruleDetail(rule)).fontSize(11).fontColor(this.textSecond()).maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 10 })
                  Button(this.t('common.stop')).height(34).fontSize(12).enabled(!this.busy).backgroundColor('#D92D20')
                    .onClick(() => this.stopForward(rule))
                }
                .width('100%').height(58).padding({ left: 10, right: 10 })
                .backgroundColor(this.cardBg()).borderRadius(14)
              }, (rule: PortForwardRule) => rule.id)
            }
            .width('92%')
          }

          Text(this.t('forward.security'))
            .fontSize(11).fontColor(this.textSecond()).width('88%').margin({ top: 12, bottom: 24 })
        }
        .width('100%').alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1).width('100%')
    }
    .width('100%').height('100%').backgroundColor(this.pageBg())
    .padding({ top: this.avoidStatusBarHeight, bottom: this.avoidNavigationBarHeight })
  }
}
