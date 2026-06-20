import { ChatMessage, ChatRole } from '../models/AiConversation';

@Component
export struct ChatBubble {
  message: ChatMessage = { id: '', role: ChatRole.ASSISTANT, content: '', timestamp: 0, isStreaming: false };

  build() {
    Row() {
      if (this.message.role === ChatRole.USER) {
        Blank().layoutWeight(0.3)
        this.buildBubble()
      } else {
        Text('AI').fontSize(11).fontColor(Color.White).fontWeight(FontWeight.Bold).width(32).height(32).textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.primary')).borderRadius(16).margin({ right: 8 })
        this.buildBubble()
        Blank().layoutWeight(0.15)
      }
    }.width('100%').alignItems(VerticalAlign.Top).padding({ top: 6, bottom: 6, left: 12, right: 12 })
  }

  @Builder
  buildBubble() {
    Column() {
      Text(this.message.content).fontSize(14).fontColor(Color.White).lineHeight(20)
        .textAlign(this.message.role === ChatRole.USER ? TextAlign.End : TextAlign.Start)
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
  }
}
