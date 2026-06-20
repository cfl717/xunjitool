import { PromptTemplate, PromptType } from '../models/AiConversation';

@Component
export struct PromptChip {
  template: PromptTemplate = { type: PromptType.WEEKLY_ANALYSIS, title: '', icon: '', systemPrompt: '' };
  clickCallback?: () => void;

  build() {
    Row() {
      Text(this.template.icon).fontSize(16).margin({ right: 6 })
      Text(this.template.title).fontSize(12).fontColor(Color.White).fontWeight(FontWeight.Medium)
    }.padding({ left: 12, right: 12, top: 8, bottom: 8 })
     .backgroundColor('rgba(108,99,255,0.2)').borderRadius(20)
     .border({ width: 1, color: 'rgba(108,99,255,0.4)' }).margin({ right: 8, bottom: 8 })
     .onClick(() => { if (this.clickCallback) this.clickCallback(); })
  }
}
