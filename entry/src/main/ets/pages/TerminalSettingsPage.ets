import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct TerminalSettingsPage {
  @State fontSizeLabel: string = '中';

  private readonly textPrimary: string = '#111827';
  private readonly textSecond: string = '#7B8491';
  private readonly lineColor: string = '#ECEEF3';

  private toast(message: string): void {
    promptAction.showToast({ message: message, duration: 1800 });
  }

  @Builder
  OptionRow(icon: string, title: string, value: string, color: string, action: () => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        Row() { Text(icon).fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White) }
          .width(36).height(36).justifyContent(FlexAlign.Center).backgroundColor(color).borderRadius(10).margin({ right: 12 })
        Text(title).fontSize(16).fontColor(this.textPrimary).layoutWeight(1)
        Text(value).fontSize(13).fontColor(this.textSecond).margin({ right: 8 })
        Text('›').fontSize(26).fontColor('#94A3B8')
      }
      .width('100%').height(54).padding({ left: 14, right: 14 }).onClick(action)
      if (showDivider) { Divider().color(this.lineColor).margin({ left: 62 }) }
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(34).fontColor(this.textPrimary).width(44).onClick(() => router.back())
        Text('终端设置').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.textPrimary)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(44)
      }
      .width('100%').height(64).padding({ left: 14, right: 14, top: 8 })

      Column() {
        this.OptionRow('T', '字体', 'Monospace', '#0A84FF', () => this.toast('字体选择器接入中'))
        this.OptionRow('◐', '终端主题', '深色', '#6554D9', () => this.toast('当前主题：深色'))
        this.OptionRow('T', '字号', this.fontSizeLabel, '#20B8E6', () => {
          this.fontSizeLabel = this.fontSizeLabel === '中' ? '小' : '中';
        })
        this.OptionRow('⌨', '扩展键盘', 'Ctrl / 方向键', '#FF9F0A', () => this.toast('终端快捷键已在会话页启用'), false)
      }
      .width('92%')
      .backgroundColor(Color.White)
      .borderRadius(18)
      .clip(true)
      .margin({ top: 10 })

      Text('字体、颜色、滚动历史和键盘配置将随终端渲染器继续完善。')
        .fontSize(12).fontColor(this.textSecond).width('88%').margin({ top: 10 })
      Blank()
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F3F7FF')
  }
}
