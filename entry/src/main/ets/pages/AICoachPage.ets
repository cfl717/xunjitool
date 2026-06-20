import { viewModel, LoadState } from '../viewmodel/TrainingViewModel';
import { ChatMessage, ChatRole, PROMPT_TEMPLATES, PromptTemplate } from '../models/AiConversation';
import { ChatBubble } from '../components/ChatBubble';
import { PromptChip } from '../components/PromptChip';
import { callDeepSeek, buildSystemPrompt, ApiMessage } from '../services/DeepSeekService';

@Component
export struct AICoachPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isWaiting: boolean = false;
  @State showApiKeyDialog: boolean = false;
  @State apiKeyInput: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.apiKeyInput = viewModel.deepSeekConfig.apiKey;
  }

  build() {
    Column() {
      Row() {
        Text('AI 教练').fontSize(22).fontColor(Color.White).fontWeight(FontWeight.Bold)
        Blank()
        Text('⚙️').fontSize(20).onClick(() => { this.showApiKeyDialog = true; })
      }.width('100%').padding({ top: 16, bottom: 8, left: 20, right: 20 })

      Scroll(this.scroller) {
        Column() {
          if (this.messages.length === 0) { this.buildWelcomeSection(); }
          else {
            ForEach(this.messages, (msg: ChatMessage) => { ChatBubble({ message: msg }); }, (msg: ChatMessage) => msg.id);
          }
        }.width('100%').padding({ bottom: 80 })
      }.scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)

      this.buildInputArea()

      if (this.showApiKeyDialog) { this.buildApiKeyDialog(); }
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }

  @Builder
  buildWelcomeSection() {
    Column() {
      Circle().width(64).height(64).fill($r('app.color.primary')).margin({ top: 40, bottom: 16 })
      Text('你好！我是你的AI健身教练').fontSize(18).fontColor(Color.White).fontWeight(FontWeight.Bold).margin({ bottom: 4 })
      Text('我可以帮你分析训练数据、生成计划、识别弱点')
        .fontSize(13).fontColor($r('app.color.text_secondary')).textAlign(TextAlign.Center).margin({ bottom: 24 }).padding({ left: 32, right: 32 })
      Text('快速开始').fontSize(14).fontColor(Color.White).fontWeight(FontWeight.Medium).width('100%').margin({ bottom: 12, left: 20 })

      Column() {
        ForEach(PROMPT_TEMPLATES, (tpl: PromptTemplate) => {
          PromptChip({ template: tpl, clickCallback: () => { this.sendPrompt(tpl); } })
        }, (tpl: PromptTemplate) => tpl.type)
      }.width('100%').padding({ left: 20, right: 20 })
    }.width('100%')
  }

  @Builder
  buildInputArea() {
    Row() {
      TextInput({ placeholder: '输入你的问题...', text: this.inputText })
        .layoutWeight(1).height(44).fontSize(14).placeholderColor($r('app.color.text_secondary'))
        .backgroundColor($r('app.color.card_background')).borderRadius(22).padding({ left: 16 })
        .onChange((v: string) => { this.inputText = v; })
        .onSubmit(() => { this.sendMessage(); })
      Text('➤').fontSize(18).fontColor(Color.White).width(40).height(40).textAlign(TextAlign.Center)
        .backgroundColor(this.inputText.trim() && !this.isWaiting ? $r('app.color.primary') : 'rgba(255,255,255,0.1)')
        .borderRadius(20).margin({ left: 8 })
        .onClick(() => { this.sendMessage(); })
    }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })
     .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildApiKeyDialog() {
    Column() {
      Column() {
        Text('设置 DeepSeek API Key').fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Bold).margin({ bottom: 16 })
        TextInput({ placeholder: '输入你的 API Key', text: this.apiKeyInput })
          .height(44).fontSize(14).backgroundColor($r('app.color.card_background')).borderRadius(10).padding({ left: 12 })
          .type(InputType.Password).onChange((v: string) => { this.apiKeyInput = v; })
        Text('可在 deepseek.com 获取').fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 8, bottom: 16 })
        Row() {
          Button('取消').backgroundColor('rgba(255,255,255,0.1)').borderRadius(20).height(40)
            .onClick(() => { this.showApiKeyDialog = false; })
          Button('保存').backgroundColor($r('app.color.primary')).borderRadius(20).height(40).margin({ left: 12 })
            .onClick(() => { this.saveApiKey(); })
        }
      }.padding(24).backgroundColor($r('app.color.surface')).borderRadius(16).width('85%')
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
     .backgroundColor('rgba(0,0,0,0.6)').onClick(() => { this.showApiKeyDialog = false; })
  }

  async saveApiKey(): Promise<void> {
    if (this.apiKeyInput.trim()) await viewModel.updateApiKey(this.apiKeyInput.trim());
    this.showApiKeyDialog = false;
  }

  async sendPrompt(tpl: PromptTemplate): Promise<void> {
    const ctx = this.buildContext();
    const sysPrompt = buildSystemPrompt(ctx);
    const userMsg: ChatMessage = { id: 'msg_' + Date.now(), role: ChatRole.USER, content: '请执行：' + tpl.systemPrompt, timestamp: Date.now(), isStreaming: false };
    this.messages.push(userMsg);
    this.isWaiting = true;
    try {
      await this.doChat(sysPrompt, userMsg.content);
    } catch (err) {
      this.addErr(err.message || '请求失败');
    }
    this.isWaiting = false;
  }

  async sendMessage(): Promise<void> {
    const text = this.inputText.trim();
    if (!text || this.isWaiting) return;
    this.inputText = '';
    const userMsg: ChatMessage = { id: 'msg_' + Date.now(), role: ChatRole.USER, content: text, timestamp: Date.now(), isStreaming: false };
    this.messages.push(userMsg);
    this.isWaiting = true;
    try {
      const ctx = this.buildContext();
      const sysPrompt = !viewModel.deepSeekConfig.apiKey
        ? '你是AI健身教练。用户尚未设置API Key，提醒用户设置后即可获得个性化训练分析。'
        : buildSystemPrompt(ctx);
      await this.doChat(sysPrompt, text);
    } catch (err) {
      this.addErr(err.message || '请求失败');
    }
    this.isWaiting = false;
  }

  async doChat(sysPrompt: string, userContent: string): Promise<void> {
    const aid = 'msg_' + Date.now() + '_ai';
    const asst: ChatMessage = { id: aid, role: ChatRole.ASSISTANT, content: '', timestamp: Date.now(), isStreaming: true };
    this.messages.push(asst);

    const apiMessages: ApiMessage[] = [{ role: 'system', content: sysPrompt }];
    for (const m of this.messages) {
      if (m.id !== aid && !m.isStreaming) {
        const msg: ApiMessage = { role: m.role === ChatRole.USER ? 'user' : 'assistant', content: m.content };
        apiMessages.push(msg);
      }
    }

    try {
      const result = await callDeepSeek(viewModel.deepSeekConfig, apiMessages);
      this.updateMsg(aid, result, false);
    } catch (err) {
      this.addErr(err.message || '请求失败');
    }
  }

  updateMsg(id: string, content: string, streaming: boolean): void {
    const idx = this.findMsg(id);
    if (idx >= 0) {
      this.messages[idx].content = content;
      this.messages[idx].isStreaming = streaming;
      this.messages = [...this.messages];
    }
  }

  findMsg(id: string): number {
    for (let i = 0; i < this.messages.length; i++) {
      if (this.messages[i].id === id) return i;
    }
    return -1;
  }

  addErr(text: string): void {
    this.messages.push({ id: 'err_' + Date.now(), role: ChatRole.ASSISTANT, content: '⚠️ ' + text, timestamp: Date.now(), isStreaming: false });
  }

  buildContext(): string {
    const records = viewModel.allRecords;
    if (records.length === 0) return '暂无训练数据。';
    const stats = viewModel.dashboardStats;
    let ctx = '总训练次数: ' + stats.totalSessions + '，总训练天数: ' + stats.totalTrainingDays + '\n';
    if (stats.bigThreePRs.length > 0) {
      ctx += '三大项1RM:\n';
      for (const pr of stats.bigThreePRs) ctx += '- ' + pr.exerciseName + ': ' + pr.estimatedOneRm + 'kg\n';
    }
    let count = 0;
    for (const r of records) {
      if (count >= 10) break;
      ctx += '- ' + r.date + ' ' + r.name + '\n';
      count++;
    }
    return ctx;
  }
}
