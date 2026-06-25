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

  private readonly accentColor: string = '#0A84FF';
  private readonly pageBg: string = '#F3F7FF';
  private readonly textPrimary: string = '#111827';
  private readonly textSecond: string = '#8A8F99';
  private readonly lineColor: string = '#ECEEF3';

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

  private countProfiles(groupId: string): number {
    const filter: ProfileFilter = createDefaultProfileFilter();
    filter.groupId = groupId;
    return ProfileRepository.listFiltered(filter).length;
  }

  private addGroup(): void {
    const colors: string[] = ['#38BDF8', '#0A84FF', '#35C7D7', '#2EA8E5'];
    const index: number = this.nextGroupIndex;
    const group: ConnectionGroup = createConnectionGroup('新分组 ' + index.toString(), colors[index % colors.length]);
    group.sortOrder = this.groups.length + 1;
    ProfileRepository.saveGroup(group);
    this.nextGroupIndex = index + 1;
    this.reload();
    this.toast('已新增分组');
  }

  private toggleCollapsed(group: ConnectionGroup): void {
    const updated: ConnectionGroup = JSON.parse(JSON.stringify(group)) as ConnectionGroup;
    updated.collapsed = !updated.collapsed;
    ProfileRepository.saveGroup(updated);
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

        Column({ space: 4 }) {
          Row() {
            Text(group.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.textPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
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
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 6 }) {
          Text(group.collapsed ? '展开' : '折叠')
            .fontSize(12)
            .fontColor('#64748B')
            .padding({ left: 9, right: 9, top: 5, bottom: 5 })
            .backgroundColor('#F1F5F9')
            .borderRadius(9)
            .onClick(() => this.toggleCollapsed(group))
          Text('删除')
            .fontSize(12)
            .fontColor(group.id === 'group-default' ? '#CBD5E1' : '#EF4444')
            .padding({ left: 9, right: 9, top: 5, bottom: 5 })
            .backgroundColor(group.id === 'group-default' ? '#F8FAFC' : '#FEF2F2')
            .borderRadius(9)
            .onClick(() => this.removeGroup(group))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .height(74)
      .padding({ left: 12, right: 12 })

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
            Text('当前仅为内存实现，退出应用后会丢失；RDB 持久化和主机分组编辑仍待接入。')
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
