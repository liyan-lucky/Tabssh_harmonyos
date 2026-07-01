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
import { AUDIT_BULK_ACTION } from '../common/models/ConnectionAuditLog';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';
import { createIconColorFilter } from '../common/IconUtils';

interface SortChipItem {
  titleKey: string;
  mode: string;
}

@Entry
@Component
struct SavedHostsPage {
  @State profiles: ConnectionProfile[] = [];
  @State groups: ConnectionGroup[] = [];
  @State searchKeyword: string = '';
  @State sortMode: string = SORT_MANUAL;
  @State favoriteOnly: boolean = false;
  @State selectedGroupId: string = '';
  @State bulkMode: boolean = false;
  @State selectedProfileIds: string[] = [];
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;
  @StorageLink('profileRefreshToken')
  @Watch('onProfileRefreshTokenChanged')
  profileRefreshToken: number = 0;

  private readonly accentColor: string = '#0A84FF';
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
  }

  onPageShow(): void {
    this.reload();
  }

  onProfileRefreshTokenChanged(): void {
    this.reload();
  }

  private reload(): void {
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

  private toast(message: string): void {
    promptAction.showToast({ message: message, duration: 1800 });
  }

  private openEditor(profileId: string = ''): void {
    if (profileId.length > 0) {
      router.pushUrl({ url: 'pages/ConnectionEditPage', params: { profileId: profileId } });
      return;
    }
    router.pushUrl({ url: 'pages/ConnectionEditPage' });
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

  @Builder
  Header() {
    Row() {
      Image($rawfile('ft_back.svg'))
        .width(22)
        .height(22)
        .colorFilter(createIconColorFilter(this.textPrimary()))
        .onClick(() => router.back())
      Column({ space: 2 }) {
        Text(this.t('savedHosts.title'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary())
        Text(this.t('savedHosts.subtitle'))
          .fontSize(12)
          .fontColor(this.textSecond())
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
      Text(this.t('common.add'))
        .fontSize(13)
        .fontColor(this.accentColor)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor(this.iconSoftBg())
        .borderRadius(11)
        .onClick(() => this.openEditor())
    }
    .width('100%')
    .height(68)
    .padding({ left: 20, right: 20, top: 8 })
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
      .margin({ right: 8, bottom: 6 })
      .onClick(action)
  }

  @Builder
  HighlightedText(value: string, fontSize: number, fontColor: string, weight: FontWeight = FontWeight.Regular,
    maxLines: number = 1) {
    Text() {
      if (this.matchStart(value) >= 0) {
        Span(this.matchBefore(value)).fontColor(fontColor)
        Span(this.matchText(value))
          .fontColor(this.accentColor)
          .fontWeight(FontWeight.Medium)
          .textBackgroundStyle({ color: this.highlightBg() })
        Span(this.matchAfter(value)).fontColor(fontColor)
      } else {
        Span(value).fontColor(fontColor)
      }
    }
    .fontSize(fontSize)
    .fontWeight(weight)
    .maxLines(maxLines)
    .textOverflow({ overflow: TextOverflow.Ellipsis })
  }

  @Builder
  FilterCard() {
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

      Flex({ wrap: FlexWrap.Wrap }) {
        this.FilterChip(this.t('common.all'), !this.favoriteOnly, () => {
          this.favoriteOnly = false;
          this.reload();
        })
        this.FilterChip(this.t('connections.onlyFavorites'), this.favoriteOnly, () => {
          this.favoriteOnly = true;
          this.reload();
        })
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

      Flex({ wrap: FlexWrap.Wrap }) {
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
    .margin({ top: 8 })
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
            Text(this.t('common.edit'))
              .fontSize(12)
              .fontColor(this.textSecond())
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor(this.chipBg())
              .borderRadius(9)
              .onClick(() => this.openEditor(profile.id))
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
      .height(96)
      .padding({ left: 12, right: 12 })

      if (index < this.profiles.length - 1) {
        Divider().color(this.lineColor()).margin({ left: this.bulkMode ? 108 : 62 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.FilterCard()
          this.BulkActionBar()
          if (this.profiles.length === 0) {
            Row() {
              Text(this.t('savedHosts.empty'))
                .fontSize(14)
                .fontColor(this.textSecond())
            }
            .width('92%')
            .height(72)
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
            .margin({ top: 10, bottom: 16 })
          }
          Text(this.t('savedHosts.privacy'))
            .fontSize(12)
            .fontColor(this.textMuted())
            .lineHeight(18)
            .width('92%')
            .margin({ bottom: 20 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.avoidStatusBarHeight, bottom: this.avoidNavigationBarHeight })
    .backgroundColor(this.pageBg())
  }
}
