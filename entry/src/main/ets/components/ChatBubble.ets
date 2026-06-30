import { ChatMessage, ChatRole } from '../models/AiConversation';

@Component
export struct ChatBubble {
  message: ChatMessage = { id: '', role: ChatRole.ASSISTANT, content: '', timestamp: 0, isStreaming: false };
  onEditRequest?: (content: string) => void;
  @State showReasoning: boolean = false;

  build() {
    Row() {
      if (this.message.role === ChatRole.USER) {
        Blank()
        this.buildBubble()
      } else {
        Text('AI').fontSize(11).fontColor(Color.White).fontWeight(FontWeight.Bold).width(32).height(32).textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.primary')).borderRadius(16).margin({ right: 8 })
        this.buildBubble()
      }
    }.width('100%').alignItems(VerticalAlign.Top).padding({ top: 6, bottom: 6, left: 12, right: 12 })
  }

  @Builder
  buildBubble() {
    Column() {
      // 思考过程（可折叠）
      if (this.message.reasoningContent) {
        Row() {
          Text('🤔 思考过程').fontSize(11).fontColor($r('app.color.accent_orange'))
          Text(this.showReasoning ? '▾ 收起' : '▸ 展开').fontSize(10).fontColor($r('app.color.text_secondary')).margin({ left: 6 })
        }.onClick(() => { this.showReasoning = !this.showReasoning; }).margin({ bottom: 4 })
        if (this.showReasoning) {
          Text(this.message.reasoningContent).fontSize(12).fontColor($r('app.color.accent_orange')).lineHeight(18)
            .opacity(0.8).margin({ bottom: 8 })
        }
      }

      Text(this.message.content).fontSize(14).fontColor(Color.White).lineHeight(20)
        .textAlign(this.message.role === ChatRole.USER ? TextAlign.End : TextAlign.Start)
        .onClick(() => {
          if (this.message.role === ChatRole.USER && this.onEditRequest) {
            this.onEditRequest(this.message.content);
          }
        })
      if (this.message.role === ChatRole.USER) {
        Text('点击编辑').fontSize(9).fontColor('rgba(255,255,255,0.3)').margin({ top: 2 })
      }
      if (this.message.isStreaming) {
        LoadingProgress().width(16).height(16).color($r('app.color.primary')).margin({ top: 4 })
      }
    }.padding(14)
     .backgroundColor(this.message.role === ChatRole.USER ? $r('app.color.primary') : $r('app.color.card_background'))
     .borderRadius({
       topLeft: this.message.role === ChatRole.USER ? 16 : 4,
       topRight: this.message.role === ChatRole.USER ? 4 : 16,
       bottomLeft: 16, bottomRight: 16
     })
     .alignItems(this.message.role === ChatRole.USER ? HorizontalAlign.End : HorizontalAlign.Start)
     .constraintSize({ maxWidth: '80%' })
  }
}
