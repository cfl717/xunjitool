import { ChatMessageModel, ChatRole } from '../models/AiConversation';
import { MarkdownContent } from './MarkdownContent';

@Component
export struct ChatBubble {
  @ObjectLink message: ChatMessageModel;
  onEditRequest?: (content: string) => void;
  @State showReasoning: boolean = false;

  build() {
    Row() {
      if (this.message.role === ChatRole.USER) {
        Blank()
        this.buildBubble(true)
      } else {
        Text('AI').fontSize(11).fontColor(Color.White).fontWeight(FontWeight.Bold).width(32).height(32).textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.primary')).borderRadius(16).margin({ right: 8 }).flexShrink(0)
        this.buildBubble(false)
      }
    }.width('100%').alignItems(VerticalAlign.Top).padding({ top: 6, bottom: 6, left: 12, right: 12 })
  }

  @Builder
  buildBubble(isUser: boolean) {
    Column() {
      if (this.message.reasoningContent.length > 0) {
        Row() {
          Text('🤔 思考过程').fontSize(11).fontColor($r('app.color.accent_orange'))
          Text(this.showReasoning ? '▾ 收起' : '▸ 展开').fontSize(10).fontColor($r('app.color.text_secondary')).margin({ left: 6 })
        }.onClick(() => { this.showReasoning = !this.showReasoning; }).margin({ bottom: 4 })
        if (this.showReasoning) {
          Text(this.message.reasoningContent).fontSize(12).fontColor($r('app.color.accent_orange')).lineHeight(18)
            .opacity(0.8).margin({ bottom: 8 })
            .width('100%').wordBreak(WordBreak.BREAK_WORD)
        }
      }

      if (this.message.role === ChatRole.ASSISTANT) {
        MarkdownContent({ content: this.message.content })
          .width('100%')
      } else {
        Text(this.message.content).fontSize(14).fontColor(Color.White).lineHeight(20)
          .textAlign(TextAlign.End).width('100%').wordBreak(WordBreak.BREAK_WORD)
          .onClick(() => {
            if (this.onEditRequest) {
              this.onEditRequest(this.message.content);
            }
          })
      }
      if (this.message.role === ChatRole.USER) {
        Text('点击编辑').fontSize(9).fontColor('rgba(255,255,255,0.3)').margin({ top: 2 })
      }
      if (this.message.isStreaming) {
        if (this.message.content.length > 0 || this.message.reasoningContent.length > 0) {
          Text('▍').fontSize(14).fontColor($r('app.color.primary')).margin({ top: 2 })
        } else {
          LoadingProgress().width(16).height(16).color($r('app.color.primary')).margin({ top: 4 })
        }
      }
    }.padding(14).width('100%')
     .backgroundColor(isUser ? $r('app.color.primary') : $r('app.color.card_background'))
     .borderRadius({
       topLeft: isUser ? 16 : 4,
       topRight: isUser ? 4 : 16,
       bottomLeft: 16, bottomRight: 16
     })
     .alignItems(isUser ? HorizontalAlign.End : HorizontalAlign.Start)
     .clip(true)
     .constraintSize(isUser ? { maxWidth: '80%' } : { maxWidth: '100%' })
     .layoutWeight(isUser ? 0 : 1)
  }
}
