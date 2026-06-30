import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import {
  ConnectionGroup,
  ProfileFilter,
  createConnectionGroup,
  createDefaultProfileFilter
} from '../common/models/ConnectionGroup';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { createIconColorFilter } from '../common/IconUtils';
import { AUDIT_GROUP_CHANGE } from '../common/models/ConnectionAuditLog';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';

@Entry
@Component
// RDB-backed ProfileRepository page; credentials remain runtime-only.
struct ConnectionGroupPage {
  @State groups: ConnectionGroup[] = [];
  @State nextGroupIndex: number = 1;
  @State editingGroupId: string = '';
  @State editingName: string = '';
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;

  private readonly accentColor: string = '#0A84FF';
  private readonly palette: string[] = ['#38BDF8', '#0A84FF', '#35C7D7', '#2EA8E5', '#22C55E', '#F59E0B'];

  private t(key: string): string {
    return I18n.t(this.language, key);
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

  private textPrimary(): string {
    return AppTheme.textPrimary(this.themeMode);
  }

  private textSecond(): string {
    return AppTheme.textSecond(this.themeMode);
  }

  private textMuted(): string {
    return AppTheme.textMuted(this.themeMode);
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

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    this.reload();
  }

  private reload(): void {
    this.groups = ProfileRepository.listGroups();
  }

  private toast(message: string): void {
    promptAction.showToast({ message: message, duration: 1800 });
  }

  private cloneGroup(group: ConnectionGroup): ConnectionGroup {
    return JSON.parse(JSON.stringify(group)) as ConnectionGroup;
  }

  private countProfiles(groupId: string): number {
    const filter: ProfileFilter = createDefaultProfileFilter();
    filter.groupId = groupId;
    return ProfileRepository.listFiltered(filter).length;
  }

  private addGroup(): void {
    const index: number = this.nextGroupIndex;
    const group: ConnectionGroup = createConnectionGroup(this.t('groups.newGroupName') + index.toString(), this.palette[index % this.palette.length]);
    group.sortOrder = this.groups.length + 1;
    ProfileRepository.saveGroup(group);
    ProfileRepository.recordAuditLog(AUDIT_GROUP_CHANGE, 'success', '', this.t('groups.auditProfile'), this.t('groups.auditAdd'));
    this.nextGroupIndex = index + 1;
    this.reload();
    this.startRename(group);
    this.toast(this.t('groups.added'));
  }

  private startRename(group: ConnectionGroup): void {
    this.editingGroupId = group.id;
    this.editingName = group.name;
  }

  private cancelRename(): void {
    this.editingGroupId = '';
    this.editingName = '';
  }

  private saveRename(group: ConnectionGroup): void {
    const name: string = this.editingName.trim();
    if (name.length === 0) {
      this.toast(this.t('groups.nameRequired'));
      return;
    }
    const updated: ConnectionGroup = this.cloneGroup(group);
    updated.name = name;
    ProfileRepository.saveGroup(updated);
    ProfileRepository.recordAuditLog(AUDIT_GROUP_CHANGE, 'success', '', this.t('groups.auditProfile'), this.t('groups.auditRename'));
    this.cancelRename();
    this.reload();
    this.toast(this.t('groups.renamed'));
  }

  private toggleCollapsed(group: ConnectionGroup): void {
    const updated: ConnectionGroup = this.cloneGroup(group);
    updated.collapsed = !updated.collapsed;
    ProfileRepository.saveGroup(updated);
    ProfileRepository.recordAuditLog(AUDIT_GROUP_CHANGE, 'success', '', this.t('groups.auditProfile'),
      updated.collapsed ? this.t('groups.auditCollapse') : this.t('groups.auditExpand'));
    this.reload();
  }

  private cycleColor(group: ConnectionGroup): void {
    const updated: ConnectionGroup = this.cloneGroup(group);
    const currentIndex: number = this.palette.indexOf(updated.colorTag);
    const nextIndex: number = currentIndex < 0 ? 0 : (currentIndex + 1) % this.palette.length;
    updated.colorTag = this.palette[nextIndex];
    ProfileRepository.saveGroup(updated);
    ProfileRepository.recordAuditLog(AUDIT_GROUP_CHANGE, 'success', '', this.t('groups.auditProfile'), this.t('groups.auditColor'));
    this.reload();
  }

  private moveGroup(group: ConnectionGroup, direction: number): void {
    const index: number = this.groups.findIndex((item: ConnectionGroup) => item.id === group.id);
    const targetIndex: number = index + direction;
    if (index < 0 || targetIndex < 0 || targetIndex >= this.groups.length) {
      this.toast(direction < 0 ? this.t('groups.first') : this.t('groups.last'));
      return;
    }
    const current: ConnectionGroup = this.cloneGroup(this.groups[index]);
    const target: ConnectionGroup = this.cloneGroup(this.groups[targetIndex]);
    const currentOrder: number = current.sortOrder;
    current.sortOrder = target.sortOrder;
    target.sortOrder = currentOrder;
    ProfileRepository.saveGroup(current);
    ProfileRepository.saveGroup(target);
    ProfileRepository.recordAuditLog(AUDIT_GROUP_CHANGE, 'success', '', this.t('groups.auditProfile'), this.t('groups.auditMove'));
    this.reload();
  }

  private removeGroup(group: ConnectionGroup): void {
    if (group.id === 'group-default') {
      this.toast(this.t('groups.defaultCannotDelete'));
      return;
    }
    const count: number = this.countProfiles(group.id);
    if (count > 0) {
      this.toast(this.t('groups.notEmpty'));
      return;
    }
    ProfileRepository.removeGroup(group.id);
    ProfileRepository.recordAuditLog(AUDIT_GROUP_CHANGE, 'success', '', this.t('groups.auditProfile'), this.t('groups.auditDelete'));
    this.cancelRename();
    this.reload();
    this.toast(this.t('groups.deleted'));
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
        Text(this.t('groups.title'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary())
        Text(this.t('groups.subtitle'))
          .fontSize(12)
          .fontColor(this.textSecond())
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
      Text(this.t('groups.new'))
        .fontSize(14)
        .fontColor(this.accentColor)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 12, right: 12, top: 7, bottom: 7 })
        .backgroundColor(this.iconSoftBg())
        .borderRadius(12)
        .onClick(() => this.addGroup())
    }
    .width('100%')
    .height(68)
    .padding({ left: 20, right: 20, top: 8 })
  }

  @Builder
  MiniButton(title: string, color: string, bg: string, action: () => void) {
    Text(title)
      .fontSize(12)
      .fontColor(color)
      .padding({ left: 9, right: 9, top: 5, bottom: 5 })
      .backgroundColor(bg)
      .borderRadius(9)
      .onClick(action)
  }

  @Builder
  RenameEditor(group: ConnectionGroup) {
    Column({ space: 8 }) {
      TextInput({ placeholder: this.t('groups.placeholder'), text: this.editingName })
        .fontSize(14)
        .fontColor(this.textPrimary())
        .placeholderColor('#94A3B8')
        .height(38)
        .padding({ left: 10, right: 10 })
        .backgroundColor(this.elevatedBg())
        .borderRadius(12)
        .onChange((value: string) => {
          this.editingName = value;
        })
      Row() {
        this.MiniButton(this.t('groups.save'), this.accentColor, this.iconSoftBg(), () => this.saveRename(group))
        this.MiniButton(this.t('groups.cancel'), this.textSecond(), this.chipBg(), () => this.cancelRename())
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 60, right: 12, bottom: 12 })
  }

  @Builder
  GroupRow(group: ConnectionGroup, index: number) {
    Column() {
      Row() {
        Row() {
          Circle()
            .width(14)
            .height(14)
            .fill(group.colorTag)
        }
        .width(38)
        .height(38)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.chipBg())
        .borderRadius(12)
        .margin({ right: 10 })
        .onClick(() => this.cycleColor(group))

        Column({ space: 4 }) {
          Row() {
            Text(group.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.textPrimary())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .onClick(() => this.startRename(group))
            if (group.id === 'group-default') {
              Text(this.t('groups.default'))
                .fontSize(10)
                .fontColor(this.accentColor)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(this.iconSoftBg())
                .borderRadius(8)
                .margin({ left: 6 })
            }
          }
          .width('100%')
          Text(this.countProfiles(group.id).toString() + this.t('groups.hostUnit') + ' · ' +
            (group.collapsed ? this.t('groups.collapsed') : this.t('groups.expanded')))
            .fontSize(12)
            .fontColor(this.textSecond())
          Text(this.t('groups.renameTip'))
            .fontSize(11)
            .fontColor(this.textMuted())
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 6 }) {
          Row({ space: 6 }) {
            this.MiniButton(this.t('groups.moveUp'), index <= 0 ? this.textMuted() : this.textSecond(), this.chipBg(), () => this.moveGroup(group, -1))
            this.MiniButton(this.t('groups.moveDown'), index >= this.groups.length - 1 ? this.textMuted() : this.textSecond(), this.chipBg(), () => this.moveGroup(group, 1))
          }
          this.MiniButton(group.collapsed ? this.t('groups.expand') : this.t('groups.collapse'), this.textSecond(), this.chipBg(), () => this.toggleCollapsed(group))
          this.MiniButton(this.t('groups.delete'), group.id === 'group-default' ? this.textMuted() : '#EF4444',
            group.id === 'group-default' ? this.elevatedBg() : '#FEF2F2', () => this.removeGroup(group))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .height(92)
      .padding({ left: 12, right: 12 })

      if (this.editingGroupId === group.id) {
        this.RenameEditor(group)
      }

      if (index < this.groups.length - 1) {
        Divider()
          .color(this.lineColor())
          .margin({ left: 60 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          Column({ space: 4 }) {
            Text(this.t('groups.infoTitle'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.textPrimary())
              .width('100%')
            Text(this.t('groups.infoBody'))
              .fontSize(13)
              .fontColor(this.textSecond())
              .lineHeight(19)
              .width('100%')
          }
          .width('92%')
          .padding(16)
          .backgroundColor(this.cardBg())
          .borderRadius(18)
          .shadow({ radius: 8, color: AppTheme.shadow(this.themeMode), offsetY: 2 })
          .margin({ top: 8, bottom: 12 })

          if (this.groups.length === 0) {
            Row() {
              Text(this.t('groups.empty'))
                .fontSize(14)
                .fontColor(this.textSecond())
            }
            .width('92%')
            .height(62)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.cardBg())
            .borderRadius(16)
          } else {
            Column() {
              ForEach(this.groups, (group: ConnectionGroup, index: number) => {
                this.GroupRow(group, index)
              }, (group: ConnectionGroup) => group.id)
            }
            .width('92%')
            .backgroundColor(this.cardBg())
            .borderRadius(16)
            .clip(true)
          }
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
