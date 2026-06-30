import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { ConnectionProfile, createEmptyConnectionProfile, AUTH_PASSWORD, AUTH_PRIVATE_KEY } from '../common/models/ConnectionProfile';
import { ConnectionGroup } from '../common/models/ConnectionGroup';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';

@Entry
@Component
struct ConnectionEditPage {
  @State profile: ConnectionProfile = createEmptyConnectionProfile();
  @State groups: ConnectionGroup[] = [];
  @State isEditing: boolean = false;
  @State privateKeyStatus: string = '';
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

  private textMuted(): string {
    return AppTheme.textMuted(this.themeMode);
  }

  private chipBg(): string {
    return AppTheme.chipBg(this.themeMode);
  }

  aboutToAppear(): void {
    this.groups = ProfileRepository.listGroups();
    const params = router.getParams() as Record<string, string>;
    if (params !== undefined && params['profileId'] !== undefined) {
      const found = ProfileRepository.get(params['profileId']);
      if (found !== undefined) {
        this.profile = found;
        this.isEditing = true;
      }
    }
    if (this.profile.groupId.length === 0 && this.groups.length > 0) {
      this.profile.groupId = this.groups[0].id;
    }
  }

  onPageShow(): void {
    this.groups = ProfileRepository.listGroups();
  }

  save(): void {
    if (this.profile.host.trim().length === 0 || this.profile.username.trim().length === 0 ||
      this.profile.port < 1 || this.profile.port > 65535) {
      promptAction.showToast({ message: this.t('edit.invalidRequired'), duration: 2200 });
      return;
    }
    if (this.profile.authType === AUTH_PRIVATE_KEY && this.profile.privateKeyPath.length === 0) {
      promptAction.showToast({ message: this.t('edit.keyRequired'), duration: 2200 });
      return;
    }
    ProfileRepository.save(this.profile);
    router.back();
  }

  async importPrivateKey(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      const selectedUris: Array<string> = await documentPicker.select(options);
      if (selectedUris.length === 0) {
        return;
      }

      const keyDirectory: string = context.filesDir + '/ssh_keys';
      if (!fs.accessSync(keyDirectory)) {
        fs.mkdirSync(keyDirectory);
      }
      const destination: string = keyDirectory + '/profile_' + this.profile.id + '.key';
      const source: fs.File = fs.openSync(selectedUris[0], fs.OpenMode.READ_ONLY);
      try {
        fs.copyFileSync(source.fd, destination);
      } finally {
        fs.closeSync(source);
      }

      this.profile.privateKeyPath = destination;
      this.privateKeyStatus = this.t('edit.keyImportedStatus');
      promptAction.showToast({ message: this.t('edit.keyImportSuccess'), duration: 1800 });
    } catch (error) {
      this.privateKeyStatus = this.t('edit.keyImportIncomplete');
      promptAction.showToast({ message: this.t('edit.keyImportFailed'), duration: 2200 });
    }
  }

  clearPrivateKey(): void {
    const path: string = this.profile.privateKeyPath;
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const privateDirectoryPrefix: string = context.filesDir + '/ssh_keys/';
    if (path.startsWith(privateDirectoryPrefix) && fs.accessSync(path)) {
      try {
        fs.unlinkSync(path);
      } catch (error) {
        this.privateKeyStatus = this.t('edit.keyDeleteFailed');
        return;
      }
    }
    this.profile.privateKeyPath = '';
    this.profile.privateKeyPassphrase = '';
    this.privateKeyStatus = this.t('edit.keyCleared');
  }

  @Builder
  GroupChip(group: ConnectionGroup) {
    Button(group.name)
      .height(34)
      .fontSize(13)
      .fontColor(this.profile.groupId === group.id ? Color.White : this.textSecond())
      .backgroundColor(this.profile.groupId === group.id ? this.accentColor : this.chipBg())
      .borderRadius(12)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => this.profile.groupId = group.id)
  }

  build() {
    Column() {
      Row() {
        Button(this.t('common.back')).onClick(() => router.back())
        Text(this.t(this.isEditing ? 'edit.titleEdit' : 'edit.titleNew'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary())
          .margin({ left: 12 })
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column() {
          TextInput({ text: this.profile.name, placeholder: this.t('edit.namePlaceholder') })
            .onChange((value: string) => this.profile.name = value)
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.host, placeholder: this.t('edit.hostPlaceholder') })
            .onChange((value: string) => this.profile.host = value)
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.port.toString(), placeholder: this.t('edit.portPlaceholder') })
            .type(InputType.Number)
            .onChange((value: string) => this.profile.port = Number(value))
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.username, placeholder: this.t('edit.usernamePlaceholder') })
            .onChange((value: string) => this.profile.username = value)
            .margin({ bottom: 10 })

          Column() {
            Text(this.t('edit.group'))
              .fontSize(13)
              .fontColor(this.textMuted())
              .width('100%')
              .margin({ bottom: 8 })
            if (this.groups.length === 0) {
              Text(this.t('edit.groupEmpty'))
                .fontSize(12)
                .fontColor('#F59E0B')
                .width('100%')
                .margin({ bottom: 8 })
            } else {
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.groups, (group: ConnectionGroup) => {
                  this.GroupChip(group)
                }, (group: ConnectionGroup) => group.id)
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.cardBg())
          .borderRadius(14)
          .margin({ bottom: 10 })

          Row() {
            Button(this.t('edit.password'))
              .layoutWeight(1)
              .backgroundColor(this.profile.authType === AUTH_PASSWORD ? this.accentColor : this.textMuted())
              .onClick(() => this.profile.authType = AUTH_PASSWORD)
            Button(this.t('edit.privateKey'))
              .layoutWeight(1)
              .backgroundColor(this.profile.authType === AUTH_PRIVATE_KEY ? this.accentColor : this.textMuted())
              .margin({ left: 8 })
              .onClick(() => this.profile.authType = AUTH_PRIVATE_KEY)
          }
          .margin({ bottom: 10 })

          if (this.profile.authType === AUTH_PASSWORD) {
            TextInput({ text: this.profile.password, placeholder: this.t('edit.passwordPlaceholder') })
              .type(InputType.Password)
              .onChange((value: string) => this.profile.password = value)
              .margin({ bottom: 10 })
          } else {
            Button(this.profile.privateKeyPath.length > 0 ? this.t('edit.reimportKey') : this.t('edit.importKey'))
              .width('100%')
              .onClick(() => this.importPrivateKey())
              .margin({ bottom: 8 })
            TextInput({ text: this.profile.privateKeyPath, placeholder: this.t('edit.noKey') })
              .enabled(false)
              .margin({ bottom: 10 })
            if (this.profile.privateKeyPath.length > 0) {
              Button(this.t('edit.deleteKey'))
                .width('100%')
                .onClick(() => this.clearPrivateKey())
                .margin({ bottom: 8 })
            }
            if (this.privateKeyStatus.length > 0) {
              Text(this.privateKeyStatus)
                .fontSize(12)
                .fontColor(this.textMuted())
                .width('100%')
                .margin({ bottom: 8 })
            }
            TextInput({ text: this.profile.privateKeyPassphrase, placeholder: this.t('edit.passphrasePlaceholder') })
              .type(InputType.Password)
              .onChange((value: string) => this.profile.privateKeyPassphrase = value)
              .margin({ bottom: 10 })
          }

          Text(this.t('edit.credentialHint'))
            .fontSize(12)
            .fontColor('#F59E0B')
            .width('100%')
            .margin({ bottom: 10 })

          if (this.profile.hostKeyFingerprint.length > 0) {
            Column() {
              Text(this.t('edit.trustedHostKey'))
                .fontSize(13)
                .fontColor(this.textMuted())
                .width('100%')
              Text(this.profile.hostKeyFingerprint)
                .fontSize(12)
                .fontColor('#38BDF8')
                .width('100%')
                .margin({ top: 4, bottom: 6 })
              Button(this.t('edit.clearTrust'))
                .onClick(() => this.profile.hostKeyFingerprint = '')
            }
            .width('100%')
            .margin({ bottom: 10 })
          }

          TextInput({ text: this.profile.terminalType, placeholder: this.t('edit.terminalTypePlaceholder') })
            .onChange((value: string) => this.profile.terminalType = value)
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.postConnectScript, placeholder: this.t('edit.scriptPlaceholder') })
            .onChange((value: string) => this.profile.postConnectScript = value)
            .margin({ bottom: 10 })
          TextInput({ text: this.profile.timeoutMilliseconds.toString(), placeholder: this.t('edit.timeoutPlaceholder') })
            .type(InputType.Number)
            .onChange((value: string) => this.profile.timeoutMilliseconds = Number(value))
            .margin({ bottom: 10 })

          Button(this.t('common.save'))
            .width('100%')
            .height(44)
            .onClick(() => this.save())
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.avoidStatusBarHeight, bottom: this.avoidNavigationBarHeight })
    .backgroundColor(this.pageBg())
  }
}
