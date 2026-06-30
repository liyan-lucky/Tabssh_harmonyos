export const AUDIT_CONNECT_SUCCESS: string = 'AUTH_SUCCESS';
export const AUDIT_CONNECT_FAILURE: string = 'AUTH_FAILURE';
export const AUDIT_CONFIG_CHANGE: string = 'CONFIG_CHANGE';
export const AUDIT_BULK_ACTION: string = 'BULK_ACTION';
export const AUDIT_GROUP_CHANGE: string = 'GROUP_CHANGE';

export interface ConnectionAuditLog {
  id: string;
  profileId: string;
  profileName: string;
  eventType: string;
  status: string;
  message: string;
  createdAt: number;
}

export function createConnectionAuditLog(eventType: string, status: string, profileId: string,
  profileName: string, message: string): ConnectionAuditLog {
  const now: number = new Date().getTime();
  return {
    id: 'audit-' + now.toString() + '-' + Math.floor(Math.random() * 1000000).toString(),
    profileId: profileId,
    profileName: profileName,
    eventType: eventType,
    status: status,
    message: message,
    createdAt: now
  };
}

export function normalizeConnectionAuditLog(log: ConnectionAuditLog): ConnectionAuditLog {
  const fallback: ConnectionAuditLog = createConnectionAuditLog(AUDIT_CONFIG_CHANGE, 'info', '', '本机', '');
  fallback.id = log.id !== undefined && log.id.length > 0 ? log.id : fallback.id;
  fallback.profileId = log.profileId !== undefined ? log.profileId : '';
  fallback.profileName = log.profileName !== undefined && log.profileName.length > 0 ? log.profileName : '本机';
  fallback.eventType = log.eventType !== undefined && log.eventType.length > 0 ? log.eventType : AUDIT_CONFIG_CHANGE;
  fallback.status = log.status !== undefined && log.status.length > 0 ? log.status : 'info';
  fallback.message = log.message !== undefined ? log.message : '';
  fallback.createdAt = log.createdAt !== undefined && log.createdAt > 0 ? log.createdAt : fallback.createdAt;
  return fallback;
}

export function cloneAuditLog(log: ConnectionAuditLog): ConnectionAuditLog {
  return normalizeConnectionAuditLog(JSON.parse(JSON.stringify(log)) as ConnectionAuditLog);
}
