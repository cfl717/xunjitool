/**
 * AI 教练对话页
 * DeepSeek 流式对话 + 预设 Prompt
 */

import { viewModel, LoadState } from '../viewmodel/TrainingViewModel';
import { ChatMessage, ChatRole, PROMPT_TEMPLATES, PromptTemplate, PromptType } from '../models/AiConversation';
import { ChatBubble } from '../components/ChatBubble';
import { PromptChip } from '../components/PromptChip';
import { callDeepSeekStream, buildSystemPrompt, buildTrainingContext } from '../services/DeepSeekService';

@Component
export struct AICoachPage {
  @State loadState: LoadState = viewModel.loadState;
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isWaiting: boolean = false;
  @State showApiKeyDialog: boolean = false;
  @State apiKeyInput: string = '';

  private scrollController: Scroller = new Scroller();

  aboutToAppear(): void {
    this.loadState = viewModel.loadState;
    this.apiKeyInput = viewModel.deepSeekConfig.apiKey;
  }

  build() {
    Column() {
      // 页面标题
      Row() {
        Text('AI 教练')
          .fontSize(22)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)

        Blank()

        // 设置按钮
        Text('⚙️')
          .fontSize(20)
          .onClick(() => {
            this.showApiKeyDialog = true;
          })
      }
      .width('100%')
      .padding({ top: 16, bottom: 8, left: 20, right: 20 })

      if (this.loadState === LoadState.LOADING || this.loadState === LoadState.EMPTY) {
        // 聊天界面（即使无数据也可以对话，只是上下文为空）
      }

      // 聊天消息列表
      Scroll(this.scrollController) {
        Column() {
          if (this.messages.length === 0) {
            // 欢迎消息
            this.buildWelcomeSection()
          } else {
            ForEach(this.messages, (msg: ChatMessage) => {
              ChatBubble({ message: msg })
            }, (msg: ChatMessage) => msg.id)
          }

          // 输入加载指示器
          if (this.isWaiting) {
            ChatBubble({
              message: {
                id: 'waiting',
                role: ChatRole.ASSISTANT,
                content: '',
                timestamp: Date.now(),
                isStreaming: true
              }
            })
          }
        }
        .width('100%')
        .padding({ bottom: 80 })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      // 输入区域
      this.buildInputArea()

      // API Key 设置弹窗
      if (this.showApiKeyDialog) {
        this.buildApiKeyDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildWelcomeSection() {
    Column() {
      // AI 头像
      Circle()
        .width(64)
        .height(64)
        .fill($r('app.color.primary'))
        .margin({ top: 40, bottom: 16 })
        .overlay({
          shape: Circle(),
          content: Text('🤖')
            .fontSize(32)
        })

      Text('你好！我是你的AI健身教练')
        .fontSize(18)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 4 })

      Text('我可以帮你分析训练数据、生成计划、识别弱点')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })
        .padding({ horizontal: 32 })

      // 预设Prompt
      Text('快速开始')
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12, left: 20 })

      Wrap() {
        ForEach(PROMPT_TEMPLATES, (template: PromptTemplate) => {
          PromptChip({
            template: template,
            onClick: () => {
              this.sendPrompt(template);
            }
          })
        }, (template: PromptTemplate) => template.type)
      }
      .width('100%')
      .padding({ horizontal: 20 })
    }
    .width('100%')
  }

  @Builder
  buildInputArea() {
    Row() {
      // 输入框
      TextInput({ placeholder: '输入你的问题...', text: this.inputText })
        .layoutWeight(1)
        .height(44)
        .fontSize(14)
        .placeholderColor($r('app.color.text_secondary'))
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(22)
        .padding({ left: 16 })
        .onChange((value: string) => {
          this.inputText = value;
        })
        .onSubmit(() => {
          this.sendMessage();
        })

      // 发送按钮
      Circle()
        .width(40)
        .height(40)
        .fill(this.inputText.trim() && !this.isWaiting
          ? $r('app.color.primary')
          : 'rgba(255,255,255,0.1)')
        .margin({ left: 8 })
        .overlay({
          shape: Circle(),
          content: Text('➤')
            .fontSize(18)
            .fontColor(Color.White)
        })
        .onClick(() => {
          this.sendMessage();
        })
    }
    .width('100%')
    .padding({ horizontal: 16, vertical: 12 })
    .backgroundColor($r('app.color.background'))
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.3)', offsetY: -4 })
  }

  @Builder
  buildApiKeyDialog() {
    Column() {
      Column() {
        Text('设置 DeepSeek API Key')
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        TextInput({ placeholder: '输入你的 API Key', text: this.apiKeyInput })
          .height(44)
          .fontSize(14)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(10)
          .padding({ left: 12 })
          .type(InputType.Password)
          .onChange((value: string) => {
            this.apiKeyInput = value;
          })

        Text('可在 deepseek.com 获取 API Key')
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 8, bottom: 16 })

        Row() {
          Button('取消')
            .backgroundColor('rgba(255,255,255,0.1)')
            .borderRadius(20)
            .height(40)
            .onClick(() => {
              this.showApiKeyDialog = false;
            })

          Button('保存')
            .backgroundColor($r('app.color.primary'))
            .borderRadius(20)
            .height(40)
            .margin({ left: 12 })
            .onClick(() => {
              this.saveApiKey();
            })
        }
      }
      .padding(24)
      .backgroundColor($r('app.color.surface'))
      .borderRadius(16)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0,0,0,0.6)')
    .onClick(() => {
      this.showApiKeyDialog = false;
    })
  }

  async saveApiKey(): Promise<void> {
    if (this.apiKeyInput.trim()) {
      await viewModel.updateApiKey(this.apiKeyInput.trim());
    }
    this.showApiKeyDialog = false;
  }

  /** 发送预设Prompt */
  async sendPrompt(template: PromptTemplate): Promise<void> {
    const trainingContext = this.buildContext();
    const systemPrompt = buildSystemPrompt(trainingContext);

    const userMsg: ChatMessage = {
      id: `msg_${Date.now()}`,
      role: ChatRole.USER,
      content: `请执行：${template.systemPrompt}`,
      timestamp: Date.now(),
      isStreaming: false
    };

    this.messages.push(userMsg);
    this.isWaiting = true;

    try {
      await this.doStreamChat(systemPrompt, userMsg.content);
    } catch (err: any) {
      this.addErrorMessage(err.message || '请求失败');
    }

    this.isWaiting = false;
  }

  /** 发送用户输入消息 */
  async sendMessage(): Promise<void> {
    const text = this.inputText.trim();
    if (!text || this.isWaiting) return;

    this.inputText = '';

    const userMsg: ChatMessage = {
      id: `msg_${Date.now()}`,
      role: ChatRole.USER,
      content: text,
      timestamp: Date.now(),
      isStreaming: false
    };

    this.messages.push(userMsg);
    this.isWaiting = true;

    try {
      const trainingContext = this.buildContext();
      const systemPrompt = !viewModel.deepSeekConfig.apiKey
        ? '你是AI健身教练。请友好地回应用户的问题。注意：用户尚未设置API Key，提醒用户设置后即可获得个性化训练分析。'
        : buildSystemPrompt(trainingContext);

      await this.doStreamChat(systemPrompt, text);
    } catch (err: any) {
      this.addErrorMessage(err.message || '请求失败');
    }

    this.isWaiting = false;
  }

  /** 执行流式对话 */
  async doStreamChat(systemPrompt: string, userContent: string): Promise<void> {
    const assistantId = `msg_${Date.now()}_ai`;

    const assistantMsg: ChatMessage = {
      id: assistantId,
      role: ChatRole.ASSISTANT,
      content: '',
      timestamp: Date.now(),
      isStreaming: true
    };
    this.messages.push(assistantMsg);

    const apiMessages = [
      { role: 'system', content: systemPrompt },
      ...this.messages
        .filter(m => m.id !== assistantId && !m.isStreaming)
        .map(m => ({ role: m.role === ChatRole.USER ? 'user' : 'assistant', content: m.content }))
    ];

    let fullContent = '';

    try {
      const generator = callDeepSeekStream(viewModel.deepSeekConfig, apiMessages);
      for await (const chunk of generator) {
        fullContent += chunk;
        this.updateMessage(assistantId, fullContent, true);
      }
      this.updateMessage(assistantId, fullContent, false);
    } catch (err: any) {
      // 如果流式失败，尝试非流式
      if (!fullContent) {
        throw err;
      }
      this.updateMessage(assistantId, fullContent + '\n\n[响应被截断]', false);
    }
  }

  /** 更新消息内容 */
  updateMessage(id: string, content: string, streaming: boolean): void {
    const index = this.messages.findIndex(m => m.id === id);
    if (index >= 0) {
      this.messages[index].content = content;
      this.messages[index].isStreaming = streaming;

      // 触发刷新
      this.messages = [...this.messages];

      // 滚动到底部
      setTimeout(() => {
        this.scrollController.scrollEdge(Edge.Bottom);
      }, 50);
    }
  }

  /** 添加错误消息 */
  addErrorMessage(errorText: string): void {
    const errMsg: ChatMessage = {
      id: `err_${Date.now()}`,
      role: ChatRole.ASSISTANT,
      content: `⚠️ ${errorText}`,
      timestamp: Date.now(),
      isStreaming: false
    };
    this.messages.push(errMsg);
  }

  /** 构建训练上下文 */
  buildContext(): string {
    const records = viewModel.allRecords;
    if (records.length === 0) return '暂无训练数据。';

    const stats = viewModel.dashboardStats;

    const recentSessions = records
      .filter(r => r.type === 'strength')
      .slice(0, 10)
      .map(r => ({
        date: r.date,
        name: r.name,
        exercises: (r.exercises || []).map(e => `${e.name}(${e.totalSets}组)`).join(', ')
      }));

    return buildTrainingContext({
      totalSessions: stats.totalSessions,
      totalDays: stats.totalTrainingDays,
      recentSessions,
      bigThreePRs: stats.bigThreePRs.map(p => ({
        name: p.exerciseName,
        oneRm: p.estimatedOneRm
      }))
    });
  }
}
