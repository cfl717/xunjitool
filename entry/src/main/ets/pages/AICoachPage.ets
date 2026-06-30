import { viewModel, LoadState } from '../viewmodel/TrainingViewModel';
import { ChatMessage, ChatRole, PROMPT_TEMPLATES, PromptTemplate } from '../models/AiConversation';
import { ChatBubble } from '../components/ChatBubble';
import { PromptChip } from '../components/PromptChip';
import { callDeepSeek, callDeepSeekStream, buildSystemPrompt, ApiMessage, ApiResult } from '../services/DeepSeekService';
import { Storage } from '../services/PreferencesStorage';
import { DEEPSEEK_MODELS, ModelOption } from '../utils/Constants';
import { saveString } from '../services/PreferencesStorage';

@Component
export struct AICoachPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isWaiting: boolean = false;
  @State showApiKeyDialog: boolean = false;
  @State showModelDialog: boolean = false;
  @State apiKeyInput: string = '';
  @State selectedModel: number = 0;
  private scroller: Scroller = new Scroller();
  private isLoaded: boolean = false;

  aboutToAppear(): void {
    this.apiKeyInput = viewModel.deepSeekConfig.apiKey;
    this.loadMessages();
    this.syncModelIndex();
  }

  syncModelIndex(): void {
    for (let i = 0; i < DEEPSEEK_MODELS.length; i++) {
      if (DEEPSEEK_MODELS[i].name === viewModel.deepSeekConfig.model) {
        this.selectedModel = i;
        return;
      }
    }
  }

  selectModel(idx: number): void {
    this.selectedModel = idx;
    viewModel.deepSeekConfig.model = DEEPSEEK_MODELS[idx].name;
    saveString('deepseek_model', viewModel.deepSeekConfig.model);
  }

  async loadMessages(): Promise<void> {
    if (this.isLoaded) return;
    this.isLoaded = true;
    try {
      const saved = await Storage.getChatMessages();
      if (saved.length > 0) {
        this.messages = saved as ChatMessage[];
      }
    } catch (e) {
      console.error('Failed to load chat history: ' + JSON.stringify(e));
    }
  }

  async saveMessages(): Promise<void> {
    try {
      await Storage.saveChatMessages(this.messages);
    } catch (e) {
      console.error('Failed to save chat history: ' + JSON.stringify(e));
    }
  }

  clearHistory(): void {
    this.messages = [];
    Storage.saveChatMessages([]);
  }

  build() {
    Column() {
      Row() {
        Text('AI 教练').fontSize(22).fontColor(Color.White).fontWeight(FontWeight.Bold)
        Blank()
        if (this.messages.length > 0) {
          Text('🗑️').fontSize(18).margin({ right: 12 }).onClick(() => { this.clearHistory(); })
        }
        Text('🧠').fontSize(16).margin({ right: 12 }).onClick(() => { this.showModelDialog = true; })
        Text('⚙️').fontSize(20).onClick(() => { this.showApiKeyDialog = true; })
      }.width('100%').padding({ top: 16, bottom: 8, left: 20, right: 20 })

      Scroll(this.scroller) {
        Column() {
          if (this.messages.length === 0) { this.buildWelcomeSection(); }
          else {
            ForEach(this.messages, (msg: ChatMessage) => {
              ChatBubble({
                message: msg,
                onEditRequest: (content: string) => {
                  this.inputText = content;
                }
              });
            }, (msg: ChatMessage) => msg.id);
          }
        }.width('100%').padding({ bottom: 80 })
      }.scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)

      this.buildInputArea()

      if (this.showApiKeyDialog) { this.buildApiKeyDialog(); }
      if (this.showModelDialog) { this.buildModelDialog(); }
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

  @Builder
  buildModelDialog() {
    Column() {
      Column() {
        Text('选择模型').fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Bold).margin({ bottom: 16 })
        ForEach(DEEPSEEK_MODELS, (m: ModelOption, i: number) => {
          Row() {
            Column() {
              Text(m.label).fontSize(14).fontColor(Color.White)
              Text(m.supportsReasoning ? '支持思考模式（更深度分析）' : '快速响应').fontSize(10).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Text(this.selectedModel === i ? '✓' : '○').fontSize(16).fontColor(this.selectedModel === i ? $r('app.color.primary') : $r('app.color.text_secondary'))
          }.width('100%').padding(12).backgroundColor(this.selectedModel === i ? 'rgba(108,99,255,0.15)' : $r('app.color.card_background')).borderRadius(10).margin({ bottom: 8 })
           .onClick(() => { this.selectModel(i); this.showModelDialog = false; })
        }, (m: ModelOption, i: number) => m.name)
        Button('关闭').fontSize(14).fontColor($r('app.color.text_secondary')).backgroundColor('rgba(255,255,255,0.08)')
          .width('100%').height(40).borderRadius(20).margin({ top: 8 })
          .onClick(() => { this.showModelDialog = false; })
      }.padding(24).backgroundColor($r('app.color.surface')).borderRadius(16).width('85%')
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
     .backgroundColor('rgba(0,0,0,0.6)').onClick(() => { this.showModelDialog = false; })
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
    this.saveMessages();
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
    this.saveMessages();
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
    this.saveMessages();

    const apiMessages: ApiMessage[] = [{ role: 'system', content: sysPrompt }];
    for (const m of this.messages) {
      if (m.id !== aid && !m.isStreaming) {
        const msg: ApiMessage = { role: m.role === ChatRole.USER ? 'user' : 'assistant', content: m.content };
        apiMessages.push(msg);
      }
    }

    try {
      const result: ApiResult = await callDeepSeekStream(viewModel.deepSeekConfig, apiMessages, (chunk: string) => {
        // non-streaming: 一次性回调，直接显示完整内容
      });
      const idx = this.findMsg(aid);
      if (idx >= 0) {
        this.messages[idx].content = result.content;
        this.messages[idx].reasoningContent = result.reasoningContent;
        this.messages[idx].isStreaming = false;
        this.messages = [...this.messages];
        this.saveMessages();
      }
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
      this.saveMessages();
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
    this.saveMessages();
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
