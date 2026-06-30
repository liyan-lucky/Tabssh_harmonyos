import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import socket from '@ohos.net.socket';
import connection from '@ohos.net.connection';
import http from '@ohos.net.http';
import { createIconColorFilter } from '../common/IconUtils';
import { AppTheme } from '../common/AppTheme';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { I18n } from '../common/I18n';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { ConnectionProfile } from '../common/models/ConnectionProfile';

interface ToolboxItem {
  titleKey: string;
  subtitleKey: string;
  category: string;
  icon: Resource;
  color: string;
  bgColor: string;
}

interface ParsedEndpoint {
  host: string;
  ports: number[];
}

interface TcpProbeResult {
  host: string;
  address: string;
  port: number;
  ok: boolean;
  elapsedMs: number;
  detail: string;
}

interface Ipv4Link {
  address: string;
  prefixLength: number;
}

interface QrMatrixResult {
  version: number;
  size: number;
  dataCodewords: number;
  eccCodewords: number;
  lines: string[];
}

@Entry
@Component
struct ToolboxPage {
  @State keyword: string = '';
  @State selectedCategory: string = 'all';
  @State activeToolKey: string = '';
  @State toolInput: string = '';
  @State toolOutput: string = '';
  @State unitMode: string = 'm_ft';
  @State networkInFlight: boolean = false;
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;

  private readonly accentColor: string = '#0A84FF';
  private readonly base64Chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  private readonly categories: string[] = ['all', 'network', 'system', 'develop'];
  private readonly tools: ToolboxItem[] = [
    { titleKey: 'toolbox.topology', subtitleKey: 'toolbox.topologySub', category: 'network', icon: $rawfile('settings_network.svg'), color: '#8B5CF6', bgColor: '#F3E8FF' },
    { titleKey: 'toolbox.speed', subtitleKey: 'toolbox.speedSub', category: 'network', icon: $rawfile('settings_timer.svg'), color: '#EF4444', bgColor: '#FFE4E6' },
    { titleKey: 'toolbox.nginx', subtitleKey: 'toolbox.nginxSub', category: 'network', icon: $rawfile('settings_server.svg'), color: '#F97316', bgColor: '#FFEDD5' },
    { titleKey: 'toolbox.ipInfo', subtitleKey: 'toolbox.ipInfoSub', category: 'network', icon: $rawfile('settings_router.svg'), color: '#0EA5E9', bgColor: '#E0F2FE' },
    { titleKey: 'toolbox.ping', subtitleKey: 'toolbox.pingSub', category: 'network', icon: $rawfile('settings_update.svg'), color: '#10B981', bgColor: '#D1FAE5' },
    { titleKey: 'toolbox.portScan', subtitleKey: 'toolbox.portScanSub', category: 'network', icon: $rawfile('settings_cpu.svg'), color: '#7C3AED', bgColor: '#EDE9FE' },
    { titleKey: 'toolbox.systemInfo', subtitleKey: 'toolbox.systemInfoSub', category: 'system', icon: $rawfile('settings_info.svg'), color: '#0A84FF', bgColor: '#DBEAFE' },
    { titleKey: 'toolbox.storage', subtitleKey: 'toolbox.storageSub', category: 'system', icon: $rawfile('settings_folder.svg'), color: '#22C55E', bgColor: '#DCFCE7' },
    { titleKey: 'toolbox.audit', subtitleKey: 'toolbox.auditSub', category: 'system', icon: $rawfile('settings_shield.svg'), color: '#F59E0B', bgColor: '#FEF3C7' },
    { titleKey: 'toolbox.json', subtitleKey: 'toolbox.jsonSub', category: 'develop', icon: $rawfile('settings_tune.svg'), color: '#4661E6', bgColor: '#E0E7FF' },
    { titleKey: 'toolbox.encode', subtitleKey: 'toolbox.encodeSub', category: 'develop', icon: $rawfile('settings_shield.svg'), color: '#7C3AED', bgColor: '#EDE9FE' },
    { titleKey: 'toolbox.qr', subtitleKey: 'toolbox.qrSub', category: 'develop', icon: $rawfile('settings_update.svg'), color: '#10B981', bgColor: '#D1FAE5' },
    { titleKey: 'toolbox.color', subtitleKey: 'toolbox.colorSub', category: 'develop', icon: $rawfile('settings_palette.svg'), color: '#E11D48', bgColor: '#FCE7F3' },
    { titleKey: 'toolbox.text', subtitleKey: 'toolbox.textSub', category: 'develop', icon: $rawfile('settings_language.svg'), color: '#3347A8', bgColor: '#E0E7FF' },
    { titleKey: 'toolbox.unit', subtitleKey: 'toolbox.unitSub', category: 'develop', icon: $rawfile('settings_update.svg'), color: '#EA580C', bgColor: '#FFEDD5' }
  ];

  private t(key: string): string {
    return I18n.t(this.language, key);
  }

  private textPrimary(): string {
    return AppTheme.textPrimary(this.themeMode);
  }

  private textSecond(): string {
    return AppTheme.textSecond(this.themeMode);
  }

  private textMuted(): string {
    return AppTheme.textMuted(this.themeMode);
  }

  private pageBg(): string {
    return AppTheme.pageBg(this.themeMode);
  }

  private cardBg(): string {
    return AppTheme.cardBg(this.themeMode);
  }

  private elevatedBg(): string {
    return AppTheme.elevatedBg(this.themeMode);
  }

  private chipBg(): string {
    return AppTheme.chipBg(this.themeMode);
  }

  private categoryTitle(category: string): string {
    if (category === 'network') {
      return this.t('toolbox.network');
    }
    if (category === 'system') {
      return this.t('toolbox.systemCategory');
    }
    if (category === 'develop') {
      return this.t('toolbox.develop');
    }
    return this.t('common.all');
  }

  private filteredTools(category: string): ToolboxItem[] {
    const keyword: string = this.keyword.trim().toLowerCase();
    return this.tools.filter((item: ToolboxItem) => {
      const categoryMatched: boolean = category === 'all' || item.category === category;
      if (!categoryMatched) {
        return false;
      }
      if (keyword.length === 0) {
        return true;
      }
      const title: string = this.t(item.titleKey).toLowerCase();
      const subtitle: string = this.t(item.subtitleKey).toLowerCase();
      return title.includes(keyword) || subtitle.includes(keyword);
    });
  }

  private defaultInputFor(toolKey: string): string {
    if (toolKey === 'toolbox.json') {
      return '{"name":"OpenTabSsh","port":22,"tags":["ssh","ohos"]}';
    }
    if (toolKey === 'toolbox.encode') {
      return 'OpenTabSsh HarmonyOS';
    }
    if (toolKey === 'toolbox.text') {
      return 'OpenTabSsh HarmonyOS\nSSH, SFTP, Terminal';
    }
    if (toolKey === 'toolbox.color') {
      return '#0A84FF';
    }
    if (toolKey === 'toolbox.unit') {
      return '1';
    }
    if (toolKey === 'toolbox.speed') {
      return 'https://www.example.com/';
    }
    if (toolKey === 'toolbox.nginx') {
      return 'upstream app { server 10.0.0.2:8080; }\nset $target http://app;\ninclude conf.d/*.conf;\nserver { listen 80; server_name example.com; location / { proxy_pass $target; } }';
    }
    if (toolKey === 'toolbox.ping') {
      return 'www.example.com 443';
    }
    if (toolKey === 'toolbox.portScan') {
      return '127.0.0.1 22,80,443';
    }
    if (toolKey === 'toolbox.qr') {
      return 'ssh://user@example.com:22';
    }
    return '';
  }

  private openTool(item: ToolboxItem): void {
    if (item.titleKey === 'toolbox.audit') {
      router.pushUrl({ url: 'pages/AuditLogPage' });
      return;
    }

    const runnable: boolean = item.titleKey === 'toolbox.json' || item.titleKey === 'toolbox.encode' ||
      item.titleKey === 'toolbox.text' || item.titleKey === 'toolbox.color' || item.titleKey === 'toolbox.unit' ||
      item.titleKey === 'toolbox.systemInfo' || item.titleKey === 'toolbox.storage' ||
      item.titleKey === 'toolbox.ipInfo' || item.titleKey === 'toolbox.topology' ||
      item.titleKey === 'toolbox.speed' || item.titleKey === 'toolbox.nginx' ||
      item.titleKey === 'toolbox.ping' || item.titleKey === 'toolbox.portScan' ||
      item.titleKey === 'toolbox.qr';
    if (!runnable) {
      promptAction.showToast({ message: this.t(item.titleKey) + this.t('toolbox.pending'), duration: 1800 });
      return;
    }

    this.activeToolKey = item.titleKey;
    this.toolInput = this.defaultInputFor(item.titleKey);
    this.toolOutput = '';
    if (item.titleKey === 'toolbox.json') {
      this.formatJson(true);
    } else if (item.titleKey === 'toolbox.encode') {
      this.convertBase64(true);
    } else if (item.titleKey === 'toolbox.text') {
      this.analyzeText();
    } else if (item.titleKey === 'toolbox.color') {
      this.convertColor();
    } else if (item.titleKey === 'toolbox.unit') {
      this.convertUnit('m_ft');
    } else if (item.titleKey === 'toolbox.systemInfo') {
      this.showSystemInfo();
    } else if (item.titleKey === 'toolbox.storage') {
      this.showStorageInfo();
    } else if (item.titleKey === 'toolbox.ipInfo') {
      this.showIpInfo();
    } else if (item.titleKey === 'toolbox.topology') {
      this.showTopologySummary();
    } else if (item.titleKey === 'toolbox.nginx') {
      this.analyzeNginxConfig();
    } else if (item.titleKey === 'toolbox.speed') {
      this.toolOutput = this.t('toolbox.speedReady');
    } else if (item.titleKey === 'toolbox.ping') {
      this.toolOutput = this.t('toolbox.tcpProbeReady');
    } else if (item.titleKey === 'toolbox.portScan') {
      this.toolOutput = this.t('toolbox.portScanReady');
    } else if (item.titleKey === 'toolbox.qr') {
      this.generateQrPayload();
    }
  }

  private closeTool(): void {
    this.activeToolKey = '';
    this.toolInput = '';
    this.toolOutput = '';
  }

  private errorMessage(error: Error): string {
    if (error.message !== undefined && error.message.length > 0) {
      return error.message;
    }
    return this.t('toolbox.errorUnknown');
  }

  private formatJson(pretty: boolean): void {
    try {
      const parsed: Object = JSON.parse(this.toolInput) as Object;
      this.toolOutput = JSON.stringify(parsed, null, pretty ? 2 : 0);
    } catch (error) {
      this.toolOutput = this.t('toolbox.jsonError') + this.errorMessage(error as Error);
    }
  }

  private utf8Bytes(text: string): number[] {
    const bytes: number[] = [];
    for (let i = 0; i < text.length; i++) {
      let code: number = text.charCodeAt(i);
      if (code >= 0xD800 && code <= 0xDBFF && i + 1 < text.length) {
        const next: number = text.charCodeAt(i + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          code = 0x10000 + ((code - 0xD800) << 10) + (next - 0xDC00);
          i++;
        }
      }
      if (code <= 0x7F) {
        bytes.push(code);
      } else if (code <= 0x7FF) {
        bytes.push(0xC0 | (code >> 6));
        bytes.push(0x80 | (code & 0x3F));
      } else if (code <= 0xFFFF) {
        bytes.push(0xE0 | (code >> 12));
        bytes.push(0x80 | ((code >> 6) & 0x3F));
        bytes.push(0x80 | (code & 0x3F));
      } else {
        bytes.push(0xF0 | (code >> 18));
        bytes.push(0x80 | ((code >> 12) & 0x3F));
        bytes.push(0x80 | ((code >> 6) & 0x3F));
        bytes.push(0x80 | (code & 0x3F));
      }
    }
    return bytes;
  }

  private textFromUtf8(bytes: number[]): string {
    let result: string = '';
    let i: number = 0;
    while (i < bytes.length) {
      const first: number = bytes[i++];
      if (first < 0x80) {
        result += String.fromCharCode(first);
      } else if ((first & 0xE0) === 0xC0 && i < bytes.length) {
        const second: number = bytes[i++];
        result += String.fromCharCode(((first & 0x1F) << 6) | (second & 0x3F));
      } else if ((first & 0xF0) === 0xE0 && i + 1 < bytes.length) {
        const second: number = bytes[i++];
        const third: number = bytes[i++];
        result += String.fromCharCode(((first & 0x0F) << 12) | ((second & 0x3F) << 6) | (third & 0x3F));
      } else if ((first & 0xF8) === 0xF0 && i + 2 < bytes.length) {
        const second: number = bytes[i++];
        const third: number = bytes[i++];
        const fourth: number = bytes[i++];
        const code: number = ((first & 0x07) << 18) | ((second & 0x3F) << 12) |
          ((third & 0x3F) << 6) | (fourth & 0x3F);
        const shifted: number = code - 0x10000;
        result += String.fromCharCode(0xD800 + (shifted >> 10), 0xDC00 + (shifted & 0x3FF));
      }
    }
    return result;
  }

  private base64Encode(text: string): string {
    const bytes: number[] = this.utf8Bytes(text);
    let output: string = '';
    for (let i = 0; i < bytes.length; i += 3) {
      const b1: number = bytes[i];
      const b2: number = i + 1 < bytes.length ? bytes[i + 1] : 0;
      const b3: number = i + 2 < bytes.length ? bytes[i + 2] : 0;
      output += this.base64Chars.charAt(b1 >> 2);
      output += this.base64Chars.charAt(((b1 & 0x03) << 4) | (b2 >> 4));
      output += i + 1 < bytes.length ? this.base64Chars.charAt(((b2 & 0x0F) << 2) | (b3 >> 6)) : '=';
      output += i + 2 < bytes.length ? this.base64Chars.charAt(b3 & 0x3F) : '=';
    }
    return output;
  }

  private base64Decode(text: string): string {
    const clean: string = text.replace(/[^A-Za-z0-9+/=]/g, '');
    const bytes: number[] = [];
    for (let i = 0; i < clean.length; i += 4) {
      const c1: number = this.base64Chars.indexOf(clean.charAt(i));
      const c2: number = this.base64Chars.indexOf(clean.charAt(i + 1));
      const c3: number = clean.charAt(i + 2) === '=' ? -1 : this.base64Chars.indexOf(clean.charAt(i + 2));
      const c4: number = clean.charAt(i + 3) === '=' ? -1 : this.base64Chars.indexOf(clean.charAt(i + 3));
      if (c1 < 0 || c2 < 0) {
        throw new Error(this.t('toolbox.base64Error'));
      }
      bytes.push((c1 << 2) | (c2 >> 4));
      if (c3 >= 0) {
        bytes.push(((c2 & 0x0F) << 4) | (c3 >> 2));
      }
      if (c3 >= 0 && c4 >= 0) {
        bytes.push(((c3 & 0x03) << 6) | c4);
      }
    }
    return this.textFromUtf8(bytes);
  }

  private convertBase64(encode: boolean): void {
    try {
      this.toolOutput = encode ? this.base64Encode(this.toolInput) : this.base64Decode(this.toolInput);
    } catch (error) {
      this.toolOutput = this.t('toolbox.convertError') + this.errorMessage(error as Error);
    }
  }

  private hashText(): void {
    const bytes: number[] = this.utf8Bytes(this.toolInput);
    let hash: number = 0x811C9DC5;
    for (let i = 0; i < bytes.length; i++) {
      hash = hash ^ bytes[i];
      hash = (hash + ((hash << 1) + (hash << 4) + (hash << 7) + (hash << 8) + (hash << 24))) >>> 0;
    }
    const hex: string = ('00000000' + hash.toString(16).toUpperCase()).slice(-8);
    this.toolOutput = 'FNV-1a 32-bit: ' + hex + '\n' + this.t('toolbox.hashNote');
  }

  private analyzeText(): void {
    const trimmed: string = this.toolInput.trim();
    const words: string[] = trimmed.length === 0 ? [] : trimmed.split(/\s+/);
    const lines: string[] = this.toolInput.length === 0 ? [] : this.toolInput.split(/\r\n|\r|\n/);
    const bytes: number[] = this.utf8Bytes(this.toolInput);
    this.toolOutput = this.t('toolbox.textChars') + this.toolInput.length.toString() + '\n' +
      this.t('toolbox.textWords') + words.length.toString() + '\n' +
      this.t('toolbox.textLines') + lines.length.toString() + '\n' +
      this.t('toolbox.textBytes') + bytes.length.toString();
  }

  private convertColor(): void {
    const input: string = this.toolInput.trim();
    let r: number = 0;
    let g: number = 0;
    let b: number = 0;
    if (/^#[0-9a-fA-F]{6}$/.test(input)) {
      r = parseInt(input.slice(1, 3), 16);
      g = parseInt(input.slice(3, 5), 16);
      b = parseInt(input.slice(5, 7), 16);
    } else {
      const match: RegExpMatchArray | null = input.match(/^rgb\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3})\)$/i);
      if (match === null) {
        this.toolOutput = this.t('toolbox.colorError');
        return;
      }
      r = Number(match[1]);
      g = Number(match[2]);
      b = Number(match[3]);
    }
    if (r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255) {
      this.toolOutput = this.t('toolbox.colorError');
      return;
    }
    const hex: string = '#' + this.colorPart(r) + this.colorPart(g) + this.colorPart(b);
    const luminance: number = Math.round((0.2126 * r + 0.7152 * g + 0.0722 * b) * 100) / 100;
    this.toolOutput = 'HEX: ' + hex + '\nRGB: rgb(' + r.toString() + ', ' + g.toString() + ', ' + b.toString() +
      ')\n' + this.t('toolbox.colorLuma') + luminance.toString();
  }

  private colorPart(value: number): string {
    return ('0' + value.toString(16).toUpperCase()).slice(-2);
  }

  private convertUnit(mode: string): void {
    this.unitMode = mode;
    const value: number = Number(this.toolInput);
    if (isNaN(value)) {
      this.toolOutput = this.t('toolbox.numberError');
      return;
    }
    let result: number = value;
    let label: string = '';
    if (mode === 'm_ft') {
      result = value * 3.280839895;
      label = 'm -> ft';
    } else if (mode === 'ft_m') {
      result = value / 3.280839895;
      label = 'ft -> m';
    } else if (mode === 'c_f') {
      result = value * 9 / 5 + 32;
      label = 'C -> F';
    } else if (mode === 'f_c') {
      result = (value - 32) * 5 / 9;
      label = 'F -> C';
    } else if (mode === 'kg_lb') {
      result = value * 2.2046226218;
      label = 'kg -> lb';
    } else if (mode === 'lb_kg') {
      result = value / 2.2046226218;
      label = 'lb -> kg';
    }
    this.toolOutput = label + '\n' + value.toString() + ' = ' + this.roundNumber(result);
  }

  private roundNumber(value: number): string {
    return (Math.round(value * 1000000) / 1000000).toString();
  }

  private showSystemInfo(): void {
    this.toolOutput = 'OpenTabSsh\nBundle: com.open.tabssh\nRuntime: HarmonyOS / ArkTS\n' +
      this.t('toolbox.savedHosts') + ProfileRepository.list().length.toString() + '\n' +
      this.t('settings.theme') + ': ' + (this.themeMode === THEME_LIGHT ? this.t('common.light') : this.t('common.dark')) +
      '\n' + this.t('settings.language') + ': ' + this.language;
  }

  private showStorageInfo(): void {
    this.toolOutput = this.t('toolbox.storageLocal') + '\n' +
      this.t('toolbox.savedHosts') + ProfileRepository.list().length.toString() + '\n' +
      this.t('toolbox.auditCount') + ProfileRepository.listAuditLogs(999).length.toString();
  }

  private showIpInfo(): void {
    this.showNetworkDetails();
  }

  private async queryPublicIp(): Promise<void> {
    if (this.networkInFlight) {
      return;
    }
    this.networkInFlight = true;
    this.toolOutput = this.t('toolbox.running');
    const services: string[] = ['https://api.ipify.org', 'https://ifconfig.me/ip'];
    const failures: string[] = [];
    try {
      for (let i = 0; i < services.length; i++) {
        const request: http.HttpRequest = http.createHttp();
        try {
          const response: http.HttpResponse = await request.request(services[i], {
            method: http.RequestMethod.GET,
            expectDataType: http.HttpDataType.STRING,
            readTimeout: 8000,
            connectTimeout: 5000,
            header: {
              'User-Agent': 'OpenTabSsh-HarmonyOS'
            }
          });
          const responseText: string = this.responseToString(response.result);
          const publicIp: string = this.extractIpAddress(responseText);
          if (response.responseCode >= 200 && response.responseCode < 300 && publicIp.length > 0) {
            const hasDefaultNet: boolean = await connection.hasDefaultNet();
            this.toolOutput = this.t('toolbox.publicIp') + publicIp +
              '\n' + this.t('toolbox.publicIpSource') + services[i] +
              '\nHTTP ' + response.responseCode.toString() +
              '\n' + this.t('toolbox.defaultNet') +
              (hasDefaultNet ? this.t('common.enabled') : this.t('common.disabled')) +
              '\n' + this.t('toolbox.publicIpNote');
            return;
          }
          failures.push(services[i] + ' HTTP ' + response.responseCode.toString() + ' ' +
            this.t('toolbox.publicIpInvalid'));
        } catch (error) {
          failures.push(services[i] + ' ' + this.errorMessage(error as Error));
        } finally {
          request.destroy();
        }
      }
      this.toolOutput = this.t('toolbox.convertError') + failures.join('\n');
    } finally {
      this.networkInFlight = false;
    }
  }

  private parseEndpoint(input: string, defaultPorts: number[]): ParsedEndpoint {
    const normalized: string = input.trim().replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    if (normalized.length === 0) {
      throw new Error(this.t('toolbox.hostRequired'));
    }
    const tokens: string[] = normalized.split(/\s+/).filter((part: string) => part.length > 0);
    let hostToken: string = tokens[0];
    let portText: string = tokens.slice(1).join(',');
    let host: string = hostToken;
    if (hostToken.startsWith('[')) {
      const closeIndex: number = hostToken.indexOf(']');
      if (closeIndex > 1) {
        host = hostToken.substring(1, closeIndex);
        const suffix: string = hostToken.substring(closeIndex + 1);
        if (suffix.startsWith(':')) {
          portText = suffix.substring(1) + (portText.length > 0 ? ',' + portText : '');
        }
      }
    } else {
      const firstColon: number = hostToken.indexOf(':');
      const lastColon: number = hostToken.lastIndexOf(':');
      if (firstColon > 0 && firstColon === lastColon && lastColon < hostToken.length - 1) {
        host = hostToken.substring(0, lastColon);
        portText = hostToken.substring(lastColon + 1) + (portText.length > 0 ? ',' + portText : '');
      }
    }
    const ports: number[] = this.parsePorts(portText, defaultPorts);
    if (host.trim().length === 0) {
      throw new Error(this.t('toolbox.hostRequired'));
    }
    return { host: host.trim(), ports: ports };
  }

  private parsePorts(input: string, defaultPorts: number[]): number[] {
    if (input.trim().length === 0) {
      return defaultPorts;
    }
    const parts: string[] = input.split(/[,\s]+/).filter((part: string) => part.length > 0);
    const ports: number[] = [];
    for (let i = 0; i < parts.length; i++) {
      const part: string = parts[i];
      if (part.indexOf('-') > 0) {
        const rangeParts: string[] = part.split('-');
        if (rangeParts.length !== 2) {
          throw new Error(this.t('toolbox.portInvalid'));
        }
        const start: number = Number(rangeParts[0]);
        const end: number = Number(rangeParts[1]);
        if (!this.isValidPort(start) || !this.isValidPort(end) || end < start) {
          throw new Error(this.t('toolbox.portInvalid'));
        }
        for (let port: number = start; port <= end && ports.length < 32; port++) {
          this.addUniquePort(ports, port);
        }
      } else {
        const port: number = Number(part);
        if (!this.isValidPort(port)) {
          throw new Error(this.t('toolbox.portInvalid'));
        }
        this.addUniquePort(ports, port);
      }
      if (ports.length >= 32) {
        break;
      }
    }
    if (ports.length === 0) {
      throw new Error(this.t('toolbox.portInvalid'));
    }
    return ports;
  }

  private addUniquePort(ports: number[], port: number): void {
    if (ports.indexOf(port) < 0) {
      ports.push(port);
    }
  }

  private isValidPort(port: number): boolean {
    return Number.isInteger(port) && port > 0 && port <= 65535;
  }

  private isIpv4Literal(host: string): boolean {
    if (!/^\d{1,3}(\.\d{1,3}){3}$/.test(host)) {
      return false;
    }
    const parts: string[] = host.split('.');
    for (let i = 0; i < parts.length; i++) {
      const value: number = Number(parts[i]);
      if (value < 0 || value > 255) {
        return false;
      }
    }
    return true;
  }

  private isIpv6Literal(host: string): boolean {
    return host.indexOf(':') >= 0 && /^[0-9a-fA-F:]+$/.test(host);
  }

  private ipv4ToNumber(address: string): number {
    const parts: string[] = address.split('.');
    return Number(parts[0]) * 16777216 + Number(parts[1]) * 65536 + Number(parts[2]) * 256 + Number(parts[3]);
  }

  private numberToIpv4(value: number): string {
    const a: number = Math.floor(value / 16777216) % 256;
    const b: number = Math.floor(value / 65536) % 256;
    const c: number = Math.floor(value / 256) % 256;
    const d: number = value % 256;
    return a.toString() + '.' + b.toString() + '.' + c.toString() + '.' + d.toString();
  }

  private addressFamily(host: string): number {
    return this.isIpv6Literal(host) ? 2 : 1;
  }

  private async resolveHost(host: string): Promise<string[]> {
    if (this.isIpv4Literal(host) || this.isIpv6Literal(host)) {
      return [host];
    }
    const defaultNet: connection.NetHandle = await connection.getDefaultNet();
    const addresses: connection.NetAddress[] = await defaultNet.getAddressesByName(host);
    const result: string[] = [];
    for (let i = 0; i < addresses.length && result.length < 4; i++) {
      const address: string = addresses[i].address;
      if (address.length > 0 && result.indexOf(address) < 0) {
        result.push(address);
      }
    }
    if (result.length === 0) {
      throw new Error(this.t('toolbox.dnsEmpty'));
    }
    return result;
  }

  private async probeTcp(host: string, port: number, timeoutMs: number): Promise<TcpProbeResult> {
    const addresses: string[] = await this.resolveHost(host);
    const address: string = addresses[0];
    const tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
    const start: number = new Date().getTime();
    try {
      await tcp.connect({
        address: {
          address: address,
          port: port,
          family: this.addressFamily(address)
        },
        timeout: timeoutMs
      });
      const elapsed: number = new Date().getTime() - start;
      return { host: host, address: address, port: port, ok: true, elapsedMs: elapsed, detail: this.t('toolbox.tcpOpen') };
    } catch (error) {
      const elapsed: number = new Date().getTime() - start;
      return {
        host: host,
        address: address,
        port: port,
        ok: false,
        elapsedMs: elapsed,
        detail: this.errorMessage(error as Error)
      };
    } finally {
      try {
        await tcp.close();
      } catch (error) {
      }
    }
  }

  private async runConnectivityTest(): Promise<void> {
    if (this.networkInFlight) {
      return;
    }
    this.networkInFlight = true;
    this.toolOutput = this.t('toolbox.running');
    try {
      const endpoint: ParsedEndpoint = this.parseEndpoint(this.toolInput, [443]);
      const hasDefaultNet: boolean = await connection.hasDefaultNet();
      const addresses: string[] = await this.resolveHost(endpoint.host);
      const result: TcpProbeResult = await this.probeTcp(endpoint.host, endpoint.ports[0], 3000);
      this.toolOutput = this.t('toolbox.defaultNet') + (hasDefaultNet ? this.t('common.enabled') : this.t('common.disabled')) +
        '\nDNS: ' + addresses.join(', ') +
        '\nTCP ' + endpoint.host + ':' + endpoint.ports[0].toString() + ' -> ' +
        (result.ok ? this.t('toolbox.tcpOpen') : this.t('toolbox.tcpClosed')) +
        ' (' + result.elapsedMs.toString() + ' ms)' +
        '\n' + this.t('toolbox.icmpNote');
    } catch (error) {
      this.toolOutput = this.t('toolbox.convertError') + this.errorMessage(error as Error);
    } finally {
      this.networkInFlight = false;
    }
  }

  private async runPortScan(): Promise<void> {
    if (this.networkInFlight) {
      return;
    }
    this.networkInFlight = true;
    this.toolOutput = this.t('toolbox.running');
    try {
      const endpoint: ParsedEndpoint = this.parseEndpoint(this.toolInput, [22, 80, 443]);
      const addresses: string[] = await this.resolveHost(endpoint.host);
      const lines: string[] = [
        this.t('toolbox.scanTarget') + endpoint.host,
        'DNS: ' + addresses.join(', '),
        this.t('toolbox.scanLimit')
      ];
      for (let i = 0; i < endpoint.ports.length; i++) {
        const result: TcpProbeResult = await this.probeTcp(endpoint.host, endpoint.ports[i], 1500);
        lines.push(result.port.toString() + '/tcp ' +
          (result.ok ? this.t('toolbox.tcpOpen') : this.t('toolbox.tcpClosed')) +
          ' ' + result.elapsedMs.toString() + ' ms');
      }
      this.toolOutput = lines.join('\n');
    } catch (error) {
      this.toolOutput = this.t('toolbox.convertError') + this.errorMessage(error as Error);
    } finally {
      this.networkInFlight = false;
    }
  }

  private defaultIpv4Link(properties: connection.ConnectionProperties): Ipv4Link | undefined {
    for (let i = 0; i < properties.linkAddresses.length; i++) {
      const address: string = properties.linkAddresses[i].address.address;
      const prefixLength: number = properties.linkAddresses[i].prefixLength;
      if (this.isIpv4Literal(address) && prefixLength >= 16 && prefixLength <= 30) {
        return { address: address, prefixLength: prefixLength };
      }
    }
    return undefined;
  }

  private addSubnetCandidate(candidates: string[], host: string, localAddress: string, network: number,
    blockSize: number): void {
    if (!this.isIpv4Literal(host) || host === localAddress || candidates.indexOf(host) >= 0) {
      return;
    }
    const value: number = this.ipv4ToNumber(host);
    if (value <= network || value >= network + blockSize - 1) {
      return;
    }
    candidates.push(host);
  }

  private subnetCandidates(properties: connection.ConnectionProperties, profiles: ConnectionProfile[]): string[] {
    const link: Ipv4Link | undefined = this.defaultIpv4Link(properties);
    if (link === undefined) {
      return [];
    }
    const localValue: number = this.ipv4ToNumber(link.address);
    const blockSize: number = Math.pow(2, 32 - link.prefixLength);
    const network: number = Math.floor(localValue / blockSize) * blockSize;
    const candidates: string[] = [];
    for (let i = 0; i < properties.routes.length && candidates.length < 16; i++) {
      if (properties.routes[i].hasGateway) {
        this.addSubnetCandidate(candidates, properties.routes[i].gateway.address, link.address, network, blockSize);
      }
    }
    for (let i = 0; i < properties.dnses.length && candidates.length < 16; i++) {
      this.addSubnetCandidate(candidates, properties.dnses[i].address, link.address, network, blockSize);
    }
    for (let i = 0; i < profiles.length && candidates.length < 16; i++) {
      this.addSubnetCandidate(candidates, profiles[i].host, link.address, network, blockSize);
    }
    const start: number = network + 1;
    const end: number = network + blockSize - 2;
    for (let value: number = start; value <= end && candidates.length < 16; value++) {
      this.addSubnetCandidate(candidates, this.numberToIpv4(value), link.address, network, blockSize);
    }
    return candidates;
  }

  private subnetLabel(link: Ipv4Link): string {
    const localValue: number = this.ipv4ToNumber(link.address);
    const blockSize: number = Math.pow(2, 32 - link.prefixLength);
    const network: number = Math.floor(localValue / blockSize) * blockSize;
    return this.numberToIpv4(network) + '/' + link.prefixLength.toString();
  }

  private async discoverSubnet(): Promise<void> {
    if (this.networkInFlight) {
      return;
    }
    this.networkInFlight = true;
    this.toolOutput = this.t('toolbox.running');
    try {
      const hasDefaultNet: boolean = await connection.hasDefaultNet();
      if (!hasDefaultNet) {
        this.toolOutput = this.t('toolbox.defaultNet') + this.t('common.disabled');
        return;
      }
      const defaultNet: connection.NetHandle = await connection.getDefaultNet();
      const properties: connection.ConnectionProperties = await connection.getConnectionProperties(defaultNet);
      const link: Ipv4Link | undefined = this.defaultIpv4Link(properties);
      if (link === undefined) {
        this.toolOutput = this.t('toolbox.discoveryNoIpv4');
        return;
      }
      const profiles: ConnectionProfile[] = ProfileRepository.list();
      const candidates: string[] = this.subnetCandidates(properties, profiles);
      const lines: string[] = [
        this.t('toolbox.discoveryRange') + this.subnetLabel(link),
        this.t('toolbox.interfaceName') + properties.interfaceName,
        this.t('toolbox.discoveryLimit')
      ];
      let found: number = 0;
      const ports: number[] = [22, 80, 443];
      for (let i = 0; i < candidates.length; i++) {
        const openPorts: string[] = [];
        for (let p = 0; p < ports.length; p++) {
          const result: TcpProbeResult = await this.probeTcp(candidates[i], ports[p], 600);
          if (result.ok) {
            openPorts.push(ports[p].toString() + '/tcp ' + result.elapsedMs.toString() + ' ms');
          }
        }
        if (openPorts.length > 0) {
          found++;
          lines.push(candidates[i] + ' -> ' + openPorts.join(', '));
        }
      }
      if (found === 0) {
        lines.push(this.t('toolbox.discoveryNone'));
      } else {
        lines.splice(3, 0, this.t('toolbox.discoveryFound') + found.toString());
      }
      this.toolOutput = lines.join('\n');
    } catch (error) {
      this.toolOutput = this.t('toolbox.convertError') + this.errorMessage(error as Error);
    } finally {
      this.networkInFlight = false;
    }
  }

  private responseBytes(result: string | Object | ArrayBuffer): number {
    if (typeof result === 'string') {
      return this.utf8Bytes(result).length;
    }
    if (result instanceof ArrayBuffer) {
      return result.byteLength;
    }
    return this.utf8Bytes(JSON.stringify(result)).length;
  }

  private responseToString(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result;
    }
    if (result instanceof ArrayBuffer) {
      const view: Uint8Array = new Uint8Array(result);
      const bytes: number[] = [];
      for (let i = 0; i < view.length; i++) {
        bytes.push(view[i]);
      }
      return this.textFromUtf8(bytes);
    }
    return JSON.stringify(result);
  }

  private extractIpAddress(text: string): string {
    const ipv4Match: RegExpMatchArray | null = text.match(/\b(?:\d{1,3}\.){3}\d{1,3}\b/);
    if (ipv4Match !== null && this.isIpv4Literal(ipv4Match[0])) {
      return ipv4Match[0];
    }
    const ipv6Match: RegExpMatchArray | null = text.match(/\b[0-9a-fA-F]{1,4}(?::[0-9a-fA-F]{0,4}){2,7}\b/);
    if (ipv6Match !== null && this.isIpv6Literal(ipv6Match[0])) {
      return ipv6Match[0];
    }
    return '';
  }

  private async runSpeedTest(): Promise<void> {
    if (this.networkInFlight) {
      return;
    }
    this.networkInFlight = true;
    this.toolOutput = this.t('toolbox.running');
    const request: http.HttpRequest = http.createHttp();
    try {
      const url: string = this.toolInput.trim();
      if (!/^https?:\/\//i.test(url)) {
        throw new Error(this.t('toolbox.urlInvalid'));
      }
      const start: number = new Date().getTime();
      const response: http.HttpResponse = await request.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        readTimeout: 10000,
        connectTimeout: 5000
      });
      const elapsed: number = Math.max(1, new Date().getTime() - start);
      const bytes: number = this.responseBytes(response.result);
      const kbps: number = Math.round(bytes * 8 / elapsed);
      this.toolOutput = 'HTTP ' + response.responseCode.toString() +
        '\n' + this.t('toolbox.downloadedBytes') + bytes.toString() +
        '\n' + this.t('toolbox.elapsed') + elapsed.toString() + ' ms' +
        '\n' + this.t('toolbox.throughput') + kbps.toString() + ' kbps';
    } catch (error) {
      this.toolOutput = this.t('toolbox.convertError') + this.errorMessage(error as Error);
    } finally {
      request.destroy();
      this.networkInFlight = false;
    }
  }

  private buildUploadPayload(bytes: number): string {
    const chunk: string = 'OpenTabSsh-HarmonyOS-upload-sample-0123456789\n';
    let output: string = '';
    while (output.length < bytes) {
      output += chunk;
    }
    return output.substring(0, bytes);
  }

  private async runUploadTest(): Promise<void> {
    if (this.networkInFlight) {
      return;
    }
    this.networkInFlight = true;
    this.toolOutput = this.t('toolbox.running');
    const request: http.HttpRequest = http.createHttp();
    try {
      const url: string = this.toolInput.trim();
      if (!/^https?:\/\//i.test(url)) {
        throw new Error(this.t('toolbox.urlInvalid'));
      }
      const payload: string = this.buildUploadPayload(65536);
      const uploadBytes: number = this.utf8Bytes(payload).length;
      const start: number = new Date().getTime();
      const response: http.HttpResponse = await request.request(url, {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        extraData: payload,
        readTimeout: 10000,
        connectTimeout: 5000,
        header: {
          'Content-Type': 'text/plain; charset=utf-8',
          'User-Agent': 'OpenTabSsh-HarmonyOS'
        }
      });
      const elapsed: number = Math.max(1, new Date().getTime() - start);
      const kbps: number = Math.round(uploadBytes * 8 / elapsed);
      const responseBytes: number = this.responseBytes(response.result);
      this.toolOutput = 'HTTP ' + response.responseCode.toString() +
        '\n' + this.t('toolbox.uploadedBytes') + uploadBytes.toString() +
        '\n' + this.t('toolbox.downloadedBytes') + responseBytes.toString() +
        '\n' + this.t('toolbox.elapsed') + elapsed.toString() + ' ms' +
        '\n' + this.t('toolbox.throughput') + kbps.toString() + ' kbps' +
        '\n' + this.t('toolbox.uploadNote');
    } catch (error) {
      this.toolOutput = this.t('toolbox.convertError') + this.errorMessage(error as Error);
    } finally {
      request.destroy();
      this.networkInFlight = false;
    }
  }

  private async showNetworkDetails(): Promise<void> {
    if (this.networkInFlight) {
      return;
    }
    this.networkInFlight = true;
    this.toolOutput = this.t('toolbox.running');
    try {
      const hasDefaultNet: boolean = await connection.hasDefaultNet();
      const lines: string[] = [
        'Loopback: 127.0.0.1',
        'System: ohos',
        this.t('toolbox.defaultNet') + (hasDefaultNet ? this.t('common.enabled') : this.t('common.disabled'))
      ];
      if (hasDefaultNet) {
        const defaultNet: connection.NetHandle = await connection.getDefaultNet();
        const properties: connection.ConnectionProperties = await connection.getConnectionProperties(defaultNet);
        lines.push(this.t('toolbox.interfaceName') + properties.interfaceName);
        lines.push('MTU: ' + properties.mtu.toString());
        lines.push(this.t('toolbox.linkAddresses') + this.formatLinkAddresses(properties.linkAddresses));
        lines.push('DNS: ' + this.formatNetAddresses(properties.dnses));
        lines.push(this.t('toolbox.gateway') + this.formatGateways(properties.routes));
        lines.push(this.t('toolbox.routes') + this.formatRoutes(properties.routes));
      }
      lines.push(this.t('toolbox.ipNoteResolved'));
      this.toolOutput = lines.join('\n');
    } catch (error) {
      this.toolOutput = this.t('toolbox.convertError') + this.errorMessage(error as Error);
    } finally {
      this.networkInFlight = false;
    }
  }

  private formatNetAddresses(addresses: connection.NetAddress[]): string {
    if (addresses.length === 0) {
      return this.t('toolbox.none');
    }
    const values: string[] = [];
    for (let i = 0; i < addresses.length; i++) {
      if (addresses[i].address.length > 0) {
        values.push(addresses[i].address);
      }
    }
    return values.length > 0 ? values.join(', ') : this.t('toolbox.none');
  }

  private formatAddressFamily(address: connection.NetAddress): string {
    if (address.family === undefined) {
      return 'family unknown';
    }
    if (address.family === 1) {
      return 'IPv4';
    }
    if (address.family === 2) {
      return 'IPv6';
    }
    return 'family ' + address.family.toString();
  }

  private formatLinkAddresses(addresses: connection.LinkAddress[]): string {
    if (addresses.length === 0) {
      return this.t('toolbox.none');
    }
    const values: string[] = [];
    for (let i = 0; i < addresses.length; i++) {
      values.push(addresses[i].address.address + '/' + addresses[i].prefixLength.toString() +
        ' ' + this.formatAddressFamily(addresses[i].address));
    }
    return values.join(', ');
  }

  private formatGateways(routes: connection.RouteInfo[]): string {
    const values: string[] = [];
    for (let i = 0; i < routes.length; i++) {
      if (routes[i].hasGateway && routes[i].gateway.address.length > 0 && values.indexOf(routes[i].gateway.address) < 0) {
        values.push(routes[i].gateway.address);
      }
    }
    return values.length > 0 ? values.join(', ') : this.t('toolbox.none');
  }

  private formatRoutes(routes: connection.RouteInfo[]): string {
    if (routes.length === 0) {
      return this.t('toolbox.none');
    }
    const values: string[] = [];
    for (let i = 0; i < routes.length && values.length < 8; i++) {
      const gateway: string = routes[i].hasGateway && routes[i].gateway.address.length > 0 ?
        routes[i].gateway.address : this.t('toolbox.none');
      values.push('route' + (i + 1).toString() + ' gateway=' + gateway);
    }
    return values.join('; ');
  }

  private async showTopologySummary(): Promise<void> {
    if (this.networkInFlight) {
      return;
    }
    this.networkInFlight = true;
    this.toolOutput = this.t('toolbox.running');
    try {
      const profiles: ConnectionProfile[] = ProfileRepository.list();
      const lines: string[] = [
        this.t('toolbox.topologyLocal'),
        this.t('toolbox.savedHosts') + profiles.length.toString()
      ];
      if (profiles.length === 0) {
        lines.push(this.t('workbench.noHosts'));
      } else {
        for (let i = 0; i < profiles.length && i < 8; i++) {
          lines.push('- ' + profiles[i].name + ' -> ' + profiles[i].username + '@' +
            profiles[i].host + ':' + profiles[i].port.toString());
        }
      }
      const hasDefaultNet: boolean = await connection.hasDefaultNet();
      lines.push(this.t('toolbox.defaultNet') + (hasDefaultNet ? this.t('common.enabled') : this.t('common.disabled')));
      if (hasDefaultNet) {
        const defaultNet: connection.NetHandle = await connection.getDefaultNet();
        const properties: connection.ConnectionProperties = await connection.getConnectionProperties(defaultNet);
        lines.push(this.t('toolbox.interfaceName') + properties.interfaceName);
        lines.push(this.t('toolbox.linkAddresses') + this.formatLinkAddresses(properties.linkAddresses));
        lines.push(this.t('toolbox.gateway') + this.formatGateways(properties.routes));
      }
      lines.push(this.t('toolbox.topologyNote'));
      this.toolOutput = lines.join('\n');
    } catch (error) {
      this.toolOutput = this.t('toolbox.convertError') + this.errorMessage(error as Error);
    } finally {
      this.networkInFlight = false;
    }
  }

  private stripNginxComment(line: string): string {
    const index: number = line.indexOf('#');
    return (index >= 0 ? line.substring(0, index) : line).trim();
  }

  private analyzeNginxConfig(): void {
    const normalized: string = this.toolInput.replace(/\{/g, '{\n').replace(/;/g, ';\n');
    const lines: string[] = normalized.split(/\r\n|\r|\n/);
    let serverCount: number = 0;
    const listens: string[] = [];
    const serverNames: string[] = [];
    const upstreams: string[] = [];
    const upstreamServers: string[] = [];
    const locations: string[] = [];
    const proxies: string[] = [];
    const includes: string[] = [];
    const variableNames: string[] = [];
    const variableValues: string[] = [];
    let currentUpstream: string = '';
    for (let i = 0; i < lines.length; i++) {
      const line: string = this.stripNginxComment(lines[i]);
      if (line.length === 0) {
        continue;
      }
      if (line === '}') {
        currentUpstream = '';
        continue;
      }
      if (/^server\s*\{/.test(line)) {
        serverCount++;
      }
      const upstream: RegExpMatchArray | null = line.match(/^upstream\s+([A-Za-z0-9_.-]+)/);
      if (upstream !== null) {
        upstreams.push(upstream[1]);
        currentUpstream = upstream[1];
      }
      const upstreamServer: RegExpMatchArray | null = line.match(/^server\s+([^;]+)/);
      if (upstreamServer !== null && currentUpstream.length > 0) {
        upstreamServers.push(currentUpstream + ' -> ' + upstreamServer[1].trim());
      }
      const listen: RegExpMatchArray | null = line.match(/^listen\s+([^;]+)/);
      if (listen !== null) {
        listens.push(listen[1].trim());
      }
      const serverName: RegExpMatchArray | null = line.match(/^server_name\s+([^;]+)/);
      if (serverName !== null) {
        serverNames.push(serverName[1].trim());
      }
      const location: RegExpMatchArray | null = line.match(/^location\s+([^\s{]+)/);
      if (location !== null) {
        locations.push(location[1].trim());
      }
      const include: RegExpMatchArray | null = line.match(/^include\s+([^;]+)/);
      if (include !== null) {
        includes.push(include[1].trim());
      }
      const variable: RegExpMatchArray | null = line.match(/^set\s+(\$[A-Za-z0-9_]+)\s+([^;]+)/);
      if (variable !== null) {
        variableNames.push(variable[1]);
        variableValues.push(variable[2].trim());
      }
      const proxy: RegExpMatchArray | null = line.match(/^proxy_pass\s+([^;]+)/);
      if (proxy !== null) {
        const rawProxy: string = proxy[1].trim();
        const expandedProxy: string = this.expandNginxVariables(rawProxy, variableNames, variableValues);
        proxies.push(rawProxy === expandedProxy ? rawProxy : rawProxy + ' -> ' + expandedProxy);
      }
    }
    this.toolOutput = 'server blocks: ' + serverCount.toString() +
      '\nlisten: ' + this.joinOrNone(listens) +
      '\nserver_name: ' + this.joinOrNone(serverNames) +
      '\nupstream: ' + this.joinOrNone(upstreams) +
      '\n' + this.t('toolbox.nginxUpstreamServers') + this.joinOrNone(upstreamServers) +
      '\nlocation: ' + this.joinOrNone(locations) +
      '\nproxy_pass: ' + this.joinOrNone(proxies) +
      '\ninclude: ' + this.joinOrNone(includes) +
      '\n' + this.t('toolbox.nginxVariables') + this.formatNginxVariables(variableNames, variableValues) +
      '\n' + this.t('toolbox.nginxNote');
  }

  private expandNginxVariables(value: string, names: string[], values: string[]): string {
    let output: string = value;
    for (let i = 0; i < names.length; i++) {
      output = output.split(names[i]).join(values[i]);
    }
    return output;
  }

  private formatNginxVariables(names: string[], values: string[]): string {
    if (names.length === 0) {
      return this.t('toolbox.none');
    }
    const output: string[] = [];
    for (let i = 0; i < names.length; i++) {
      output.push(names[i] + '=' + values[i]);
    }
    return output.join(', ');
  }

  private joinOrNone(values: string[]): string {
    return values.length > 0 ? values.join(', ') : this.t('toolbox.none');
  }

  private generateQrPayload(): void {
    const payload: string = this.toolInput.trim();
    if (payload.length === 0) {
      this.toolOutput = this.t('toolbox.inputPlaceholder');
      return;
    }
    try {
      const qr: QrMatrixResult = this.buildQrMatrix(payload);
      this.toolOutput = this.t('toolbox.qrPayload') + payload +
        '\n' + this.t('toolbox.textChars') + payload.length.toString() +
        '\n' + this.t('toolbox.textBytes') + this.utf8Bytes(payload).length.toString() +
        '\n' + this.t('toolbox.qrMatrix') + 'Version ' + qr.version.toString() + '-L Byte, ' +
        qr.size.toString() + 'x' + qr.size.toString() +
        '\n' + this.t('toolbox.qrCodewords') + qr.dataCodewords.toString() + ' data + ' +
        qr.eccCodewords.toString() + ' ecc' +
        '\n' + this.t('toolbox.qrLegend') +
        '\n' + qr.lines.join('\n') +
        '\n' + this.t('toolbox.qrNote');
    } catch (error) {
      this.toolOutput = this.t('toolbox.convertError') + this.errorMessage(error as Error);
    }
  }

  private appendBits(bits: number[], value: number, length: number): void {
    for (let i = length - 1; i >= 0; i--) {
      bits.push((value >>> i) & 1);
    }
  }

  private gfMul(left: number, right: number): number {
    let x: number = left;
    let y: number = right;
    let output: number = 0;
    while (y > 0) {
      if ((y & 1) !== 0) {
        output ^= x;
      }
      x <<= 1;
      if ((x & 0x100) !== 0) {
        x ^= 0x11D;
      }
      y >>>= 1;
    }
    return output & 0xFF;
  }

  private gfPow(power: number): number {
    let output: number = 1;
    for (let i = 0; i < power; i++) {
      output = this.gfMul(output, 2);
    }
    return output;
  }

  private rsGenerator(degree: number): number[] {
    let result: number[] = [1];
    for (let i = 0; i < degree; i++) {
      const next: number[] = [];
      for (let j = 0; j < result.length + 1; j++) {
        next.push(0);
      }
      const root: number = this.gfPow(i);
      for (let j = 0; j < result.length; j++) {
        next[j] ^= result[j];
        next[j + 1] ^= this.gfMul(result[j], root);
      }
      result = next;
    }
    return result;
  }

  private reedSolomonRemainder(data: number[], degree: number): number[] {
    const generator: number[] = this.rsGenerator(degree);
    const message: number[] = [];
    for (let i = 0; i < data.length; i++) {
      message.push(data[i]);
    }
    for (let i = 0; i < degree; i++) {
      message.push(0);
    }
    for (let i = 0; i < data.length; i++) {
      const factor: number = message[i];
      if (factor === 0) {
        continue;
      }
      for (let j = 0; j < generator.length; j++) {
        message[i + j] ^= this.gfMul(generator[j], factor);
      }
    }
    return message.slice(message.length - degree);
  }

  private setQrFunctionModule(modules: boolean[][], reserved: boolean[][], row: number, col: number,
    dark: boolean): void {
    if (row < 0 || col < 0 || row >= modules.length || col >= modules.length) {
      return;
    }
    modules[row][col] = dark;
    reserved[row][col] = true;
  }

  private drawQrFinder(modules: boolean[][], reserved: boolean[][], row: number, col: number): void {
    for (let dy = -1; dy <= 7; dy++) {
      for (let dx = -1; dx <= 7; dx++) {
        const r: number = row + dy;
        const c: number = col + dx;
        const inPattern: boolean = dx >= 0 && dx <= 6 && dy >= 0 && dy <= 6;
        const dark: boolean = inPattern && (dx === 0 || dx === 6 || dy === 0 || dy === 6 ||
          (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4));
        this.setQrFunctionModule(modules, reserved, r, c, dark);
      }
    }
  }

  private drawQrAlignment(modules: boolean[][], reserved: boolean[][], center: number): void {
    for (let dy = -2; dy <= 2; dy++) {
      for (let dx = -2; dx <= 2; dx++) {
        const distance: number = Math.max(Math.abs(dx), Math.abs(dy));
        this.setQrFunctionModule(modules, reserved, center + dy, center + dx, distance === 0 || distance === 2);
      }
    }
  }

  private reserveQrFormatAreas(modules: boolean[][], reserved: boolean[][]): void {
    const size: number = modules.length;
    for (let i = 0; i <= 8; i++) {
      this.setQrFunctionModule(modules, reserved, 8, i, false);
      this.setQrFunctionModule(modules, reserved, i, 8, false);
    }
    for (let i = 0; i < 8; i++) {
      this.setQrFunctionModule(modules, reserved, size - 1 - i, 8, false);
    }
    for (let i = 8; i < 15; i++) {
      this.setQrFunctionModule(modules, reserved, 8, size - 15 + i, false);
    }
  }

  private qrFormatBits(): number {
    const data: number = (1 << 3);
    let bits: number = data << 10;
    for (let i = 14; i >= 10; i--) {
      if (((bits >>> i) & 1) !== 0) {
        bits ^= 0x537 << (i - 10);
      }
    }
    return ((data << 10) | bits) ^ 0x5412;
  }

  private qrBit(value: number, index: number): boolean {
    return ((value >>> index) & 1) !== 0;
  }

  private drawQrFormatBits(modules: boolean[][], reserved: boolean[][]): void {
    const size: number = modules.length;
    const bits: number = this.qrFormatBits();
    for (let i = 0; i <= 5; i++) {
      this.setQrFunctionModule(modules, reserved, 8, i, this.qrBit(bits, i));
    }
    this.setQrFunctionModule(modules, reserved, 8, 7, this.qrBit(bits, 6));
    this.setQrFunctionModule(modules, reserved, 8, 8, this.qrBit(bits, 7));
    this.setQrFunctionModule(modules, reserved, 7, 8, this.qrBit(bits, 8));
    for (let i = 9; i < 15; i++) {
      this.setQrFunctionModule(modules, reserved, 14 - i, 8, this.qrBit(bits, i));
    }
    for (let i = 0; i < 8; i++) {
      this.setQrFunctionModule(modules, reserved, size - 1 - i, 8, this.qrBit(bits, i));
    }
    for (let i = 8; i < 15; i++) {
      this.setQrFunctionModule(modules, reserved, 8, size - 15 + i, this.qrBit(bits, i));
    }
  }

  private buildQrMatrix(payload: string): QrMatrixResult {
    const bytes: number[] = this.utf8Bytes(payload);
    if (bytes.length > 32) {
      throw new Error(this.t('toolbox.qrTooLong'));
    }
    const version: number = 2;
    const size: number = 25;
    const dataCodewords: number = 34;
    const eccCodewords: number = 10;
    const dataBits: number[] = [];
    this.appendBits(dataBits, 0x4, 4);
    this.appendBits(dataBits, bytes.length, 8);
    for (let i = 0; i < bytes.length; i++) {
      this.appendBits(dataBits, bytes[i], 8);
    }
    const capacityBits: number = dataCodewords * 8;
    const terminator: number = Math.min(4, capacityBits - dataBits.length);
    this.appendBits(dataBits, 0, terminator);
    while (dataBits.length % 8 !== 0) {
      dataBits.push(0);
    }
    const data: number[] = [];
    for (let i = 0; i < dataBits.length; i += 8) {
      let value: number = 0;
      for (let j = 0; j < 8; j++) {
        value = (value << 1) | dataBits[i + j];
      }
      data.push(value);
    }
    const pads: number[] = [0xEC, 0x11];
    let padIndex: number = 0;
    while (data.length < dataCodewords) {
      data.push(pads[padIndex % 2]);
      padIndex++;
    }
    const ecc: number[] = this.reedSolomonRemainder(data, eccCodewords);
    const codewords: number[] = data.concat(ecc);
    const bits: number[] = [];
    for (let i = 0; i < codewords.length; i++) {
      this.appendBits(bits, codewords[i], 8);
    }
    const modules: boolean[][] = [];
    const reserved: boolean[][] = [];
    for (let row = 0; row < size; row++) {
      const moduleRow: boolean[] = [];
      const reservedRow: boolean[] = [];
      for (let col = 0; col < size; col++) {
        moduleRow.push(false);
        reservedRow.push(false);
      }
      modules.push(moduleRow);
      reserved.push(reservedRow);
    }
    this.drawQrFinder(modules, reserved, 0, 0);
    this.drawQrFinder(modules, reserved, 0, size - 7);
    this.drawQrFinder(modules, reserved, size - 7, 0);
    for (let i = 8; i < size - 8; i++) {
      this.setQrFunctionModule(modules, reserved, 6, i, i % 2 === 0);
      this.setQrFunctionModule(modules, reserved, i, 6, i % 2 === 0);
    }
    this.drawQrAlignment(modules, reserved, 18);
    this.setQrFunctionModule(modules, reserved, 4 * version + 9, 8, true);
    this.reserveQrFormatAreas(modules, reserved);
    let bitIndex: number = 0;
    let upward: boolean = true;
    for (let col = size - 1; col >= 1; col -= 2) {
      if (col === 6) {
        col--;
      }
      for (let rowOffset = 0; rowOffset < size; rowOffset++) {
        const row: number = upward ? size - 1 - rowOffset : rowOffset;
        for (let c = 0; c < 2; c++) {
          const x: number = col - c;
          if (reserved[row][x]) {
            continue;
          }
          let dark: boolean = bitIndex < bits.length && bits[bitIndex] === 1;
          bitIndex++;
          if ((row + x) % 2 === 0) {
            dark = !dark;
          }
          modules[row][x] = dark;
        }
      }
      upward = !upward;
    }
    this.drawQrFormatBits(modules, reserved);
    const output: string[] = [];
    for (let row = -4; row < size + 4; row++) {
      let line: string = '';
      for (let col = -4; col < size + 4; col++) {
        const dark: boolean = row >= 0 && row < size && col >= 0 && col < size && modules[row][col];
        line += dark ? '##' : '..';
      }
      output.push(line);
    }
    return { version: version, size: size, dataCodewords: dataCodewords, eccCodewords: eccCodewords, lines: output };
  }

  @Builder
  Header() {
    Row() {
      Row() {
        Image($rawfile('ft_back.svg'))
          .width(22)
          .height(22)
          .colorFilter(createIconColorFilter(this.textPrimary()))
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.elevatedBg())
      .borderRadius(22)
      .onClick(() => router.back())

      Text(this.t('toolbox.title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary())
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Blank().width(44)
    }
    .width('100%')
    .height(64)
    .padding({ left: 18, right: 18, top: 8 })
  }

  @Builder
  LocalInfoCard() {
    Column() {
      Row() {
        Row() {
          Image($rawfile('settings_display.svg'))
            .width(24)
            .height(24)
            .colorFilter(createIconColorFilter('#FFFFFF'))
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#2FB5FF')
        .borderRadius(14)
        .margin({ right: 12 })
        Column({ space: 2 }) {
          Text(this.t('toolbox.localhost'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(this.t('toolbox.online'))
            .fontSize(13)
            .fontColor('#DDF2FF')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Row() {
        Column({ space: 6 }) {
          Row({ space: 6 }) {
            Image($rawfile('settings_network.svg'))
              .width(16)
              .height(16)
              .colorFilter(createIconColorFilter('#BDE8FF'))
            Text(this.t('toolbox.localIp'))
              .fontSize(12)
              .fontColor('#BDE8FF')
          }
          Text('127.0.0.1')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Column({ space: 6 }) {
          Row({ space: 6 }) {
            Image($rawfile('settings_cpu.svg'))
              .width(16)
              .height(16)
              .colorFilter(createIconColorFilter('#BDE8FF'))
            Text(this.t('toolbox.system'))
              .fontSize(12)
              .fontColor('#BDE8FF')
          }
          Text('ohos')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('92%')
    .padding(20)
    .backgroundColor(this.accentColor)
    .borderRadius(18)
    .margin({ top: 8 })
  }

  @Builder
  SearchBox() {
    Row() {
      Image($rawfile('settings_tune.svg'))
        .width(18)
        .height(18)
        .colorFilter(createIconColorFilter(this.textMuted()))
        .margin({ right: 8 })
      TextInput({ placeholder: this.t('toolbox.search'), text: this.keyword })
        .fontSize(14)
        .fontColor(this.textPrimary())
        .placeholderColor(this.textMuted())
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .height(40)
        .onChange((value: string) => {
          this.keyword = value;
        })
    }
    .width('92%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.elevatedBg())
    .borderRadius(14)
    .margin({ top: 18 })
  }

  @Builder
  CategoryChip(category: string) {
    Text(this.categoryTitle(category))
      .fontSize(13)
      .fontWeight(this.selectedCategory === category ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(this.selectedCategory === category ? Color.White : this.textSecond())
      .height(38)
      .padding({ left: 18, right: 18 })
      .textAlign(TextAlign.Center)
      .backgroundColor(this.selectedCategory === category ? this.accentColor : this.chipBg())
      .borderRadius(19)
      .margin({ right: 10, bottom: 8 })
      .onClick(() => this.selectedCategory = category)
  }

  @Builder
  ToolCard(item: ToolboxItem) {
    Column() {
      Row() {
        Row() {
          Image(item.icon)
            .width(26)
            .height(26)
            .colorFilter(createIconColorFilter(item.color))
        }
        .width(52)
        .height(52)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(item.bgColor)
        .borderRadius(14)
        .layoutWeight(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Blank().height(20)
      Text(this.t(item.titleKey))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary())
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.t(item.subtitleKey))
        .fontSize(12)
        .fontColor(this.textSecond())
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 7 })
    }
    .width('47%')
    .height(158)
    .padding(16)
    .backgroundColor(this.cardBg())
    .borderRadius(18)
    .shadow({ radius: 8, color: AppTheme.shadow(this.themeMode), offsetY: 2 })
    .margin({ right: 10, bottom: 12 })
    .onClick(() => this.openTool(item))
  }

  @Builder
  ActionButton(title: string, selected: boolean, action: () => void) {
    Button(title)
      .height(34)
      .fontSize(12)
      .fontColor(selected ? Color.White : this.textSecond())
      .backgroundColor(selected ? this.accentColor : this.chipBg())
      .borderRadius(17)
      .margin({ right: 8, bottom: 8 })
      .onClick(action)
  }

  @Builder
  ToolInputBox(placeholder: string) {
    TextArea({ placeholder: placeholder, text: this.toolInput })
      .height(86)
      .fontSize(13)
      .fontColor(this.textPrimary())
      .placeholderColor(this.textMuted())
      .backgroundColor(this.elevatedBg())
      .borderRadius(12)
      .padding({ left: 12, right: 12 })
      .onChange((value: string) => {
        this.toolInput = value;
      })
  }

  @Builder
  ToolRunner() {
    if (this.activeToolKey.length > 0) {
      Column({ space: 12 }) {
        Row() {
          Text(this.t(this.activeToolKey))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary())
            .layoutWeight(1)
          Button(this.t('common.close'))
            .height(34)
            .fontSize(12)
            .fontColor(this.textSecond())
            .backgroundColor(this.chipBg())
            .borderRadius(17)
            .onClick(() => this.closeTool())
        }
        .width('100%')

        if (this.activeToolKey === 'toolbox.systemInfo' || this.activeToolKey === 'toolbox.storage' ||
          this.activeToolKey === 'toolbox.ipInfo' || this.activeToolKey === 'toolbox.topology') {
          Flex({ wrap: FlexWrap.Wrap }) {
            if (this.activeToolKey === 'toolbox.systemInfo') {
              this.ActionButton(this.t('toolbox.refresh'), false, () => this.showSystemInfo())
            } else if (this.activeToolKey === 'toolbox.storage') {
              this.ActionButton(this.t('toolbox.refresh'), false, () => this.showStorageInfo())
            } else if (this.activeToolKey === 'toolbox.ipInfo') {
              this.ActionButton(this.t('toolbox.refresh'), false, () => this.showIpInfo())
              this.ActionButton(this.t('toolbox.publicIpButton'), this.networkInFlight, () => this.queryPublicIp())
            } else {
              this.ActionButton(this.t('toolbox.refresh'), false, () => this.showTopologySummary())
              this.ActionButton(this.t('toolbox.discover'), this.networkInFlight, () => this.discoverSubnet())
            }
          }
          .width('100%')
        } else {
          this.ToolInputBox(this.t('toolbox.inputPlaceholder'))
          Flex({ wrap: FlexWrap.Wrap }) {
            if (this.activeToolKey === 'toolbox.json') {
              this.ActionButton(this.t('toolbox.format'), false, () => this.formatJson(true))
              this.ActionButton(this.t('toolbox.minify'), false, () => this.formatJson(false))
            } else if (this.activeToolKey === 'toolbox.encode') {
              this.ActionButton(this.t('toolbox.base64Encode'), false, () => this.convertBase64(true))
              this.ActionButton(this.t('toolbox.base64Decode'), false, () => this.convertBase64(false))
              this.ActionButton(this.t('toolbox.hash'), false, () => this.hashText())
            } else if (this.activeToolKey === 'toolbox.text') {
              this.ActionButton(this.t('toolbox.analyze'), false, () => this.analyzeText())
            } else if (this.activeToolKey === 'toolbox.color') {
              this.ActionButton(this.t('toolbox.convert'), false, () => this.convertColor())
            } else if (this.activeToolKey === 'toolbox.unit') {
              this.ActionButton('m -> ft', this.unitMode === 'm_ft', () => this.convertUnit('m_ft'))
              this.ActionButton('ft -> m', this.unitMode === 'ft_m', () => this.convertUnit('ft_m'))
              this.ActionButton('C -> F', this.unitMode === 'c_f', () => this.convertUnit('c_f'))
              this.ActionButton('F -> C', this.unitMode === 'f_c', () => this.convertUnit('f_c'))
              this.ActionButton('kg -> lb', this.unitMode === 'kg_lb', () => this.convertUnit('kg_lb'))
              this.ActionButton('lb -> kg', this.unitMode === 'lb_kg', () => this.convertUnit('lb_kg'))
            } else if (this.activeToolKey === 'toolbox.speed') {
              this.ActionButton(this.t('toolbox.downloadTest'), this.networkInFlight, () => this.runSpeedTest())
              this.ActionButton(this.t('toolbox.uploadTest'), this.networkInFlight, () => this.runUploadTest())
            } else if (this.activeToolKey === 'toolbox.nginx') {
              this.ActionButton(this.t('toolbox.analyze'), false, () => this.analyzeNginxConfig())
            } else if (this.activeToolKey === 'toolbox.ping') {
              this.ActionButton(this.t('toolbox.tcpProbe'), this.networkInFlight, () => this.runConnectivityTest())
            } else if (this.activeToolKey === 'toolbox.portScan') {
              this.ActionButton(this.t('toolbox.scan'), this.networkInFlight, () => this.runPortScan())
            } else if (this.activeToolKey === 'toolbox.qr') {
              this.ActionButton(this.t('toolbox.generate'), false, () => this.generateQrPayload())
            }
          }
          .width('100%')
        }

        Text(this.toolOutput.length > 0 ? this.toolOutput : this.t('toolbox.noOutput'))
          .fontSize(13)
          .fontColor(this.textPrimary())
          .fontFamily('monospace')
          .copyOption(CopyOptions.LocalDevice)
          .width('100%')
          .padding(12)
          .backgroundColor(this.elevatedBg())
          .borderRadius(12)
      }
      .width('92%')
      .padding(16)
      .backgroundColor(this.cardBg())
      .borderRadius(18)
      .shadow({ radius: 8, color: AppTheme.shadow(this.themeMode), offsetY: 2 })
      .margin({ bottom: 12 })
    }
  }

  @Builder
  ToolSection(category: string) {
    if (this.filteredTools(category).length > 0) {
      Text(this.categoryTitle(category))
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textSecond())
        .width('92%')
        .margin({ top: 12, bottom: 8 })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.filteredTools(category), (item: ToolboxItem) => {
          this.ToolCard(item)
        }, (item: ToolboxItem) => item.titleKey)
      }
      .width('92%')
    }
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.LocalInfoCard()
          this.SearchBox()
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.categories, (category: string) => {
              this.CategoryChip(category)
            }, (category: string) => category)
          }
          .width('92%')
          .margin({ top: 16 })

          this.ToolRunner()

          if (this.selectedCategory === 'all') {
            this.ToolSection('network')
            this.ToolSection('system')
            this.ToolSection('develop')
          } else {
            this.ToolSection(this.selectedCategory)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 18 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.avoidStatusBarHeight, bottom: this.avoidNavigationBarHeight })
    .backgroundColor(this.pageBg())
  }
}
