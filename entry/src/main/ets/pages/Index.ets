import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ConnectionProfile } from '../common/models/ConnectionProfile';
import {
  ConnectionGroup,
  ProfileFilter,
  SORT_CONNECTION_COUNT_DESC,
  SORT_FAVORITE_FIRST,
  SORT_HOST_ASC,
  SORT_LAST_CONNECTED_DESC,
  SORT_MANUAL,
  SORT_NAME_ASC,
  createDefaultProfileFilter
} from '../common/models/ConnectionGroup';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { NativeSshCore } from '../common/native/NativeSshCore';
import { createIconColorFilter } from '../common/IconUtils';
import { AUDIT_BULK_ACTION } from '../common/models/ConnectionAuditLog';
import { AppTheme } from '../common/AppTheme';
import {
  AppSettingsRepository,
  LANG_EN,
  LANG_SYSTEM,
  LANG_ZH,
  THEME_DARK,
  THEME_LIGHT
} from '../common/AppSettings';
import { I18n } from '../common/I18n';

interface WorkbenchAction {
  titleKey: string;
  icon: Resource;
  type: string;
}

interface BottomTabItem {
  titleKey: string;
  icon: Resource;
}

interface SortChipItem {
  titleKey: string;
  mode: string;
}

@Entry
@Component
struct Index {
  @State profiles: ConnectionProfile[] = [];
  @State nativeVersion: string = '';
  @State activeTab: number = 0;
  @State searchKeyword: string = '';
  @State sortMode: string = SORT_MANUAL;
  @State favoriteOnly: boolean = false;
  @State groups: ConnectionGroup[] = [];
  @State selectedGroupId: string = '';
  @State bulkMode: boolean = false;
  @State selectedProfileIds: string[] = [];
  @State autoSave: boolean = true;
  @State autoCompress: boolean = false;
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;

  private readonly accentColor: string = '#0A84FF';

  private actions: WorkbenchAction[] = [
    { titleKey: 'workbench.history', icon: $rawfile('settings_timer.svg'), type: 'history' },
    { titleKey: 'workbench.groups', icon: $rawfile('settings_folder.svg'), type: 'groups' },
    { titleKey: 'workbench.importExport', icon: $rawfile('settings_update.svg'), type: 'transfer' },
    { titleKey: 'workbench.keys', icon: $rawfile('settings_shield.svg'), type: 'keys' },
    { titleKey: 'workbench.redis', icon: $rawfile('settings_cpu.svg'), type: 'redis' },
    { titleKey: 'workbench.sftp', icon: $rawfile('ft_remote.svg'), type: 'sftp' },
    { titleKey: 'workbench.files', icon: $rawfile('settings_folder.svg'), type: 'files' },
    { titleKey: 'workbench.lan', icon: $rawfile('settings_network.svg'), type: 'lan' },
    { titleKey: 'workbench.audit', icon: $rawfile('settings_timer.svg'), type: 'logs' },
    { titleKey: 'workbench.notes', icon: $rawfile('settings_privacy.svg'), type: 'notes' }
  ];

  private tabs: BottomTabItem[] = [
    { titleKey: 'tab.workbench', icon: $rawfile('settings_tune.svg') },
    { titleKey: 'tab.connections', icon: $rawfile('settings_network.svg') },
    { titleKey: 'tab.monitor', icon: $rawfile('settings_monitor.svg') },
    { titleKey: 'tab.mine', icon: $rawfile('settings_display.svg') }
  ];

  private sortChips: SortChipItem[] = [
    { titleKey: 'connections.defaultSort', mode: SORT_MANUAL },
    { titleKey: 'connections.nameSort', mode: SORT_NAME_ASC },
    { titleKey: 'connections.hostSort', mode: SORT_HOST_ASC },
    { titleKey: 'connections.recentSort', mode: SORT_LAST_CONNECTED_DESC },
    { titleKey: 'connections.countSort', mode: SORT_CONNECTION_COUNT_DESC },
    { titleKey: 'connections.favoriteSort', mode: SORT_FAVORITE_FIRST }
  ];

  aboutToAppear(): void {
    this.reload();
    this.nativeVersion = NativeSshCore.version();
  }

  onPageShow(): void {
    this.reload();
  }

  reload(): void {
    const groups: ConnectionGroup[] = ProfileRepository.listGroups();
    this.groups = groups;
    if (this.selectedGroupId.length > 0 &&
      groups.findIndex((item: ConnectionGroup) => item.id === this.selectedGroupId) < 0) {
      this.selectedGroupId = '';
    }
    const filter: ProfileFilter = createDefaultProfileFilter();
    filter.keyword = this.searchKeyword;
    filter.groupId = this.selectedGroupId;
    filter.favoriteOnly = this.favoriteOnly;
    filter.sortMode = this.sortMode;
    this.profiles = ProfileRepository.listFiltered(filter);
    this.pruneBulkSelection();
  }

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

  private lineColor(): string {
    return AppTheme.line(this.themeMode);
  }

  private chipBg(): string {
    return AppTheme.chipBg(this.themeMode);
  }

  private iconSoftBg(): string {
    return AppTheme.iconSoftBg(this.themeMode);
  }

  private highlightBg(): string {
    return AppTheme.isDark(this.themeMode) ? '#1D3B5F' : '#EAF3FF';
  }

  private favoriteBg(): string {
    return AppTheme.isDark(this.themeMode) ? '#3A2A14' : '#FFF7ED';
  }

  private bottomNavBg(): string {
    return AppTheme.bottomNavBg(this.themeMode);
  }

  private bottomNavBorder(): string {
    return AppTheme.bottomNavBorder(this.themeMode);
  }

  private bottomNavInactive(): string {
    return AppTheme.bottomNavInactive(this.themeMode);
  }

  private bottomNavShadow(): string {
    return AppTheme.bottomNavShadow(this.themeMode);
  }

  private bottomNavBottomInset(): number {
    return this.avoidNavigationBarHeight + 16;
  }

  private contentBottomInset(): number {
    return this.avoidNavigationBarHeight + 96;
  }

  private headerOverlayHeight(): number {
    return this.avoidStatusBarHeight + 76;
  }

  private contentTopInset(): number {
    return this.headerOverlayHeight() - 14;
  }

  private openToolboxPage(): void {
    router.pushUrl({ url: 'pages/ToolboxPage' });
  }

  private visibleWorkbenchHosts(): ConnectionProfile[] {
    return ProfileRepository.list().slice(0, 4);
  }

  private toast(message: string): void {
    promptAction.showToast({ message: message, duration: 1800 });
  }

  private setThemeMode(mode: string): void {
    this.themeMode = mode;
    AppSettingsRepository.setThemeMode(mode);
    this.toast(this.t('settings.themeToast'));
  }

  private setLanguage(language: string): void {
    this.language = language;
    AppSettingsRepository.setLanguage(language);
    this.toast(I18n.t(language, 'settings.languageToast'));
  }

  private languageSummaryText(): string {
    const effectiveLanguage: string = AppSettingsRepository.effectiveLanguage(this.language);
    const effectiveName: string = I18n.t(effectiveLanguage,
      effectiveLanguage === LANG_EN ? 'common.english' : 'common.chinese');
    if (this.language === LANG_SYSTEM) {
      return this.t('settings.languageSystemSub') + effectiveName;
    }
    return effectiveName;
  }

  private toggleFavorite(profile: ConnectionProfile): void {
    const updated: ConnectionProfile = JSON.parse(JSON.stringify(profile)) as ConnectionProfile;
    updated.favorite = !updated.favorite;
    ProfileRepository.save(updated);
    this.reload();
  }

  private pruneBulkSelection(): void {
    const nextSelected: string[] = [];
    this.selectedProfileIds.forEach((id: string) => {
      if (this.profiles.findIndex((item: ConnectionProfile) => item.id === id) >= 0) {
        nextSelected.push(id);
      }
    });
    this.selectedProfileIds = nextSelected;
  }

  private selectedCount(): number {
    return this.selectedProfileIds.length;
  }

  private isProfileSelected(profileId: string): boolean {
    return this.selectedProfileIds.indexOf(profileId) >= 0;
  }

  private toggleBulkMode(): void {
    this.bulkMode = !this.bulkMode;
    this.selectedProfileIds = [];
  }

  private toggleProfileSelected(profile: ConnectionProfile): void {
    const nextSelected: string[] = [];
    let found: boolean = false;
    this.selectedProfileIds.forEach((id: string) => {
      if (id === profile.id) {
        found = true;
      } else {
        nextSelected.push(id);
      }
    });
    if (!found) {
      nextSelected.push(profile.id);
    }
    this.selectedProfileIds = nextSelected;
  }

  private selectAllVisible(): void {
    this.selectedProfileIds = this.profiles.map((item: ConnectionProfile) => item.id);
  }

  private clearBulkSelection(): void {
    this.selectedProfileIds = [];
  }

  private applyBulkFavorite(favorite: boolean): void {
    if (this.selectedProfileIds.length === 0) {
      this.toast(this.t('connections.selectHostFirst'));
      return;
    }
    const count: number = this.selectedProfileIds.length;
    this.profiles.forEach((item: ConnectionProfile) => {
      if (this.isProfileSelected(item.id)) {
        const updated: ConnectionProfile = JSON.parse(JSON.stringify(item)) as ConnectionProfile;
        updated.favorite = favorite;
        ProfileRepository.save(updated);
      }
    });
    ProfileRepository.recordAuditLog(AUDIT_BULK_ACTION, 'success', '', this.t('connections.bulkActionLabel'),
      (favorite ? this.t('connections.bulkFavoriteLog') : this.t('connections.bulkUnfavoriteLog')) +
      count.toString() + this.t('connections.hostCountSuffix'));
    this.toast(favorite ? this.t('connections.bulkFavoriteDone') : this.t('connections.bulkUnfavoriteDone'));
    this.reload();
  }

  private applyBulkGroup(groupId: string): void {
    if (this.selectedProfileIds.length === 0) {
      this.toast(this.t('connections.selectHostFirst'));
      return;
    }
    const count: number = this.selectedProfileIds.length;
    this.profiles.forEach((item: ConnectionProfile) => {
      if (this.isProfileSelected(item.id)) {
        const updated: ConnectionProfile = JSON.parse(JSON.stringify(item)) as ConnectionProfile;
        updated.groupId = groupId;
        ProfileRepository.save(updated);
      }
    });
    ProfileRepository.recordAuditLog(AUDIT_BULK_ACTION, 'success', '', this.t('connections.bulkActionLabel'),
      this.t('connections.bulkMoveLog') + count.toString() + this.t('connections.hostCountSuffix'));
    this.toast(this.t('connections.bulkMoveDone'));
    this.reload();
  }

  private removeSelectedProfiles(): void {
    if (this.selectedProfileIds.length === 0) {
      this.toast(this.t('connections.selectHostFirst'));
      return;
    }
    const count: number = this.selectedProfileIds.length;
    this.selectedProfileIds.forEach((id: string) => ProfileRepository.remove(id));
    ProfileRepository.recordAuditLog(AUDIT_BULK_ACTION, 'success', '', this.t('connections.bulkActionLabel'),
      this.t('connections.bulkDeleteLog') + count.toString() + this.t('connections.hostCountSuffix'));
    this.toast(this.t('connections.bulkDeleteDone'));
    this.selectedProfileIds = [];
    this.bulkMode = false;
    this.reload();
  }

  private matchStart(value: string): number {
    const keyword: string = this.searchKeyword.trim().toLowerCase();
    if (keyword.length === 0) {
      return -1;
    }
    return value.toLowerCase().indexOf(keyword);
  }

  private matchBefore(value: string): string {
    const start: number = this.matchStart(value);
    return start >= 0 ? value.substring(0, start) : value;
  }

  private matchText(value: string): string {
    const start: number = this.matchStart(value);
    const keyword: string = this.searchKeyword.trim();
    return start >= 0 ? value.substring(start, start + keyword.length) : '';
  }

  private matchAfter(value: string): string {
    const start: number = this.matchStart(value);
    const keyword: string = this.searchKeyword.trim();
    return start >= 0 ? value.substring(start + keyword.length) : '';
  }

  private matchedField(profile: ConnectionProfile): string {
    if (this.searchKeyword.trim().length === 0) {
      return '';
    }
    if (this.matchStart(profile.name) >= 0) {
      return this.t('connections.matchedName');
    }
    if (this.matchStart(profile.host) >= 0) {
      return this.t('connections.matchedHost');
    }
    if (this.matchStart(profile.username) >= 0) {
      return this.t('connections.matchedUser');
    }
    if (this.matchStart(profile.remarks) >= 0) {
      return this.t('connections.matchedRemark');
    }
    return '';
  }

  private openGroupPage(): void {
    router.pushUrl({ url: 'pages/ConnectionGroupPage' });
  }

  private formatConnectionMeta(profile: ConnectionProfile): string {
    if (profile.connectionCount > 0 && profile.lastConnectedAt > 0) {
      return this.t('workbench.connectedCount') + profile.connectionCount.toString() +
        this.t('workbench.connectedTimes');
    }
    if (profile.lastErrorMessage.length > 0) {
      return this.t('workbench.lastFailure') + profile.lastErrorMessage;
    }
    return this.t('workbench.neverConnected');
  }

  private handleAction(item: WorkbenchAction): void {
    if (item.type === 'sftp') {
      router.pushUrl({ url: 'pages/SftpPage' });
      return;
    }
    if (item.type === 'groups') {
      this.openGroupPage();
      return;
    }
    if (item.type === 'history') {
      router.pushUrl({ url: 'pages/ConnectionHistoryPage' });
      return;
    }
    if (item.type === 'transfer') {
      router.pushUrl({ url: 'pages/ConnectionImportExportPage' });
      return;
    }
    if (item.type === 'keys') {
      this.toast(this.t('workbench.keysToast'));
      return;
    }
    if (item.type === 'redis') {
      this.toast(this.t('workbench.redisToast'));
      return;
    }
    if (item.type === 'files') {
      this.toast(this.t('workbench.filesToast'));
      return;
    }
    if (item.type === 'lan') {
      this.toast(this.t('workbench.lanToast'));
      return;
    }
    if (item.type === 'logs') {
      router.pushUrl({ url: 'pages/AuditLogPage' });
      return;
    }
    if (item.type === 'notes') {
      this.toast(this.t('workbench.notesToast'));
      return;
    }
  }

  @Builder
  Header() {
    if (this.activeTab === 2) {
      Row() {
        Column({ space: 2 }) {
          Text(this.t('monitor.title'))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary())
          Text(this.t('monitor.online'))
            .fontSize(13)
            .fontColor(this.textSecond())
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($rawfile('settings_terminal.svg'))
          .width(22)
          .height(22)
          .colorFilter(createIconColorFilter(this.textPrimary()))
          .margin({ right: 18 })
        Circle()
          .width(14)
          .height(14)
          .fill('#34C759')
          .margin({ right: 16 })
        Image($rawfile('ft_sort.svg'))
          .width(22)
          .height(22)
          .colorFilter(createIconColorFilter(this.textSecond()))
      }
      .width('100%')
      .height(56)
      .padding({ left: 22, right: 22, top: 0 })
    } else {
      Row() {
        Blank().layoutWeight(1)
        Row() {
          if (this.activeTab === 0) {
            Image($rawfile('settings_server.svg'))
              .width(21)
              .height(21)
              .colorFilter(createIconColorFilter(this.textPrimary()))
              .margin({ right: 8 })
          }
          Text(this.t(this.tabs[this.activeTab].titleKey))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary())
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .layoutWeight(2)

        Row() {
          if (this.activeTab === 0) {
            Image($rawfile('settings_tune.svg'))
              .width(22)
              .height(22)
              .colorFilter(createIconColorFilter(this.textPrimary()))
              .onClick(() => this.openToolboxPage())
          } else if (this.activeTab === 1) {
            Image($rawfile('ft_new_folder.svg'))
              .width(26)
              .height(26)
              .colorFilter(createIconColorFilter(this.accentColor))
              .onClick(() => router.pushUrl({ url: 'pages/ConnectionEditPage' }))
          }
        }
        .justifyContent(FlexAlign.End)
        .layoutWeight(1)
      }
      .width('100%')
      .height(52)
      .padding({ left: 22, right: 22, top: 0 })
    }
  }

  @Builder
  SectionLabel(title: string) {
    Text(title)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.textSecond())
      .width('92%')
      .margin({ top: 14, bottom: 8 })
  }

  @Builder
  CompactOptionRow(icon: Resource, title: string, subtitle: string, color: string, action: () => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        Row() {
          Image(icon)
            .width(21)
            .height(21)
            .colorFilter(createIconColorFilter('#FFFFFF'))
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(color)
        .borderRadius(10)
        .margin({ right: 12 })

        Column({ space: 2 }) {
          Text(title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
            .maxLines(1)
          if (subtitle.length > 0) {
            Text(subtitle)
              .fontSize(12)
              .fontColor(this.textSecond())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($rawfile('ft_up.svg'))
          .width(18)
          .height(18)
          .rotate({ angle: 90 })
          .colorFilter(createIconColorFilter(this.textMuted()))
      }
      .width('100%')
      .height(subtitle.length > 0 ? 62 : 54)
      .padding({ left: 14, right: 14 })
      .onClick(action)

      if (showDivider) {
        Divider().color(this.lineColor()).strokeWidth(1).margin({ left: 62 })
      }
    }
    .width('100%')
  }

  @Builder
  SettingsIconBox(icon: Resource, color: string) {
    Row() {
      Image(icon)
        .width(21)
        .height(21)
        .colorFilter(createIconColorFilter('#FFFFFF'))
    }
    .width(36)
    .height(36)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(color)
    .borderRadius(10)
    .margin({ right: 12 })
  }

  @Builder
  SettingsSegmentButton(title: string, selected: boolean, width: number, action: () => void) {
    Text(title)
      .fontSize(12)
      .fontWeight(selected ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(selected ? Color.White : this.textSecond())
      .width(width)
      .height(32)
      .textAlign(TextAlign.Center)
      .backgroundColor(selected ? this.accentColor : this.chipBg())
      .borderRadius(10)
      .onClick(action)
  }

  @Builder
  SettingsLanguageRow(showDivider: boolean = true) {
    Column() {
      Row() {
        this.SettingsIconBox($rawfile('settings_language.svg'), '#1598E8')
        Column({ space: 1 }) {
          Text(this.t('settings.language'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
          Text(this.languageSummaryText())
            .fontSize(12)
            .fontColor(this.textSecond())
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Row({ space: 6 }) {
          this.SettingsSegmentButton(this.t('common.system'), this.language === LANG_SYSTEM, 60,
            () => this.setLanguage(LANG_SYSTEM))
          this.SettingsSegmentButton(this.t('common.zhShort'), this.language === LANG_ZH, 44,
            () => this.setLanguage(LANG_ZH))
          this.SettingsSegmentButton('EN', this.language === LANG_EN, 44, () => this.setLanguage(LANG_EN))
        }
      }
      .width('100%')
      .height(64)
      .padding({ left: 14, right: 12 })
      if (showDivider) {
        Divider().color(this.lineColor()).margin({ left: 62 })
      }
    }
  }

  @Builder
  SettingsThemeRow(showDivider: boolean = true) {
    Column() {
      Row() {
        this.SettingsIconBox($rawfile('settings_palette.svg'), '#20B8E6')
        Column({ space: 1 }) {
          Text(this.t('settings.theme'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
          Text(this.themeMode === THEME_DARK ? this.t('common.dark') : this.t('common.light'))
            .fontSize(12)
            .fontColor(this.textSecond())
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Row({ space: 8 }) {
          this.SettingsSegmentButton(this.t('common.light'), this.themeMode !== THEME_DARK, 64,
            () => this.setThemeMode(THEME_LIGHT))
          this.SettingsSegmentButton(this.t('common.dark'), this.themeMode === THEME_DARK, 64,
            () => this.setThemeMode(THEME_DARK))
        }
      }
      .width('100%')
      .height(64)
      .padding({ left: 14, right: 12 })
      if (showDivider) {
        Divider().color(this.lineColor()).margin({ left: 62 })
      }
    }
  }

  @Builder
  SettingsValueRow(icon: Resource, title: string, value: string, color: string, action: () => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        this.SettingsIconBox(icon, color)
        Column({ space: 1 }) {
          Text(title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
          if (value.length > 0) {
            Text(value)
              .fontSize(12)
              .fontColor(this.textSecond())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Image($rawfile('ft_up.svg'))
          .width(18)
          .height(18)
          .rotate({ angle: 90 })
          .colorFilter(createIconColorFilter(this.textMuted()))
      }
      .width('100%')
      .height(58)
      .padding({ left: 14, right: 14 })
      .onClick(action)
      if (showDivider) {
        Divider().color(this.lineColor()).margin({ left: 62 })
      }
    }
  }

  @Builder
  SettingsToggleRow(icon: Resource, title: string, enabled: boolean, color: string,
    action: (value: boolean) => void, showDivider: boolean = true) {
    Column() {
      Row() {
        this.SettingsIconBox(icon, color)
        Column({ space: 1 }) {
          Text(title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
          Text(enabled ? this.t('common.enabled') : this.t('common.disabled'))
            .fontSize(12)
            .fontColor(this.textSecond())
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: enabled })
          .selectedColor(this.accentColor)
          .switchPointColor(Color.White)
          .onChange(action)
      }
      .width('100%')
      .height(58)
      .padding({ left: 14, right: 10 })
      if (showDivider) {
        Divider().color(this.lineColor()).margin({ left: 62 })
      }
    }
  }

  @Builder
  ActionRow(item: WorkbenchAction, index: number) {
    Column() {
      Row() {
        Image(item.icon)
          .width(22)
          .height(22)
          .colorFilter(createIconColorFilter(this.accentColor))
          .margin({ left: 13, right: 13 })
        Text(this.t(item.titleKey))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary())
          .layoutWeight(1)
        Image($rawfile('ft_up.svg'))
          .width(18)
          .height(18)
          .rotate({ angle: 90 })
          .colorFilter(createIconColorFilter(this.textMuted()))
          .margin({ right: 2 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 14, right: 14 })
      .onClick(() => this.handleAction(item))

      if (index < this.actions.length - 1) {
        Divider().color(this.lineColor()).strokeWidth(1)
      }
    }
    .width('100%')
  }

  @Builder
  FilterChip(title: string, selected: boolean, action: () => void) {
    Text(title)
      .fontSize(12)
      .fontColor(selected ? Color.White : this.textSecond())
      .fontWeight(selected ? FontWeight.Medium : FontWeight.Regular)
      .padding({ left: 11, right: 11, top: 6, bottom: 6 })
      .backgroundColor(selected ? this.accentColor : this.chipBg())
      .borderRadius(12)
      .margin({ right: 8 })
      .onClick(action)
  }

  @Builder
  HighlightedText(value: string, fontSize: number, fontColor: string, weight: FontWeight = FontWeight.Regular,
    maxLines: number = 1) {
    Text() {
      if (this.matchStart(value) >= 0) {
        Span(this.matchBefore(value))
          .fontColor(fontColor)
        Span(this.matchText(value))
          .fontColor(this.accentColor)
          .fontWeight(FontWeight.Medium)
          .textBackgroundStyle({ color: this.highlightBg() })
        Span(this.matchAfter(value))
          .fontColor(fontColor)
      } else {
        Span(value)
          .fontColor(fontColor)
      }
    }
    .fontSize(fontSize)
    .fontWeight(weight)
    .maxLines(maxLines)
    .textOverflow({ overflow: TextOverflow.Ellipsis })
  }

  @Builder
  ConnectionFilterCard() {
    Column({ space: 10 }) {
      Row() {
        Image($rawfile('settings_tune.svg'))
          .width(18)
          .height(18)
          .colorFilter(createIconColorFilter(this.textSecond()))
          .margin({ right: 8 })
        TextInput({ placeholder: this.t('connections.searchPlaceholder'), text: this.searchKeyword })
          .fontSize(14)
          .fontColor(this.textPrimary())
          .placeholderColor(this.textMuted())
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(38)
          .onChange((value: string) => {
            this.searchKeyword = value;
            this.reload();
          })
      }
      .width('100%')
      .height(42)
      .padding({ left: 12, right: 12 })
      .backgroundColor(this.elevatedBg())
      .borderRadius(14)

      Row() {
        this.FilterChip(this.t('common.all'), !this.favoriteOnly, () => {
          this.favoriteOnly = false;
          this.reload();
        })
        this.FilterChip(this.t('connections.onlyFavorites'), this.favoriteOnly, () => {
          this.favoriteOnly = true;
          this.reload();
        })
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        this.FilterChip(this.t('connections.allGroups'), this.selectedGroupId.length === 0, () => {
          this.selectedGroupId = '';
          this.reload();
        })
        ForEach(this.groups, (group: ConnectionGroup) => {
          this.FilterChip(group.name, this.selectedGroupId === group.id, () => {
            this.selectedGroupId = group.id;
            this.reload();
          })
        }, (group: ConnectionGroup) => group.id)
        this.FilterChip(this.t('connections.manageGroups'), false, () => this.openGroupPage())
      }
      .width('100%')

      Row() {
        ForEach(this.sortChips, (item: SortChipItem) => {
          this.FilterChip(this.t(item.titleKey), this.sortMode === item.mode, () => {
            this.sortMode = item.mode;
            this.reload();
          })
        }, (item: SortChipItem) => item.mode)
      }
      .width('100%')
    }
    .width('92%')
    .padding(12)
    .backgroundColor(this.cardBg())
    .borderRadius(18)
    .shadow({ radius: 8, color: AppTheme.shadow(this.themeMode), offsetY: 2 })
  }

  @Builder
  BulkActionBar() {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 2 }) {
          Text(this.bulkMode ? (this.t('connections.bulkSelected') + this.selectedCount().toString() + ' / ' +
            this.profiles.length.toString()) : this.t('connections.bulkManage'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
          Text(this.bulkMode ? this.t('connections.bulkHintActive') : this.t('connections.bulkHint'))
            .fontSize(11)
            .fontColor(this.textSecond())
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        this.FilterChip(this.bulkMode ? this.t('connections.exitBulk') : this.t('connections.bulk'), this.bulkMode,
          () => this.toggleBulkMode())
      }
      .width('100%')

      if (this.bulkMode) {
        Flex({ wrap: FlexWrap.Wrap }) {
          this.FilterChip(this.t('connections.selectAll'), this.selectedCount() === this.profiles.length && this.profiles.length > 0,
            () => this.selectAllVisible())
          this.FilterChip(this.t('connections.clearSelection'), this.selectedCount() === 0, () => this.clearBulkSelection())
          this.FilterChip(this.t('connections.markFavorite'), false, () => this.applyBulkFavorite(true))
          this.FilterChip(this.t('connections.cancelFavorite'), false, () => this.applyBulkFavorite(false))
          ForEach(this.groups, (group: ConnectionGroup) => {
            this.FilterChip(this.t('connections.moveToGroupPrefix') + group.name, false, () => this.applyBulkGroup(group.id))
          }, (group: ConnectionGroup) => group.id)
          this.FilterChip(this.t('connections.deleteSelected'), false, () => this.removeSelectedProfiles())
        }
        .width('100%')
      }
    }
    .width('92%')
    .padding(12)
    .backgroundColor(this.cardBg())
    .borderRadius(16)
    .shadow({ radius: 8, color: AppTheme.shadow(this.themeMode), offsetY: 2 })
    .margin({ top: 10 })
  }

  @Builder
  ProfileRow(profile: ConnectionProfile, index: number) {
    Column() {
      Row() {
        if (this.bulkMode) {
          Text(this.isProfileSelected(profile.id) ? this.t('connections.selected') : this.t('connections.unselected'))
            .fontSize(11)
            .fontColor(this.isProfileSelected(profile.id) ? Color.White : this.textSecond())
            .fontWeight(FontWeight.Medium)
            .width(38)
            .height(28)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.isProfileSelected(profile.id) ? this.accentColor : this.chipBg())
            .borderRadius(9)
            .margin({ right: 8 })
            .onClick(() => this.toggleProfileSelected(profile))
        }
        Row() {
          Image($rawfile('settings_server.svg'))
            .width(22)
            .height(22)
            .colorFilter(createIconColorFilter(this.accentColor))
        }
        .width(38)
        .height(38)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.iconSoftBg())
        .borderRadius(12)
        .margin({ right: 10 })

        Column({ space: 3 }) {
          Row() {
            Row() {
              this.HighlightedText(profile.name, 16, this.textPrimary(), FontWeight.Medium)
            }
            .layoutWeight(1)
            if (profile.favorite) {
              Text(this.t('common.favorite'))
                .fontSize(10)
                .fontColor('#F59E0B')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(this.favoriteBg())
                .borderRadius(8)
                .margin({ left: 6 })
            }
            if (this.matchedField(profile).length > 0) {
              Text(this.matchedField(profile))
                .fontSize(10)
                .fontColor(this.accentColor)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(this.iconSoftBg())
                .borderRadius(8)
                .margin({ left: 6 })
            }
          }
          .width('100%')
          this.HighlightedText(profile.username + '@' + profile.host + ':' + profile.port.toString(), 12, this.textSecond())
          Text(this.formatConnectionMeta(profile))
            .fontSize(11)
            .fontColor(this.textMuted())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 6 }) {
          if (!this.bulkMode) {
            Text(profile.favorite ? this.t('common.unfavorite') : this.t('common.favorite'))
              .fontSize(12)
              .fontColor(profile.favorite ? '#F59E0B' : this.textSecond())
              .padding({ left: 9, right: 9, top: 5, bottom: 5 })
              .backgroundColor(profile.favorite ? this.favoriteBg() : this.chipBg())
              .borderRadius(9)
              .onClick(() => this.toggleFavorite(profile))
            Text(this.t('common.connect'))
              .fontSize(13)
              .fontColor(this.accentColor)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(this.iconSoftBg())
              .borderRadius(10)
              .onClick(() => router.pushUrl({ url: 'pages/TerminalPage', params: { profileId: profile.id } }))
          } else {
            Text(this.isProfileSelected(profile.id) ? this.t('connections.cancelSelect') : this.t('connections.select'))
              .fontSize(12)
              .fontColor(this.accentColor)
              .padding({ left: 8, right: 8, top: 6, bottom: 6 })
              .backgroundColor(this.iconSoftBg())
              .borderRadius(10)
              .onClick(() => this.toggleProfileSelected(profile))
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .height(76)
      .padding({ left: 12, right: 12 })

      if (index < this.profiles.length - 1) {
        Divider().color(this.lineColor()).margin({ left: this.bulkMode ? 108 : 62 })
      }
    }
    .width('100%')
  }

  @Builder
  WorkbenchHostRow(profile: ConnectionProfile, index: number, total: number) {
    Column() {
      Row() {
        Row() {
          Image($rawfile('settings_server.svg'))
            .width(21)
            .height(21)
            .colorFilter(createIconColorFilter(this.accentColor))
        }
        .width(38)
        .height(38)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.iconSoftBg())
        .borderRadius(12)
        .margin({ right: 10 })

        Column({ space: 3 }) {
          Text(profile.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(profile.username + '@' + profile.host + ':' + profile.port.toString())
            .fontSize(12)
            .fontColor(this.textSecond())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.formatConnectionMeta(profile))
            .fontSize(11)
            .fontColor(this.textMuted())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.t('common.connect'))
          .fontSize(13)
          .fontColor(this.accentColor)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.iconSoftBg())
          .borderRadius(10)
          .onClick(() => router.pushUrl({ url: 'pages/TerminalPage', params: { profileId: profile.id } }))
      }
      .width('100%')
      .height(76)
      .padding({ left: 12, right: 12 })

      if (index < total - 1) {
        Divider().color(this.lineColor()).margin({ left: 60 })
      }
    }
    .width('100%')
  }

  @Builder
  WorkbenchHostList() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text(this.t('workbench.hosts'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary())
          Text(this.t('workbench.hosts.subtitle'))
            .fontSize(12)
            .fontColor(this.textSecond())
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.t('common.add'))
          .fontSize(13)
          .fontColor(this.accentColor)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.iconSoftBg())
          .borderRadius(10)
          .onClick(() => router.pushUrl({ url: 'pages/ConnectionEditPage' }))
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14, bottom: 6 })

      if (this.visibleWorkbenchHosts().length === 0) {
        Row() {
          Text(this.t('workbench.noHosts'))
            .fontSize(14)
            .fontColor(this.textSecond())
        }
        .width('100%')
        .height(62)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.visibleWorkbenchHosts(), (profile: ConnectionProfile, index: number) => {
          this.WorkbenchHostRow(profile, index, this.visibleWorkbenchHosts().length)
        }, (profile: ConnectionProfile) => profile.id)
      }

      Text(this.t('workbench.hosts.tip'))
        .fontSize(11)
        .fontColor(this.textMuted())
        .width('100%')
        .padding({ left: 14, right: 14, bottom: 12 })
    }
    .width('92%')
    .backgroundColor(this.cardBg())
    .borderRadius(18)
    .clip(true)
    .shadow({ radius: 8, color: AppTheme.shadow(this.themeMode), offsetY: 2 })
    .margin({ top: 14 })
  }

  @Builder
  WorkbenchPage() {
    Scroll() {
      Column() {
        Blank().height(this.contentTopInset())
        this.WorkbenchHostList()
        this.SectionLabel(this.t('workbench.actions'))
        Column() {
          ForEach(this.actions, (item: WorkbenchAction, index: number) => {
            this.ActionRow(item, index)
          }, (item: WorkbenchAction) => item.type)
        }
        .width('92%')
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .clip(true)
        .margin({ bottom: 20 })
        Blank().height(this.contentBottomInset())
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  ConnectionPage() {
    Scroll() {
      Column() {
        Blank().height(this.contentTopInset())
        Stack() {
          Text('01 101 001  SSH  110 010 11')
            .fontSize(16)
            .fontColor('#406A88')
            .width('100%')
            .height('100%')
            .textAlign(TextAlign.Center)
          Column({ space: 7 }) {
            Text('SSH')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#38BDF8')
            Text(this.t('connections.heroSubtitle'))
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
        }
        .width('92%')
        .height(122)
        .backgroundColor('#082F49')
        .borderRadius(18)
        .margin({ top: 10 })

        Text(this.t('connections.methods'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary())
          .width('92%')
          .margin({ top: 16 })
        Text(this.t('connections.methodsSubtitle'))
          .fontSize(13)
          .fontColor(this.textSecond())
          .width('92%')
          .margin({ top: 5, bottom: 10 })

        Column() {
          this.CompactOptionRow($rawfile('settings_server.svg'), this.t('connections.sshHost'),
            this.t('connections.sshHostSub'), '#0A84FF',
            () => router.pushUrl({ url: 'pages/ConnectionEditPage' }))
          this.CompactOptionRow($rawfile('settings_folder.svg'), this.t('workbench.groups'),
            this.t('connections.groupsSub'), '#2EA8E5',
            () => this.openGroupPage())
          this.CompactOptionRow($rawfile('settings_update.svg'), this.t('settings.importExport'),
            this.t('connections.importExportSub'), '#22C55E',
            () => router.pushUrl({ url: 'pages/ConnectionImportExportPage' }))
          this.CompactOptionRow($rawfile('ft_folder.svg'), this.t('workbench.sftp'), this.t('connections.sftpSub'), '#35C7D7',
            () => router.pushUrl({ url: 'pages/SftpPage' }))
          this.CompactOptionRow($rawfile('settings_network.svg'), this.t('connections.lan'),
            this.t('connections.lanSub'), '#38BDF8',
            () => this.toast(this.t('connections.lanPendingToast')))
          this.CompactOptionRow($rawfile('settings_terminal.svg'), this.t('connections.localTerminal'),
            this.t('connections.localTerminalSub'), '#22C55E',
            () => this.toast(this.t('connections.localTerminalToast')), false)
        }
        .width('92%')
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .clip(true)

        this.SectionLabel(this.t('connections.savedHosts'))
        this.ConnectionFilterCard()
        this.BulkActionBar()
        if (this.profiles.length === 0) {
          Row() {
            Text(this.t('connections.noMatch'))
              .fontSize(14)
              .fontColor(this.textSecond())
          }
          .width('92%')
          .height(62)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.cardBg())
          .borderRadius(16)
          .margin({ top: 10 })
        } else {
          Column() {
            ForEach(this.profiles, (profile: ConnectionProfile, index: number) => {
              this.ProfileRow(profile, index)
            }, (profile: ConnectionProfile) => profile.id)
          }
          .width('92%')
          .backgroundColor(this.cardBg())
          .borderRadius(16)
          .clip(true)
          .margin({ top: 10 })
        }

        Button(this.t('connections.forward'))
          .height(40)
          .fontSize(14)
          .fontColor(this.accentColor)
          .backgroundColor(this.iconSoftBg())
          .borderRadius(12)
          .margin({ top: 12, bottom: 18 })
          .onClick(() => router.pushUrl({ url: 'pages/PortForwardPage' }))
        Blank().height(this.contentBottomInset())
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  MonitorPage() {
    Column() {
      Blank().height(this.contentTopInset())
      Blank()
      Stack() {
        Circle().width(132).height(132).fill(this.iconSoftBg())
        Image($rawfile('settings_monitor.svg'))
          .width(58)
          .height(58)
          .colorFilter(createIconColorFilter(this.textMuted()))
      }
      Text(this.t('monitor.empty'))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary())
        .margin({ top: 24 })
      Text(this.t('monitor.emptySub'))
        .fontSize(15)
        .fontColor(this.textSecond())
        .margin({ top: 10 })
      Button() {
        Row({ space: 9 }) {
          Image($rawfile('ft_new_folder.svg'))
            .width(21)
            .height(21)
            .colorFilter(createIconColorFilter('#FFFFFF'))
          Text(this.t('monitor.add')).fontSize(16).fontColor(Color.White)
        }
      }
      .width(190)
      .height(48)
      .fontSize(16)
      .backgroundColor(this.accentColor)
      .borderRadius(14)
      .margin({ top: 28 })
      .onClick(() => {
        this.activeTab = 1;
        router.pushUrl({ url: 'pages/ConnectionEditPage' });
      })
      Row({ space: 8 }) {
        Image($rawfile('settings_info.svg'))
          .width(19)
          .height(19)
          .colorFilter(createIconColorFilter(this.textSecond()))
        Text(this.t('monitor.intro')).fontSize(15).fontColor(this.textSecond())
      }
      .margin({ top: 22 })
      .onClick(() => this.toast(this.t('monitor.pendingToast')))
      Blank()
      Row() {
        Image($rawfile('ft_new_folder.svg'))
          .width(26)
          .height(26)
          .colorFilter(createIconColorFilter('#FFFFFF'))
      }
      .width(54)
      .height(54)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.accentColor)
      .borderRadius(16)
      .shadow({ radius: 8, color: '#300A84FF', offsetY: 4 })
      .alignSelf(ItemAlign.End)
      .margin({ right: 20, bottom: 16 })
      .onClick(() => router.pushUrl({ url: 'pages/ConnectionEditPage' }))
      Blank().height(this.contentBottomInset())
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MinePage() {
    Scroll() {
      Column() {
        Blank().height(this.contentTopInset())
        this.SectionLabel(this.t('settings.appearance'))
        Column() {
          this.SettingsLanguageRow()
          this.SettingsThemeRow()
          this.SettingsValueRow($rawfile('settings_display.svg'), this.t('settings.fontSize'),
            this.t('settings.fontMedium'), '#7356E8', () => this.toast(this.t('settings.fontMedium')), false)
        }
        .width('92%')
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .clip(true)

        this.SectionLabel(this.t('settings.files'))
        Column() {
          this.SettingsToggleRow($rawfile('settings_folder.svg'), this.t('settings.autoSave'), this.autoSave, '#6554D9',
            (value: boolean) => this.autoSave = value)
          this.SettingsToggleRow($rawfile('settings_update.svg'), this.t('settings.autoCompress'), this.autoCompress, '#FF9F0A',
            (value: boolean) => this.autoCompress = value)
          this.SettingsValueRow($rawfile('ft_file.svg'), this.t('settings.maxFile'), '100 MB', '#0A84FF',
            () => this.toast('100 MB'), false)
        }
        .width('92%')
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .clip(true)

        Text(this.t('settings.filesHint'))
          .fontSize(12)
          .fontColor(this.textSecond())
          .width('88%')
          .margin({ top: 8 })

        this.SectionLabel(this.t('settings.storage'))
        Column() {
          this.SettingsValueRow($rawfile('settings_update.svg'), this.t('settings.importExport'),
            this.t('settings.importExportSub'), '#22C55E',
            () => router.pushUrl({ url: 'pages/ConnectionImportExportPage' }))
          this.SettingsValueRow($rawfile('ft_delete.svg'), this.t('settings.clearCache'),
            this.t('settings.clearCacheSub'), '#FF2965',
            () => this.toast(this.t('settings.clearCacheSub')))
          this.SettingsValueRow($rawfile('settings_server.svg'), this.t('settings.storageSpace'),
            this.t('settings.storageSpaceSub'), '#32B4DE',
            () => this.toast(this.t('settings.storageSpaceSub')), false)
        }
        .width('92%')
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .clip(true)

        this.SectionLabel(this.t('mine.terminal'))
        Column() {
          this.CompactOptionRow($rawfile('settings_terminal.svg'), this.t('mine.terminalSettings'),
            this.t('mine.terminalSettingsSub'), '#0A84FF',
            () => router.pushUrl({ url: 'pages/TerminalSettingsPage' }), false)
        }
        .width('92%')
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .clip(true)

        this.SectionLabel(this.t('mine.tools'))
        Column() {
          this.CompactOptionRow($rawfile('settings_tune.svg'), this.t('workbench.toolbox'), this.t('mine.toolboxSub'), '#20B8E6',
            () => this.openToolboxPage(), false)
        }
        .width('92%')
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .clip(true)

        this.SectionLabel(this.t('mine.aboutSection'))
        Column() {
          this.CompactOptionRow($rawfile('settings_info.svg'), this.t('mine.about'), this.t('mine.aboutSub'), '#34B7E5',
            () => router.pushUrl({ url: 'pages/AboutPage' }))
          this.CompactOptionRow($rawfile('settings_network.svg'), this.t('mine.share'), '', '#2FC665',
            () => this.toast(this.t('mine.shareToast')))
          this.CompactOptionRow($rawfile('settings_privacy.svg'), this.t('mine.recordInfo'), this.t('mine.recordInfoSub'), '#FF2965',
            () => this.toast(this.t('mine.recordInfoToast')), false)
        }
        .width('92%')
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .clip(true)
        .margin({ bottom: 20 })
        Blank().height(this.contentBottomInset())
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  ContentPage() {
    if (this.activeTab === 0) {
      this.WorkbenchPage()
    } else if (this.activeTab === 1) {
      this.ConnectionPage()
    } else if (this.activeTab === 2) {
      this.MonitorPage()
    } else {
      this.MinePage()
    }
  }

  @Builder
  BottomNavigation() {
    Row() {
      ForEach(this.tabs, (tab: BottomTabItem, index: number) => {
        Column({ space: 3 }) {
          Image(tab.icon)
            .width(22)
            .height(22)
            .colorFilter(createIconColorFilter(this.activeTab === index ? this.accentColor : this.bottomNavInactive()))
          Text(this.t(tab.titleKey))
            .fontSize(11)
            .fontColor(this.activeTab === index ? this.accentColor : this.bottomNavInactive())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 5, bottom: 5 })
        .onClick(() => {
          this.activeTab = index;
          if (index === 1) {
            this.reload();
          }
        })
      }, (tab: BottomTabItem) => tab.titleKey)
    }
    .width('100%')
    .height(60)
    .borderRadius(30)
    .backgroundColor(this.bottomNavBg())
    .backgroundBlurStyle(BlurStyle.Thin, {
      colorMode: AppTheme.isDark(this.themeMode) ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
      adaptiveColor: AdaptiveColor.AVERAGE
    })
    .border({ width: 1, color: this.bottomNavBorder() })
    .shadow({ radius: 10, color: this.bottomNavShadow(), offsetY: 4 })
  }

  @Builder
  HeaderOverlay() {
    Column() {
      Blank().height(this.avoidStatusBarHeight)
      this.Header()
    }
    .width('100%')
    .height(this.headerOverlayHeight())
    .linearGradient({
      angle: 180,
      colors: AppTheme.isDark(this.themeMode)
        ? [['#BB171A1E', 0.0], ['#AA171A1E', 0.05], ['#99171A1E', 0.12], ['#88171A1E', 0.22],
          ['#77171A1E', 0.35], ['#66171A1E', 0.52], ['#55171A1E', 0.72], ['#33171A1E', 0.88],
          ['#00171A1E', 1.0]]
        : [['#C0F0F4FA', 0.0], ['#B0F0F4FA', 0.05], ['#A0F0F4FA', 0.12], ['#90F0F4FA', 0.22],
          ['#80F0F4FA', 0.35], ['#70F0F4FA', 0.52], ['#50F0F4FA', 0.72], ['#30F0F4FA', 0.88],
          ['#00F0F4FA', 1.0]]
    })
  }

  build() {
    Stack() {
      Column() {
        this.ContentPage()
      }
      .width('100%')
      .height('100%')
      .padding({ top: 0, bottom: 0 })

      Column() {
        this.HeaderOverlay()
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .hitTestBehavior(HitTestMode.Transparent)

      Column() {
        this.BottomNavigation()
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .padding({ left: 16, right: 16, bottom: this.bottomNavBottomInset() })
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageBg())
  }
}
