/**
 * 聊天气泡组件
 * 展示用户或AI的一条消息
 */

import { ChatMessage, ChatRole } from '../models/AiConversation';

@Component
export struct ChatBubble {
  private message: ChatMessage = {
    id: '', role: ChatRole.ASSISTANT, content: '',
    timestamp: 0, isStreaming: false
  };

  build() {
    Row() {
      if (this.message.role === ChatRole.USER) {
        // 用户消息右对齐
        Blank().layoutWeight(0.3)
        this.buildBubble()
      } else {
        // AI消息左对齐，加头像
        this.buildAvatar()
        this.buildBubble()
        Blank().layoutWeight(0.15)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ vertical: 6, horizontal: 12 })
  }

  @Builder
  buildAvatar() {
    Circle()
      .width(32)
      .height(32)
      .fill($r('app.color.primary'))
      .margin({ right: 8 })
      .overlay({
        shape: Circle(),
        content: Text('AI')
          .fontSize(11)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      })
  }

  @Builder
  buildBubble() {
    Column() {
      Text(this.message.content)
        .fontSize(14)
        .fontColor(Color.White)
        .lineHeight(20)
        .textAlign(this.message.role === ChatRole.USER ? TextAlign.End : TextAlign.Start)
        .wordBreak(WordBreak.BreakWord)

      if (this.message.isStreaming) {
        LoadingProgress()
          .width(16)
          .height(16)
          .color($r('app.color.primary'))
          .margin({ top: 4 })
      }
    }
    .padding(14)
    .backgroundColor(this.message.role === ChatRole.USER
      ? $r('app.color.primary')
      : $r('app.color.card_background'))
    .borderRadius(16)
    .borderRadius(this.message.role === ChatRole.USER
      ? { topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 }
      : { topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
    .alignItems(this.message.role === ChatRole.USER ? HorizontalAlign.End : HorizontalAlign.Start)
  }
}
