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

@Entry
@Component
struct ConnectionGroupPage {
  @State groups: ConnectionGroup[] = [];
  @State nextGroupIndex: number = 1;
  @State editingGroupId: string = '';
  @State editingName: string = '';

  private readonly accentColor: string = '#0A84FF';
  private readonly pageBg: string = '#F3F7FF';
  private readonly textPrimary: string = '#111827';
  private readonly textSecond: string = '#8A8F99';
  private readonly lineColor: string = '#ECEEF3';
  private readonly palette: string[] = ['#38BDF8', '#0A84FF', '#35C7D7', '#2EA8E5', '#22C55E', '#F59E0B'];

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
    const group: ConnectionGroup = createConnectionGroup('新分组 ' + index.toString(), this.palette[index % this.palette.length]);
    group.sortOrder = this.groups.length + 1;
    ProfileRepository.saveGroup(group);
    this.nextGroupIndex = index + 1;
    this.reload();
    this.startRename(group);
    this.toast('已新增分组，可直接改名');
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
      this.toast('分组名称不能为空');
      return;
    }
    const updated: ConnectionGroup = this.cloneGroup(group);
    updated.name = name;
    ProfileRepository.saveGroup(updated);
    this.cancelRename();
    this.reload();
    this.toast('已重命名分组');
  }

  private toggleCollapsed(group: ConnectionGroup): void {
    const updated: ConnectionGroup = this.cloneGroup(group);
    updated.collapsed = !updated.collapsed;
    ProfileRepository.saveGroup(updated);
    this.reload();
  }

  private cycleColor(group: ConnectionGroup): void {
    const updated: ConnectionGroup = this.cloneGroup(group);
    const currentIndex: number = this.palette.indexOf(updated.colorTag);
    const nextIndex: number = currentIndex < 0 ? 0 : (currentIndex + 1) % this.palette.length;
    updated.colorTag = this.palette[nextIndex];
    ProfileRepository.saveGroup(updated);
    this.reload();
  }

  private moveGroup(group: ConnectionGroup, direction: number): void {
    const index: number = this.groups.findIndex((item: ConnectionGroup) => item.id === group.id);
    const targetIndex: number = index + direction;
    if (index < 0 || targetIndex < 0 || targetIndex >= this.groups.length) {
      this.toast(direction < 0 ? '已经是第一个分组' : '已经是最后一个分组');
      return;
    }
    const current: ConnectionGroup = this.cloneGroup(this.groups[index]);
    const target: ConnectionGroup = this.cloneGroup(this.groups[targetIndex]);
    const currentOrder: number = current.sortOrder;
    current.sortOrder = target.sortOrder;
    target.sortOrder = currentOrder;
    ProfileRepository.saveGroup(current);
    ProfileRepository.saveGroup(target);
    this.reload();
  }

  private removeGroup(group: ConnectionGroup): void {
    if (group.id === 'group-default') {
      this.toast('默认分组不能删除');
      return;
    }
    const count: number = this.countProfiles(group.id);
    if (count > 0) {
      this.toast('该分组下还有主机，暂不删除');
      return;
    }
    ProfileRepository.removeGroup(group.id);
    this.cancelRename();
    this.reload();
    this.toast('已删除空分组');
  }

  @Builder
  Header() {
    Row() {
      Image($rawfile('ft_back.svg'))
        .width(22)
        .height(22)
        .colorFilter(createIconColorFilter(this.textPrimary))
        .onClick(() => router.back())
      Column({ space: 2 }) {
        Text('连接分组')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
        Text('内存分组管理，后续接入 RDB 持久化')
          .fontSize(12)
          .fontColor(this.textSecond)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
      Text('新建')
        .fontSize(14)
        .fontColor(this.accentColor)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 12, right: 12, top: 7, bottom: 7 })
        .backgroundColor('#EAF3FF')
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
      TextInput({ placeholder: '输入分组名称', text: this.editingName })
        .fontSize(14)
        .fontColor(this.textPrimary)
        .placeholderColor('#94A3B8')
        .height(38)
        .padding({ left: 10, right: 10 })
        .backgroundColor('#F8FAFC')
        .borderRadius(12)
        .onChange((value: string) => {
          this.editingName = value;
        })
      Row() {
        this.MiniButton('保存', this.accentColor, '#EAF3FF', () => this.saveRename(group))
        this.MiniButton('取消', '#64748B', '#F1F5F9', () => this.cancelRename())
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
        .backgroundColor('#F1F5F9')
        .borderRadius(12)
        .margin({ right: 10 })
        .onClick(() => this.cycleColor(group))

        Column({ space: 4 }) {
          Row() {
            Text(group.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.textPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .onClick(() => this.startRename(group))
            if (group.id === 'group-default') {
              Text('默认')
                .fontSize(10)
                .fontColor(this.accentColor)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('#EAF3FF')
                .borderRadius(8)
                .margin({ left: 6 })
            }
          }
          .width('100%')
          Text(this.countProfiles(group.id).toString() + ' 台主机 · ' + (group.collapsed ? '已折叠' : '已展开'))
            .fontSize(12)
            .fontColor(this.textSecond)
          Text('点名称改名，点色块换色')
            .fontSize(11)
            .fontColor('#CBD5E1')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 6 }) {
          Row({ space: 6 }) {
            this.MiniButton('上移', index <= 0 ? '#CBD5E1' : '#64748B', '#F1F5F9', () => this.moveGroup(group, -1))
            this.MiniButton('下移', index >= this.groups.length - 1 ? '#CBD5E1' : '#64748B', '#F1F5F9', () => this.moveGroup(group, 1))
          }
          this.MiniButton(group.collapsed ? '展开' : '折叠', '#64748B', '#F1F5F9', () => this.toggleCollapsed(group))
          this.MiniButton('删除', group.id === 'group-default' ? '#CBD5E1' : '#EF4444', group.id === 'group-default' ? '#F8FAFC' : '#FEF2F2', () => this.removeGroup(group))
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
          .color(this.lineColor)
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
            Text('分组用于承载 Android 版的主机管理能力')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.textPrimary)
              .width('100%')
            Text('当前仅为内存实现，退出应用后会丢失；已支持改名、换色、排序和折叠，仍待接入 RDB 与首页入口。')
              .fontSize(13)
              .fontColor(this.textSecond)
              .lineHeight(19)
              .width('100%')
          }
          .width('92%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(18)
          .shadow({ radius: 8, color: '#0A000000', offsetY: 2 })
          .margin({ top: 8, bottom: 12 })

          if (this.groups.length === 0) {
            Row() {
              Text('暂无分组，点击右上角新建')
                .fontSize(14)
                .fontColor(this.textSecond)
            }
            .width('92%')
            .height(62)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(Color.White)
            .borderRadius(16)
          } else {
            Column() {
              ForEach(this.groups, (group: ConnectionGroup, index: number) => {
                this.GroupRow(group, index)
              }, (group: ConnectionGroup) => group.id)
            }
            .width('92%')
            .backgroundColor(Color.White)
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
    .backgroundColor(this.pageBg)
  }
}
