import { PortForwardRule } from '../models/TerminalModels';
import { NativeJsonResult, NativeSshCore } from '../native/NativeSshCore';

class PortForwardManagerImpl {
  private rules: PortForwardRule[] = [];

  list(): PortForwardRule[] {
    return this.rules.slice();
  }

  async addLocal(sessionId: string, localPort: number, remoteHost: string,
    remotePort: number): Promise<PortForwardRule | undefined> {
    const id: string = await NativeSshCore.addLocalForward(sessionId, localPort, remoteHost, remotePort);
    if (id.length === 0) return undefined;
    return this.addRule({
      id: id,
      type: 'local',
      sessionId: sessionId,
      localHost: '127.0.0.1',
      localPort: localPort,
      remoteHost: remoteHost,
      remotePort: remotePort,
      running: true
    });
  }

  async addRemote(sessionId: string, remotePort: number, localHost: string,
    localPort: number): Promise<PortForwardRule | undefined> {
    const id: string = await NativeSshCore.addRemoteForward(sessionId, remotePort, localHost, localPort);
    if (id.length === 0) return undefined;
    return this.addRule({
      id: id,
      type: 'remote',
      sessionId: sessionId,
      localHost: localHost,
      localPort: localPort,
      remoteHost: '127.0.0.1',
      remotePort: remotePort,
      running: true
    });
  }

  async addDynamic(sessionId: string, localPort: number): Promise<PortForwardRule | undefined> {
    const id: string = await NativeSshCore.addDynamicForward(sessionId, localPort);
    if (id.length === 0) return undefined;
    return this.addRule({
      id: id,
      type: 'dynamic',
      sessionId: sessionId,
      localHost: '127.0.0.1',
      localPort: localPort,
      remoteHost: '',
      remotePort: 0,
      running: true
    });
  }

  async remove(forwardId: string): Promise<NativeJsonResult> {
    const result: NativeJsonResult = await NativeSshCore.removeForward(forwardId);
    if (result.ok) {
      this.rules = this.rules.filter((item: PortForwardRule) => item.id !== forwardId);
    }
    return result;
  }

  forgetSession(sessionId: string): void {
    this.rules = this.rules.filter((item: PortForwardRule) => item.sessionId !== sessionId);
  }

  private addRule(rule: PortForwardRule): PortForwardRule {
    this.rules.push(rule);
    return rule;
  }
}

export const PortForwardManager: PortForwardManagerImpl = new PortForwardManagerImpl();
