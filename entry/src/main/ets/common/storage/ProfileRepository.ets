import { ConnectionProfile, createEmptyConnectionProfile, cloneProfile } from '../models/ConnectionProfile';

class MemoryProfileRepository {
  private profiles: ConnectionProfile[] = [];

  constructor() {
    const demo: ConnectionProfile = createEmptyConnectionProfile();
    demo.id = 'demo-localhost';
    demo.name = '示例连接';
    demo.host = '192.168.1.1';
    demo.username = 'root';
    // 测试凭据只允许在运行内存中由测试者输入，不写入源码或文档。
    demo.password = '';
    this.profiles.push(demo);
  }

  list(): ConnectionProfile[] {
    return this.profiles.map((item: ConnectionProfile) => cloneProfile(item));
  }

  get(id: string): ConnectionProfile | undefined {
    const found: ConnectionProfile | undefined = this.profiles.find((item: ConnectionProfile) => item.id === id);
    if (found === undefined) {
      return undefined;
    }
    return cloneProfile(found);
  }

  save(profile: ConnectionProfile): void {
    const index: number = this.profiles.findIndex((item: ConnectionProfile) => item.id === profile.id);
    if (index >= 0) {
      this.profiles[index] = cloneProfile(profile);
    } else {
      this.profiles.push(cloneProfile(profile));
    }
  }

  remove(id: string): void {
    this.profiles = this.profiles.filter((item: ConnectionProfile) => item.id !== id);
  }

  clearSensitiveFields(): void {
    this.profiles.forEach((item: ConnectionProfile) => {
      item.password = '';
      item.privateKeyPassphrase = '';
    });
  }
}

export const ProfileRepository: MemoryProfileRepository = new MemoryProfileRepository();
