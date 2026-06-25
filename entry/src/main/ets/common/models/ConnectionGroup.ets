export const SORT_MANUAL: string = 'manual';
export const SORT_NAME_ASC: string = 'nameAsc';
export const SORT_HOST_ASC: string = 'hostAsc';
export const SORT_LAST_CONNECTED_DESC: string = 'lastConnectedDesc';
export const SORT_CONNECTION_COUNT_DESC: string = 'connectionCountDesc';
export const SORT_CREATED_DESC: string = 'createdDesc';
export const SORT_MODIFIED_DESC: string = 'modifiedDesc';
export const SORT_FAVORITE_FIRST: string = 'favoriteFirst';

export interface ConnectionGroup {
  id: string;
  name: string;
  colorTag: string;
  sortOrder: number;
  collapsed: boolean;
  createdAt: number;
  modifiedAt: number;
}

export interface ProfileFilter {
  keyword: string;
  groupId: string;
  favoriteOnly: boolean;
  sortMode: string;
}

export function createDefaultProfileFilter(): ProfileFilter {
  return {
    keyword: '',
    groupId: '',
    favoriteOnly: false,
    sortMode: SORT_MANUAL
  };
}

export function createConnectionGroup(name: string, colorTag: string = '#38BDF8'): ConnectionGroup {
  const now: number = new Date().getTime();
  return {
    id: 'group-' + now.toString(),
    name: name.length > 0 ? name : '默认分组',
    colorTag,
    sortOrder: 0,
    collapsed: false,
    createdAt: now,
    modifiedAt: now
  };
}

export function cloneGroup(group: ConnectionGroup): ConnectionGroup {
  return JSON.parse(JSON.stringify(group)) as ConnectionGroup;
}
