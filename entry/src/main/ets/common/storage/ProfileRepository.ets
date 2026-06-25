import { ConnectionProfile, createEmptyConnectionProfile, cloneProfile } from '../models/ConnectionProfile';
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
  createDefaultProfileFilter
} from '../models/ConnectionGroup';

class MemoryProfileRepository {
  private profiles: ConnectionProfile[] = [];
  private groups: ConnectionGroup[] = [];

  constructor() {
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
  }

  saveGroup(group: ConnectionGroup): void {
    group.modifiedAt = new Date().getTime();
    const index: number = this.groups.findIndex((item: ConnectionGroup) => item.id === group.id);
    if (index >= 0) {
      this.groups[index] = cloneGroup(group);
    } else {
      this.groups.push(cloneGroup(group));
    }
  }

  remove(id: string): void {
    this.profiles = this.profiles.filter((item: ConnectionProfile) => item.id !== id);
  }

  removeGroup(id: string): void {
    this.groups = this.groups.filter((item: ConnectionGroup) => item.id !== id);
    this.profiles.forEach((item: ConnectionProfile) => {
      if (item.groupId === id) {
        item.groupId = '';
        item.modifiedAt = new Date().getTime();
      }
    });
  }

  recordConnectSuccess(id: string): void {
    const found: ConnectionProfile | undefined = this.profiles.find((item: ConnectionProfile) => item.id === id);
    if (found !== undefined) {
      found.lastConnectedAt = new Date().getTime();
      found.connectionCount += 1;
      found.lastErrorMessage = '';
      found.modifiedAt = new Date().getTime();
    }
  }

  recordConnectFailure(id: string, message: string): void {
    const found: ConnectionProfile | undefined = this.profiles.find((item: ConnectionProfile) => item.id === id);
    if (found !== undefined) {
      found.lastErrorMessage = message;
      found.modifiedAt = new Date().getTime();
    }
  }

  clearSensitiveFields(): void {
    this.profiles.forEach((item: ConnectionProfile) => {
      item.password = '';
      item.privateKeyPassphrase = '';
    });
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
