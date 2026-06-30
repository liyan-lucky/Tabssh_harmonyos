import common from '@ohos.app.ability.common';
import relationalStore from '@ohos.data.relationalStore';
import {
  AUDIT_CONNECT_FAILURE,
  AUDIT_CONNECT_SUCCESS,
  AUDIT_CONFIG_CHANGE,
  ConnectionAuditLog,
  cloneAuditLog,
  createConnectionAuditLog,
  normalizeConnectionAuditLog
} from '../models/ConnectionAuditLog';
import { ConnectionProfile, createEmptyConnectionProfile, cloneProfile, normalizeConnectionProfile } from '../models/ConnectionProfile';
import {
  ConnectionGroup,
  ProfileFilter,
  SORT_CONNECTION_COUNT_DESC,
  SORT_CREATED_DESC,
  SORT_FAVORITE_FIRST,
  SORT_HOST_ASC,
  SORT_LAST_CONNECTED_DESC,
  SORT_MANUAL,
  SORT_MODIFIED_DESC,
  SORT_NAME_ASC,
  cloneGroup,
  createConnectionGroup,
  createDefaultProfileFilter,
  normalizeConnectionGroup
} from '../models/ConnectionGroup';

const RDB_NAME: string = 'opentabssh_profiles.db';
const TABLE_PROFILES: string = 'connection_profiles';
const TABLE_GROUPS: string = 'connection_groups';
const TABLE_AUDIT_LOGS: string = 'connection_audit_logs';
const AUDIT_LOG_LIMIT: number = 300;

export interface ConnectionImportResult {
  importedProfiles: number;
  skippedProfiles: number;
  importedGroups: number;
  skippedGroups: number;
  warnings: string[];
}

class MemoryProfileRepository {
  private profiles: ConnectionProfile[] = [];
  private groups: ConnectionGroup[] = [];
  private auditLogs: ConnectionAuditLog[] = [];
  private store: relationalStore.RdbStore | undefined = undefined;
  private persistent: boolean = false;
  private initialized: boolean = false;

  constructor() {
    this.seedDefaults();
  }

  async initialize(context: common.Context): Promise<void> {
    if (this.initialized) {
      return;
    }
    try {
      const config: relationalStore.StoreConfig = {
        name: RDB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };
      const store: relationalStore.RdbStore = relationalStore.getRdbStoreSync(context, config);
      await store.executeSql(
        'CREATE TABLE IF NOT EXISTS ' + TABLE_GROUPS + ' (' +
          'id TEXT PRIMARY KEY NOT NULL, ' +
          'data TEXT NOT NULL, ' +
          'name TEXT NOT NULL, ' +
          'color_tag TEXT NOT NULL, ' +
          'sort_order INTEGER NOT NULL, ' +
          'collapsed INTEGER NOT NULL, ' +
          'modified_at INTEGER NOT NULL)'
      );
      await store.executeSql(
        'CREATE TABLE IF NOT EXISTS ' + TABLE_PROFILES + ' (' +
          'id TEXT PRIMARY KEY NOT NULL, ' +
          'data TEXT NOT NULL, ' +
          'name TEXT NOT NULL, ' +
          'host TEXT NOT NULL, ' +
          'username TEXT NOT NULL, ' +
          'group_id TEXT NOT NULL, ' +
          'sort_order INTEGER NOT NULL, ' +
          'favorite INTEGER NOT NULL, ' +
          'last_connected_at INTEGER NOT NULL, ' +
          'connection_count INTEGER NOT NULL, ' +
          'modified_at INTEGER NOT NULL)'
      );
      await store.executeSql(
        'CREATE TABLE IF NOT EXISTS ' + TABLE_AUDIT_LOGS + ' (' +
          'id TEXT PRIMARY KEY NOT NULL, ' +
          'data TEXT NOT NULL, ' +
          'profile_id TEXT NOT NULL, ' +
          'profile_name TEXT NOT NULL, ' +
          'event_type TEXT NOT NULL, ' +
          'status TEXT NOT NULL, ' +
          'created_at INTEGER NOT NULL)'
      );
      this.store = store;
      this.loadFromRdb();
      this.persistent = true;
      this.initialized = true;
    } catch (error) {
      this.store = undefined;
      this.persistent = false;
      this.initialized = true;
    }
  }

  isPersistent(): boolean {
    return this.persistent;
  }

  private seedDefaults(): void {
    const defaultGroup: ConnectionGroup = createConnectionGroup('默认分组', '#38BDF8');
    defaultGroup.id = 'group-default';
    this.groups.push(defaultGroup);

    const demo: ConnectionProfile = createEmptyConnectionProfile();
    demo.id = 'demo-localhost';
    demo.name = '示例连接';
    demo.host = '192.168.1.1';
    demo.username = 'root';
    demo.groupId = defaultGroup.id;
    // 测试凭据只允许在运行内存中由测试者输入，不写入源码或文档。
    demo.password = '';
    this.profiles.push(demo);
  }

  list(): ConnectionProfile[] {
    return this.listFiltered(createDefaultProfileFilter());
  }

  listFiltered(filter: ProfileFilter): ConnectionProfile[] {
    const keyword: string = filter.keyword.trim().toLowerCase();
    let items: ConnectionProfile[] = this.profiles.map((item: ConnectionProfile) => cloneProfile(item));
    if (filter.groupId.length > 0) {
      items = items.filter((item: ConnectionProfile) => item.groupId === filter.groupId);
    }
    if (filter.favoriteOnly) {
      items = items.filter((item: ConnectionProfile) => item.favorite);
    }
    if (keyword.length > 0) {
      items = items.filter((item: ConnectionProfile) => {
        const haystack: string = `${item.name} ${item.host} ${item.username} ${item.remarks}`.toLowerCase();
        return haystack.includes(keyword);
      });
    }
    return this.sortProfiles(items, filter.sortMode);
  }

  listGroups(): ConnectionGroup[] {
    return this.groups
      .map((item: ConnectionGroup) => cloneGroup(item))
      .sort((a: ConnectionGroup, b: ConnectionGroup) => a.sortOrder - b.sortOrder || a.name.localeCompare(b.name));
  }

  get(id: string): ConnectionProfile | undefined {
    const found: ConnectionProfile | undefined = this.profiles.find((item: ConnectionProfile) => item.id === id);
    if (found === undefined) {
      return undefined;
    }
    return cloneProfile(found);
  }

  save(profile: ConnectionProfile): void {
    profile.modifiedAt = new Date().getTime();
    const index: number = this.profiles.findIndex((item: ConnectionProfile) => item.id === profile.id);
    if (index >= 0) {
      this.profiles[index] = cloneProfile(profile);
    } else {
      this.profiles.push(cloneProfile(profile));
    }
    this.persistProfile(profile);
  }

  saveGroup(group: ConnectionGroup): void {
    group.modifiedAt = new Date().getTime();
    const index: number = this.groups.findIndex((item: ConnectionGroup) => item.id === group.id);
    if (index >= 0) {
      this.groups[index] = cloneGroup(group);
    } else {
      this.groups.push(cloneGroup(group));
    }
    this.persistGroup(group);
  }

  remove(id: string): void {
    this.profiles = this.profiles.filter((item: ConnectionProfile) => item.id !== id);
    this.deleteProfile(id);
  }

  removeGroup(id: string): void {
    this.groups = this.groups.filter((item: ConnectionGroup) => item.id !== id);
    this.profiles.forEach((item: ConnectionProfile) => {
      if (item.groupId === id) {
        item.groupId = '';
        item.modifiedAt = new Date().getTime();
      }
    });
    this.deleteGroup(id);
    this.persistProfiles();
  }

  recordConnectSuccess(id: string): void {
    const found: ConnectionProfile | undefined = this.profiles.find((item: ConnectionProfile) => item.id === id);
    if (found !== undefined) {
      found.lastConnectedAt = new Date().getTime();
      found.connectionCount += 1;
      found.lastErrorMessage = '';
      found.modifiedAt = new Date().getTime();
      this.persistProfile(found);
      this.recordAuditLog(AUDIT_CONNECT_SUCCESS, 'success', found.id, found.name, 'SSH 认证成功');
    }
  }

  recordConnectFailure(id: string, message: string): void {
    const found: ConnectionProfile | undefined = this.profiles.find((item: ConnectionProfile) => item.id === id);
    if (found !== undefined) {
      found.lastErrorMessage = message;
      found.modifiedAt = new Date().getTime();
      this.persistProfile(found);
      this.recordAuditLog(AUDIT_CONNECT_FAILURE, 'failure', found.id, found.name, this.sanitizeAuditMessage(message));
    }
  }

  listAuditLogs(limit: number = 100): ConnectionAuditLog[] {
    const capped: number = Math.max(1, Math.min(limit, AUDIT_LOG_LIMIT));
    return this.auditLogs
      .map((item: ConnectionAuditLog) => cloneAuditLog(item))
      .sort((a: ConnectionAuditLog, b: ConnectionAuditLog) => b.createdAt - a.createdAt)
      .slice(0, capped);
  }

  recordAuditLog(eventType: string, status: string, profileId: string, profileName: string, message: string): void {
    const log: ConnectionAuditLog = createConnectionAuditLog(
      eventType,
      status,
      profileId,
      profileName.length > 0 ? profileName : '本机',
      this.sanitizeAuditMessage(message)
    );
    this.auditLogs.unshift(log);
    this.trimAuditLogs();
    this.persistAuditLog(log);
  }

  clearAuditLogs(): void {
    this.auditLogs = [];
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return;
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_AUDIT_LOGS);
    store.deleteSync(predicates);
  }

  clearSensitiveFields(): void {
    this.profiles.forEach((item: ConnectionProfile) => {
      item.password = '';
      item.privateKeyPassphrase = '';
    });
    this.persistProfiles();
  }

  importConnections(groups: ConnectionGroup[], profiles: ConnectionProfile[], sourceLabel: string): ConnectionImportResult {
    const result: ConnectionImportResult = {
      importedProfiles: 0,
      skippedProfiles: 0,
      importedGroups: 0,
      skippedGroups: 0,
      warnings: []
    };
    const groupIdMap: Record<string, string> = {};
    groups.forEach((group: ConnectionGroup) => {
      const normalized: ConnectionGroup = normalizeConnectionGroup(group);
      const existingById: ConnectionGroup | undefined =
        this.groups.find((item: ConnectionGroup) => item.id === normalized.id);
      const existingByName: ConnectionGroup | undefined =
        this.groups.find((item: ConnectionGroup) => item.name === normalized.name);
      if (existingById !== undefined) {
        groupIdMap[normalized.id] = existingById.id;
        result.skippedGroups += 1;
        return;
      }
      if (existingByName !== undefined) {
        groupIdMap[normalized.id] = existingByName.id;
        result.skippedGroups += 1;
        return;
      }
      const imported: ConnectionGroup = cloneGroup(normalized);
      if (this.groups.findIndex((item: ConnectionGroup) => item.id === imported.id) >= 0) {
        imported.id = this.nextImportedId('group');
      }
      imported.sortOrder = this.groups.length;
      imported.modifiedAt = new Date().getTime();
      this.groups.push(imported);
      this.persistGroup(imported);
      groupIdMap[normalized.id] = imported.id;
      result.importedGroups += 1;
    });

    profiles.forEach((profile: ConnectionProfile) => {
      const imported: ConnectionProfile = this.prepareImportedProfile(profile, groupIdMap);
      if (imported.host.trim().length === 0 || imported.port < 1 || imported.port > 65535) {
        result.skippedProfiles += 1;
        result.warnings.push(imported.name + ' 主机或端口无效，已跳过。');
        return;
      }
      if (this.profileKeyExists(imported)) {
        result.skippedProfiles += 1;
        return;
      }
      if (this.profiles.findIndex((item: ConnectionProfile) => item.id === imported.id) >= 0) {
        imported.id = this.nextImportedId('profile');
      }
      imported.sortOrder = this.profiles.length;
      imported.modifiedAt = new Date().getTime();
      this.profiles.push(imported);
      this.persistProfile(imported);
      result.importedProfiles += 1;
    });

    if (result.importedProfiles > 0 || result.importedGroups > 0 || result.skippedProfiles > 0) {
      this.recordAuditLog(AUDIT_CONFIG_CHANGE, 'success', '', '连接导入导出',
        sourceLabel + ' 导入 ' + result.importedProfiles.toString() + ' 台主机，跳过 ' +
        result.skippedProfiles.toString() + ' 台，新增 ' + result.importedGroups.toString() + ' 个分组');
    }
    return result;
  }

  private loadFromRdb(): void {
    const loadedGroups: ConnectionGroup[] = this.readGroupsFromRdb();
    const loadedProfiles: ConnectionProfile[] = this.readProfilesFromRdb();
    this.auditLogs = this.readAuditLogsFromRdb();
    if (loadedGroups.length === 0 && loadedProfiles.length === 0) {
      this.persistAll();
      this.recordAuditLog(AUDIT_CONFIG_CHANGE, 'info', '', '本机', 'RDB 首次初始化');
      return;
    }
    this.groups = loadedGroups.length > 0 ? loadedGroups : this.createDefaultGroups();
    this.profiles = loadedProfiles;
    this.ensureDefaultGroup();
    this.ensureProfileGroups();
    this.persistAll();
  }

  private sanitizeAuditMessage(message: string): string {
    return message.replace(/\r/g, ' ').replace(/\n/g, ' ').trim().substring(0, 160);
  }

  private prepareImportedProfile(profile: ConnectionProfile, groupIdMap: Record<string, string>): ConnectionProfile {
    const imported: ConnectionProfile = normalizeConnectionProfile(profile);
    imported.password = '';
    imported.privateKeyPassphrase = '';
    imported.privateKeyPath = '';
    imported.hostKeyFingerprint = '';
    imported.hostKeyAlgorithm = '';
    imported.hostKeyTrustedAt = 0;
    imported.proxyKeyId = '';
    if (imported.groupId.length > 0 && groupIdMap[imported.groupId] !== undefined) {
      imported.groupId = groupIdMap[imported.groupId];
    }
    if (imported.groupId.length === 0 || this.groups.findIndex((item: ConnectionGroup) => item.id === imported.groupId) < 0) {
      imported.groupId = 'group-default';
    }
    if (imported.name.trim().length === 0) {
      imported.name = imported.host;
    }
    return imported;
  }

  private profileKeyExists(profile: ConnectionProfile): boolean {
    const host: string = profile.host.trim().toLowerCase();
    const username: string = profile.username.trim().toLowerCase();
    return this.profiles.findIndex((item: ConnectionProfile) => {
      return item.host.trim().toLowerCase() === host && item.port === profile.port &&
        item.username.trim().toLowerCase() === username;
    }) >= 0;
  }

  private nextImportedId(prefix: string): string {
    return prefix + '-import-' + new Date().getTime().toString() + '-' +
      Math.floor(Math.random() * 100000).toString();
  }

  private trimAuditLogs(): void {
    this.auditLogs = this.auditLogs
      .sort((a: ConnectionAuditLog, b: ConnectionAuditLog) => b.createdAt - a.createdAt)
      .slice(0, AUDIT_LOG_LIMIT);
  }

  private createDefaultGroups(): ConnectionGroup[] {
    const defaultGroup: ConnectionGroup = createConnectionGroup('默认分组', '#38BDF8');
    defaultGroup.id = 'group-default';
    return [defaultGroup];
  }

  private ensureDefaultGroup(): void {
    if (this.groups.findIndex((item: ConnectionGroup) => item.id === 'group-default') >= 0) {
      return;
    }
    this.groups.unshift(this.createDefaultGroups()[0]);
  }

  private ensureProfileGroups(): void {
    const knownGroups: string[] = this.groups.map((item: ConnectionGroup) => item.id);
    this.profiles.forEach((item: ConnectionProfile) => {
      if (item.groupId.length === 0 || knownGroups.indexOf(item.groupId) < 0) {
        item.groupId = 'group-default';
        item.modifiedAt = new Date().getTime();
      }
    });
  }

  private readGroupsFromRdb(): ConnectionGroup[] {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return [];
    }
    const resultSet: relationalStore.ResultSet = store.querySqlSync(
      'SELECT data FROM ' + TABLE_GROUPS + ' ORDER BY sort_order ASC, name ASC'
    );
    const groups: ConnectionGroup[] = [];
    try {
      const dataIndex: number = resultSet.getColumnIndex('data');
      while (resultSet.goToNextRow()) {
        const parsed: ConnectionGroup | undefined = this.parseGroup(resultSet.getString(dataIndex));
        if (parsed !== undefined) {
          groups.push(parsed);
        }
      }
    } finally {
      resultSet.close();
    }
    return groups;
  }

  private readProfilesFromRdb(): ConnectionProfile[] {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return [];
    }
    const resultSet: relationalStore.ResultSet = store.querySqlSync(
      'SELECT data FROM ' + TABLE_PROFILES + ' ORDER BY sort_order ASC, name ASC'
    );
    const profiles: ConnectionProfile[] = [];
    try {
      const dataIndex: number = resultSet.getColumnIndex('data');
      while (resultSet.goToNextRow()) {
        const parsed: ConnectionProfile | undefined = this.parseProfile(resultSet.getString(dataIndex));
        if (parsed !== undefined) {
          profiles.push(parsed);
        }
      }
    } finally {
      resultSet.close();
    }
    return profiles;
  }

  private readAuditLogsFromRdb(): ConnectionAuditLog[] {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return [];
    }
    const resultSet: relationalStore.ResultSet = store.querySqlSync(
      'SELECT data FROM ' + TABLE_AUDIT_LOGS + ' ORDER BY created_at DESC LIMIT ' + AUDIT_LOG_LIMIT.toString()
    );
    const logs: ConnectionAuditLog[] = [];
    try {
      const dataIndex: number = resultSet.getColumnIndex('data');
      while (resultSet.goToNextRow()) {
        const parsed: ConnectionAuditLog | undefined = this.parseAuditLog(resultSet.getString(dataIndex));
        if (parsed !== undefined) {
          logs.push(parsed);
        }
      }
    } finally {
      resultSet.close();
    }
    return logs;
  }

  private parseGroup(data: string): ConnectionGroup | undefined {
    try {
      return normalizeConnectionGroup(JSON.parse(data) as ConnectionGroup);
    } catch (error) {
      return undefined;
    }
  }

  private parseProfile(data: string): ConnectionProfile | undefined {
    try {
      const profile: ConnectionProfile = cloneProfile(JSON.parse(data) as ConnectionProfile);
      profile.password = '';
      profile.privateKeyPassphrase = '';
      return profile;
    } catch (error) {
      return undefined;
    }
  }

  private parseAuditLog(data: string): ConnectionAuditLog | undefined {
    try {
      return normalizeConnectionAuditLog(JSON.parse(data) as ConnectionAuditLog);
    } catch (error) {
      return undefined;
    }
  }

  private persistAll(): void {
    this.persistGroups();
    this.persistProfiles();
    this.persistAuditLogs();
  }

  private persistGroups(): void {
    this.groups.forEach((item: ConnectionGroup) => this.persistGroup(item));
  }

  private persistProfiles(): void {
    this.profiles.forEach((item: ConnectionProfile) => this.persistProfile(item));
  }

  private persistAuditLogs(): void {
    this.auditLogs.forEach((item: ConnectionAuditLog) => this.persistAuditLog(item));
  }

  private persistGroup(group: ConnectionGroup): void {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return;
    }
    const normalized: ConnectionGroup = normalizeConnectionGroup(group);
    const values: relationalStore.ValuesBucket = {
      id: normalized.id,
      data: JSON.stringify(normalized),
      name: normalized.name,
      color_tag: normalized.colorTag,
      sort_order: normalized.sortOrder,
      collapsed: normalized.collapsed ? 1 : 0,
      modified_at: normalized.modifiedAt
    };
    store.insertSync(TABLE_GROUPS, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  private persistProfile(profile: ConnectionProfile): void {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return;
    }
    const stored: ConnectionProfile = cloneProfile(profile);
    stored.password = '';
    stored.privateKeyPassphrase = '';
    const values: relationalStore.ValuesBucket = {
      id: stored.id,
      data: JSON.stringify(stored),
      name: stored.name,
      host: stored.host,
      username: stored.username,
      group_id: stored.groupId,
      sort_order: stored.sortOrder,
      favorite: stored.favorite ? 1 : 0,
      last_connected_at: stored.lastConnectedAt,
      connection_count: stored.connectionCount,
      modified_at: stored.modifiedAt
    };
    store.insertSync(TABLE_PROFILES, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  private persistAuditLog(log: ConnectionAuditLog): void {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return;
    }
    const normalized: ConnectionAuditLog = normalizeConnectionAuditLog(log);
    const values: relationalStore.ValuesBucket = {
      id: normalized.id,
      data: JSON.stringify(normalized),
      profile_id: normalized.profileId,
      profile_name: normalized.profileName,
      event_type: normalized.eventType,
      status: normalized.status,
      created_at: normalized.createdAt
    };
    store.insertSync(TABLE_AUDIT_LOGS, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    this.deleteAuditOverflow();
  }

  private deleteProfile(id: string): void {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return;
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_PROFILES);
    predicates.equalTo('id', id);
    store.deleteSync(predicates);
  }

  private deleteGroup(id: string): void {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return;
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_GROUPS);
    predicates.equalTo('id', id);
    store.deleteSync(predicates);
  }

  private deleteAuditOverflow(): void {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      return;
    }
    const resultSet: relationalStore.ResultSet = store.querySqlSync(
      'SELECT id FROM ' + TABLE_AUDIT_LOGS + ' ORDER BY created_at DESC LIMIT -1 OFFSET ' + AUDIT_LOG_LIMIT.toString()
    );
    try {
      const idIndex: number = resultSet.getColumnIndex('id');
      while (resultSet.goToNextRow()) {
        const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_AUDIT_LOGS);
        predicates.equalTo('id', resultSet.getString(idIndex));
        store.deleteSync(predicates);
      }
    } finally {
      resultSet.close();
    }
  }

  private sortProfiles(items: ConnectionProfile[], sortMode: string): ConnectionProfile[] {
    const mode: string = sortMode.length > 0 ? sortMode : SORT_MANUAL;
    return items.sort((a: ConnectionProfile, b: ConnectionProfile) => {
      if (mode === SORT_NAME_ASC) {
        return a.name.localeCompare(b.name) || a.host.localeCompare(b.host);
      }
      if (mode === SORT_HOST_ASC) {
        return a.host.localeCompare(b.host) || a.name.localeCompare(b.name);
      }
      if (mode === SORT_LAST_CONNECTED_DESC) {
        return b.lastConnectedAt - a.lastConnectedAt || a.name.localeCompare(b.name);
      }
      if (mode === SORT_CONNECTION_COUNT_DESC) {
        return b.connectionCount - a.connectionCount || a.name.localeCompare(b.name);
      }
      if (mode === SORT_CREATED_DESC) {
        return b.createdAt - a.createdAt || a.name.localeCompare(b.name);
      }
      if (mode === SORT_MODIFIED_DESC) {
        return b.modifiedAt - a.modifiedAt || a.name.localeCompare(b.name);
      }
      if (mode === SORT_FAVORITE_FIRST) {
        const favoriteCompare: number = Number(b.favorite) - Number(a.favorite);
        if (favoriteCompare !== 0) {
          return favoriteCompare;
        }
        return a.sortOrder - b.sortOrder || a.name.localeCompare(b.name);
      }
      return a.sortOrder - b.sortOrder || a.name.localeCompare(b.name);
    });
  }
}

export const ProfileRepository: MemoryProfileRepository = new MemoryProfileRepository();
