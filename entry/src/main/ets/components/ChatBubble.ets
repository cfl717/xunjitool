import { ChatRole } from '../models/AiConversation';
import { MarkdownContent } from './MarkdownContent';

@Component
export struct ChatBubble {
  @Prop content: string = '';
  @Prop role: ChatRole = ChatRole.ASSISTANT;
  @Prop reasoningContent: string = '';
  @Prop isStreaming: boolean = false;
  onEditRequest?: (content: string) => void;
  @State showReasoning: boolean = false;

  build() {
    Row() {
      if (this.role === ChatRole.USER) {
        Blank()
        Column() {
          this.renderContent()
        }.padding(14).width('100%')
         .backgroundColor($r('app.color.primary'))
         .borderRadius({ topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 })
         .alignItems(HorizontalAlign.End)
         .clip(true)
         .constraintSize({ maxWidth: '80%' })
         .onClick(() => {
           if (this.onEditRequest) {
             this.onEditRequest(this.content);
           }
         })
      } else {
        Text('AI').fontSize(11).fontColor(Color.White).fontWeight(FontWeight.Bold).width(32).height(32).textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.primary')).borderRadius(16).margin({ right: 8 }).flexShrink(0)
        Column() {
          this.renderContent()
        }.padding(14).width('100%')
         .backgroundColor($r('app.color.card_background'))
         .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
         .alignItems(HorizontalAlign.Start)
         .clip(true)
         .constraintSize({ maxWidth: '100%' })
         .layoutWeight(1)
      }
    }.width('100%').alignItems(VerticalAlign.Top).padding({ top: 6, bottom: 6, left: 12, right: 12 })
  }

  @Builder
  renderContent() {
    if (this.reasoningContent.length > 0) {
      Row() {
        Text('🤔 思考过程').fontSize(11).fontColor($r('app.color.accent_orange'))
        Text(this.showReasoning ? '▾ 收起' : '▸ 展开').fontSize(10).fontColor($r('app.color.text_secondary')).margin({ left: 6 })
      }.margin({ bottom: 4 })
       .onClick(() => { this.showReasoning = !this.showReasoning; })
      if (this.showReasoning) {
        Text(this.reasoningContent).fontSize(12).fontColor($r('app.color.accent_orange')).lineHeight(18)
          .opacity(0.8).margin({ bottom: 8 })
          .width('100%').wordBreak(WordBreak.BREAK_WORD)
      }
    }

    if (this.role === ChatRole.ASSISTANT) {
      MarkdownContent({ content: this.content }).width('100%')
    } else {
      Text(this.content).fontSize(14).fontColor(Color.White).lineHeight(20)
        .textAlign(TextAlign.End).width('100%').wordBreak(WordBreak.BREAK_WORD)
      Text('点击编辑').fontSize(9).fontColor('rgba(255,255,255,0.3)').margin({ top: 2 })
    }

    if (this.isStreaming) {
      if (this.content.length > 0 || this.reasoningContent.length > 0) {
        Text('▍').fontSize(14).fontColor($r('app.color.primary')).margin({ top: 2 })
      } else {
        LoadingProgress().width(16).height(16).color($r('app.color.primary')).margin({ top: 4 })
      }
    }
  }
}
