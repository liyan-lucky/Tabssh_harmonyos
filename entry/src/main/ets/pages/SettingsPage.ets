import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SettingsPage {
  @State autoSave: boolean = true;
  @State autoCompress: boolean = false;

  private readonly accentColor: string = '#0A84FF';
  private readonly pageBg: string = '#F3F7FF';
  private readonly textPrimary: string = '#111827';
  private readonly textSecond: string = '#7B8491';
  private readonly lineColor: string = '#ECEEF3';

  private toast(message: string): void {
    promptAction.showToast({ message: message, duration: 1800 });
  }

  @Builder
  Header() {
    Row() {
      Text('‹')
        .fontSize(34)
        .fontColor(this.textPrimary)
        .width(44)
        .onClick(() => router.back())
      Text('系统设置')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Blank().width(44)
    }
    .width('100%')
    .height(64)
    .padding({ left: 14, right: 14, top: 8 })
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor('#64748B')
      .width('92%')
      .margin({ top: 16, bottom: 8 })
  }

  @Builder
  ValueRow(icon: string, title: string, value: string, color: string, action: () => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        Row() {
          Text(icon)
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(color)
        .borderRadius(10)
        .margin({ right: 12 })
        Column({ space: 1 }) {
          Text(title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary)
          if (value.length > 0) {
            Text(value)
              .fontSize(12)
              .fontColor(this.textSecond)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text('›')
          .fontSize(26)
          .fontColor('#94A3B8')
      }
      .width('100%')
      .height(58)
      .padding({ left: 14, right: 14 })
      .onClick(action)
      if (showDivider) {
        Divider().color(this.lineColor).margin({ left: 62 })
      }
    }
  }

  @Builder
  ToggleRow(icon: string, title: string, enabled: boolean, color: string, action: (value: boolean) => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        Row() {
          Text(icon)
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(color)
        .borderRadius(10)
        .margin({ right: 12 })
        Column({ space: 1 }) {
          Text(title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary)
          Text(enabled ? '已开启' : '已关闭')
            .fontSize(12)
            .fontColor(this.textSecond)
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
        Divider().color(this.lineColor).margin({ left: 62 })
      }
    }
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          Column() {
            this.ValueRow('◎', '语言', '简体中文', '#1598E8', () => this.toast('当前使用简体中文'))
            this.ValueRow('◐', '主题', '浅色', '#20B8E6', () => this.toast('深色主题尚在适配'))
            this.ValueRow('T', '字体大小', '中', '#7356E8', () => this.toast('当前字体大小：中'), false)
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(18)
          .clip(true)
          .margin({ top: 8 })

          this.SectionTitle('文件管理')
          Column() {
            this.ToggleRow('⇩', '自动保存', this.autoSave, '#6554D9',
              (value: boolean) => this.autoSave = value)
            this.ToggleRow('⇵', '自动压缩', this.autoCompress, '#FF9F0A',
              (value: boolean) => this.autoCompress = value)
            this.ValueRow('▣', '最大文件限制', '100 MB', '#0A84FF',
              () => this.toast('最大文件限制：100 MB'), false)
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(18)
          .clip(true)

          Text('自动保存接收的文件到下载目录（SFTP 写入能力完成后启用）')
            .fontSize(12)
            .fontColor(this.textSecond)
            .width('88%')
            .margin({ top: 8 })

          this.SectionTitle('存储与缓存')
          Column() {
            this.ValueRow('⌫', '清除缓存', '清除临时文件和缩略图', '#FF2965',
              () => this.toast('尚无可清理的应用缓存'))
            this.ValueRow('≣', '存储空间', '查看应用占用情况', '#32B4DE',
              () => this.toast('系统存储详情入口接入中'), false)
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(18)
          .clip(true)
          .margin({ bottom: 24 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageBg)
  }
}
