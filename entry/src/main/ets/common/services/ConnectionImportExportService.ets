import {
  AUTH_PRIVATE_KEY,
  ConnectionProfile,
  cloneProfile,
  createEmptyConnectionProfile,
  normalizeConnectionProfile
} from '../models/ConnectionProfile';
import {
  ConnectionGroup,
  cloneGroup,
  createConnectionGroup,
  normalizeConnectionGroup
} from '../models/ConnectionGroup';

export interface ConnectionBackupDocument {
  kind: string;
  formatVersion: number;
  exportedAt: number;
  policy: string;
  groups: ConnectionGroup[];
  profiles: ConnectionProfile[];
}

export interface ConnectionImportPreview {
  format: string;
  groups: ConnectionGroup[];
  profiles: ConnectionProfile[];
  warnings: string[];
}

export class ConnectionImportExportService {
  static readonly BACKUP_KIND: string = 'opentabssh-connection-backup';
  static readonly BACKUP_VERSION: number = 1;
  static readonly BACKUP_POLICY: string =
    'connection-config-only: no passwords, private key files, private key passphrases, or command output';

  static buildBackupJson(groups: ConnectionGroup[], profiles: ConnectionProfile[]): string {
    const document: ConnectionBackupDocument = {
      kind: ConnectionImportExportService.BACKUP_KIND,
      formatVersion: ConnectionImportExportService.BACKUP_VERSION,
      exportedAt: new Date().getTime(),
      policy: ConnectionImportExportService.BACKUP_POLICY,
      groups: groups.map((group: ConnectionGroup): ConnectionGroup => cloneGroup(group)),
      profiles: profiles.map((profile: ConnectionProfile): ConnectionProfile => {
        return ConnectionImportExportService.scrubProfile(profile);
      })
    };
    return JSON.stringify(document, null, 2);
  }

  static parseBackupJson(text: string): ConnectionImportPreview {
    const parsed: ConnectionBackupDocument = JSON.parse(text) as ConnectionBackupDocument;
    const warnings: string[] = [];
    if (parsed.kind !== ConnectionImportExportService.BACKUP_KIND) {
      warnings.push('文件不是 OpenTabSsh 连接备份格式，已尝试按兼容 JSON 读取。');
    }
    const groups: ConnectionGroup[] = Array.isArray(parsed.groups) ? parsed.groups.map((group: ConnectionGroup): ConnectionGroup => {
      return normalizeConnectionGroup(group);
    }) : [];
    const profiles: ConnectionProfile[] = Array.isArray(parsed.profiles) ?
      parsed.profiles.map((profile: ConnectionProfile): ConnectionProfile => {
        return ConnectionImportExportService.scrubProfile(normalizeConnectionProfile(profile));
      }) : [];
    return {
      format: 'JSON 连接备份',
      groups,
      profiles: ConnectionImportExportService.validProfiles(profiles, warnings),
      warnings
    };
  }

  static buildOpenSshConfig(groups: ConnectionGroup[], profiles: ConnectionProfile[]): string {
    const lines: string[] = [
      '# OpenTabSsh OpenSSH config export',
      '# ExportedAt ' + ConnectionImportExportService.formatTimestamp(new Date().getTime()),
      '# Credentials, private key files, and private key passphrases are excluded.',
      ''
    ];
    profiles.forEach((profile: ConnectionProfile) => {
      const group: ConnectionGroup | undefined = groups.find((item: ConnectionGroup) => item.id === profile.groupId);
      if (group !== undefined) {
        lines.push('# Group: ' + group.name);
      }
      lines.push('Host ' + ConnectionImportExportService.safeHostAlias(profile.name, profile.host));
      lines.push('    HostName ' + ConnectionImportExportService.quoteSshValue(profile.host));
      lines.push('    User ' + ConnectionImportExportService.quoteSshValue(profile.username));
      lines.push('    Port ' + profile.port.toString());
      lines.push('    RequestTTY ' + (profile.requestTty ? 'yes' : 'no'));
      lines.push('    ServerAliveInterval ' + profile.serverAliveIntervalSeconds.toString());
      lines.push('    ConnectTimeout ' + Math.max(1, Math.floor(profile.connectTimeoutMilliseconds / 1000)).toString());
      lines.push('    Compression ' + (profile.compression ? 'yes' : 'no'));
      if (profile.terminalType.length > 0) {
        lines.push('    SetEnv TERM=' + ConnectionImportExportService.quoteSshValue(profile.terminalType));
      }
      if (profile.sendEnv.length > 0) {
        lines.push('    SendEnv ' + profile.sendEnv.map((item: string): string => {
          return ConnectionImportExportService.quoteSshValue(item);
        }).join(' '));
      }
      if (profile.remoteCommand.length > 0) {
        lines.push('    RemoteCommand ' + ConnectionImportExportService.quoteSshValue(profile.remoteCommand));
      }
      if (profile.remarks.length > 0) {
        lines.push('    # Remark: ' + profile.remarks.replace(/\r/g, ' ').replace(/\n/g, ' ').substring(0, 120));
      }
      lines.push('');
    });
    return lines.join('\n');
  }

  static parseOpenSshConfig(text: string): ConnectionImportPreview {
    const warnings: string[] = [];
    const groups: ConnectionGroup[] = [];
    const profiles: ConnectionProfile[] = [];
    const lines: string[] = text.replace(/\r/g, '').split('\n');
    let current: ConnectionProfile | undefined = undefined;
    let pendingGroupName: string = '';
    let identityFileFound: boolean = false;

    const finishCurrent = (): void => {
      if (current === undefined) {
        return;
      }
      if (identityFileFound) {
        current.authType = AUTH_PRIVATE_KEY;
        current.privateKeyPath = '';
        current.remarks = ConnectionImportExportService.appendRemark(current.remarks,
          'OpenSSH 配置包含 IdentityFile，需在本机重新导入私钥。');
        warnings.push(current.name + ' 使用 IdentityFile，已省略本地私钥路径。');
      }
      profiles.push(current);
      current = undefined;
      identityFileFound = false;
    };

    lines.forEach((rawLine: string, index: number) => {
      const line: string = rawLine.trim();
      if (line.length === 0) {
        return;
      }
      if (line.startsWith('#')) {
        const groupPrefix: string = '# Group:';
        if (line.startsWith(groupPrefix)) {
          pendingGroupName = line.substring(groupPrefix.length).trim();
        }
        return;
      }
      const parts: string[] = ConnectionImportExportService.splitOption(line);
      if (parts.length < 2) {
        warnings.push('第 ' + (index + 1).toString() + ' 行无法识别，已跳过。');
        return;
      }
      const key: string = parts[0].toLowerCase();
      const value: string = ConnectionImportExportService.unquoteSshValue(parts[1]);
      if (key === 'host') {
        finishCurrent();
        const alias: string = ConnectionImportExportService.firstConcreteHostAlias(value);
        if (alias.length === 0) {
          current = undefined;
          warnings.push('第 ' + (index + 1).toString() + ' 行 Host 仅包含通配符，已跳过。');
          return;
        }
        current = createEmptyConnectionProfile();
        current.id = 'profile-import-' + new Date().getTime().toString() + '-' + profiles.length.toString();
        current.name = alias;
        current.host = alias;
        current.username = '';
        current.password = '';
        current.privateKeyPassphrase = '';
        current.privateKeyPath = '';
        if (pendingGroupName.length > 0) {
          const group: ConnectionGroup = ConnectionImportExportService.ensureGroup(groups, pendingGroupName);
          current.groupId = group.id;
        }
        pendingGroupName = '';
        return;
      }
      if (current === undefined) {
        return;
      }
      if (key === 'hostname') {
        current.host = value;
      } else if (key === 'user') {
        current.username = value;
      } else if (key === 'port') {
        const parsedPort: number = Number(value);
        if (parsedPort >= 1 && parsedPort <= 65535) {
          current.port = parsedPort;
        } else {
          warnings.push(current.name + ' 的端口无效，已使用默认 22。');
        }
      } else if (key === 'requesttty') {
        current.requestTty = value.toLowerCase() !== 'no' && value.toLowerCase() !== 'false';
      } else if (key === 'serveraliveinterval') {
        current.serverAliveIntervalSeconds = ConnectionImportExportService.positiveNumber(value,
          current.serverAliveIntervalSeconds);
      } else if (key === 'connecttimeout') {
        current.connectTimeoutMilliseconds = ConnectionImportExportService.positiveNumber(value,
          Math.floor(current.connectTimeoutMilliseconds / 1000)) * 1000;
      } else if (key === 'compression') {
        current.compression = value.toLowerCase() === 'yes' || value.toLowerCase() === 'true';
      } else if (key === 'sendenv') {
        current.sendEnv = value.split(/\s+/).filter((item: string) => item.length > 0);
      } else if (key === 'remotecommand') {
        current.remoteCommand = value;
      } else if (key === 'setenv') {
        current.terminalType = ConnectionImportExportService.parseTermFromSetEnv(value, current.terminalType);
      } else if (key === 'identityfile') {
        identityFileFound = true;
      }
    });
    finishCurrent();
    return {
      format: 'OpenSSH config',
      groups,
      profiles: ConnectionImportExportService.validProfiles(profiles, warnings),
      warnings
    };
  }

  static scrubProfile(profile: ConnectionProfile): ConnectionProfile {
    const scrubbed: ConnectionProfile = cloneProfile(profile);
    scrubbed.password = '';
    scrubbed.privateKeyPath = '';
    scrubbed.privateKeyPassphrase = '';
    scrubbed.proxyUsername = profile.proxyUsername;
    scrubbed.proxyKeyId = '';
    return scrubbed;
  }

  private static validProfiles(profiles: ConnectionProfile[], warnings: string[]): ConnectionProfile[] {
    const valid: ConnectionProfile[] = [];
    profiles.forEach((profile: ConnectionProfile) => {
      const scrubbed: ConnectionProfile = ConnectionImportExportService.scrubProfile(profile);
      if (scrubbed.host.trim().length === 0) {
        warnings.push(scrubbed.name + ' 缺少 HostName，已跳过。');
        return;
      }
      if (scrubbed.username.trim().length === 0) {
        warnings.push(scrubbed.name + ' 缺少 User，已保留为空，连接前需补充。');
      }
      if (scrubbed.port < 1 || scrubbed.port > 65535) {
        warnings.push(scrubbed.name + ' 端口无效，已改为 22。');
        scrubbed.port = 22;
      }
      valid.push(scrubbed);
    });
    return valid;
  }

  private static ensureGroup(groups: ConnectionGroup[], name: string): ConnectionGroup {
    const existing: ConnectionGroup | undefined = groups.find((item: ConnectionGroup) => item.name === name);
    if (existing !== undefined) {
      return existing;
    }
    const group: ConnectionGroup = createConnectionGroup(name);
    group.id = 'group-import-' + new Date().getTime().toString() + '-' + groups.length.toString();
    group.sortOrder = groups.length;
    groups.push(group);
    return group;
  }

  private static splitOption(line: string): string[] {
    const separator: number = line.search(/\s/);
    if (separator < 0) {
      return [line];
    }
    return [line.substring(0, separator), line.substring(separator).trim()];
  }

  private static firstConcreteHostAlias(value: string): string {
    const aliases: string[] = value.split(/\s+/);
    for (let i = 0; i < aliases.length; i++) {
      const alias: string = aliases[i].trim();
      if (alias.length > 0 && alias.indexOf('*') < 0 && alias.indexOf('?') < 0 && alias !== '!') {
        return alias.startsWith('!') ? alias.substring(1) : alias;
      }
    }
    return '';
  }

  private static safeHostAlias(name: string, host: string): string {
    const source: string = name.trim().length > 0 ? name.trim() : host.trim();
    const alias: string = source.replace(/\s+/g, '-').replace(/[^A-Za-z0-9._-]/g, '-');
    return alias.length > 0 ? alias : 'opentabssh-host';
  }

  private static quoteSshValue(value: string): string {
    if (value.length === 0) {
      return '""';
    }
    if (value.search(/[\s#"]/g) >= 0) {
      return '"' + value.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"';
    }
    return value;
  }

  private static unquoteSshValue(value: string): string {
    const trimmed: string = value.trim();
    if (trimmed.length >= 2 && trimmed.startsWith('"') && trimmed.endsWith('"')) {
      return trimmed.substring(1, trimmed.length - 1).replace(/\\"/g, '"').replace(/\\\\/g, '\\');
    }
    return trimmed;
  }

  private static positiveNumber(value: string, fallback: number): number {
    const parsed: number = Number(value);
    return parsed > 0 ? parsed : fallback;
  }

  private static parseTermFromSetEnv(value: string, fallback: string): string {
    const parts: string[] = value.split(/\s+/);
    for (let i = 0; i < parts.length; i++) {
      if (parts[i].startsWith('TERM=')) {
        return parts[i].substring(5);
      }
    }
    return fallback;
  }

  private static appendRemark(current: string, next: string): string {
    if (current.trim().length === 0) {
      return next;
    }
    return current + '；' + next;
  }

  private static formatTimestamp(timestamp: number): string {
    const date: Date = new Date(timestamp);
    return date.getFullYear().toString() + '-' + ConnectionImportExportService.pad(date.getMonth() + 1) + '-' +
      ConnectionImportExportService.pad(date.getDate()) + ' ' + ConnectionImportExportService.pad(date.getHours()) +
      ':' + ConnectionImportExportService.pad(date.getMinutes());
  }

  private static pad(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
  }
}
