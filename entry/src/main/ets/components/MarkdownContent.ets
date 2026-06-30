import { MdBlock, MdBlockType, MdInlineSpan, MdListItem } from '../models/MarkdownTypes';
import { parseMarkdownBlocks } from '../utils/MarkdownParser';

@Component
struct MarkdownInlineText {
  spans: MdInlineSpan[] = [];
  fontSize: number = 14;
  fontColor: ResourceColor = Color.White;
  baseWeight: FontWeight = FontWeight.Normal;
  lineHeight: number = 20;

  build() {
    Text() {
      ForEach(this.spans, (span: MdInlineSpan, idx: number) => {
        Span(span.text)
          .fontSize(span.code ? this.fontSize - 1 : this.fontSize)
          .fontColor(span.code ? $r('app.color.accent_orange') : (span.link ? $r('app.color.primary') : this.fontColor))
          .fontWeight(span.bold || span.code ? FontWeight.Bold : this.baseWeight)
          .fontStyle(span.italic ? FontStyle.Italic : FontStyle.Normal)
          .decoration(span.link ? { type: TextDecorationType.Underline, color: $r('app.color.primary') } : { type: TextDecorationType.None })
          .backgroundColor(span.code ? 'rgba(255,255,255,0.1)' : Color.Transparent)
      }, (span: MdInlineSpan, idx: number) => 'sp_' + idx + '_' + span.text.length)
    }
    .fontColor(this.fontColor)
    .fontSize(this.fontSize)
    .lineHeight(this.lineHeight)
    .wordBreak(WordBreak.BREAK_WORD)
    .width('100%')
    .constraintSize({ maxWidth: '100%' })
  }
}

@Component
struct MarkdownBlockItem {
  block: MdBlock = { type: MdBlockType.PARAGRAPH, level: 0, spans: [], code: '', lang: '', items: [], ordered: false, rows: [], align: [] };

  headingSize(): number {
    if (this.block.level <= 1) return 18;
    if (this.block.level === 2) return 16;
    if (this.block.level === 3) return 15;
    return 14;
  }

  getTableAlign(ci: number): TextAlign {
    if (ci < this.block.align.length) {
      const a = this.block.align[ci];
      if (a === 'center') return TextAlign.Center;
      if (a === 'right') return TextAlign.End;
    }
    return TextAlign.Start;
  }

  build() {
    Column() {
      if (this.block.type === MdBlockType.HEADING) {
        MarkdownInlineText({
          spans: this.block.spans,
          fontSize: this.headingSize(),
          fontColor: Color.White,
          baseWeight: FontWeight.Bold,
          lineHeight: this.headingSize() + 6
        }).margin({ top: 4, bottom: 2 })
      } else if (this.block.type === MdBlockType.CODE) {
        Column() {
          if (this.block.lang.length > 0) {
            Text(this.block.lang).fontSize(10).fontColor($r('app.color.text_secondary')).margin({ bottom: 4 })
          }
          Text(this.block.code)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .lineHeight(18)
            .wordBreak(WordBreak.BREAK_ALL)
            .width('100%')
        }
        .width('100%')
        .padding(10)
        .backgroundColor('rgba(0,0,0,0.28)')
        .borderRadius(8)
        .margin({ top: 2, bottom: 2 })
      } else if (this.block.type === MdBlockType.LIST) {
        Column({ space: 4 }) {
          ForEach(this.block.items, (item: MdListItem, idx: number) => {
            Row() {
              Text(this.block.ordered ? (idx + 1) + '.' : '•')
                .fontSize(14)
                .fontColor($r('app.color.primary'))
                .width(this.block.ordered ? 22 : 14)
                .margin({ right: 4 })
                .flexShrink(0)
              MarkdownInlineText({
                spans: item.spans,
                fontSize: 14,
                fontColor: Color.White,
                lineHeight: 20
              }).layoutWeight(1).constraintSize({ maxWidth: '100%' })
            }
            .alignItems(VerticalAlign.Top)
            .width('100%')
          }, (item: MdListItem, idx: number) => 'li_' + idx)
        }.width('100%').margin({ top: 2, bottom: 2 })
      } else if (this.block.type === MdBlockType.QUOTE) {
        Column() {
          MarkdownInlineText({
            spans: this.block.spans,
            fontSize: 13,
            fontColor: $r('app.color.text_secondary'),
            lineHeight: 19
          })
        }
        .width('100%')
        .padding({ left: 10, top: 2, bottom: 2 })
        .border({ width: { left: 3 }, color: $r('app.color.primary') })
        .margin({ top: 2, bottom: 2 })
      } else if (this.block.type === MdBlockType.HR) {
        Divider().color('rgba(255,255,255,0.15)').strokeWidth(1).margin({ top: 6, bottom: 6 })
      } else if (this.block.type === MdBlockType.TABLE) {
        Scroll() {
          Column() {
            ForEach(this.block.rows, (row: string[], ri: number) => {
              Row() {
                ForEach(row, (cell: string, ci: number) => {
                  Text(cell).fontSize(12).fontColor(ri === 0 ? Color.White : $r('app.color.text_secondary'))
                    .fontWeight(ri === 0 ? FontWeight.Bold : FontWeight.Regular)
                    .width(72).lineHeight(18).padding({ left: 6, right: 6, top: 4, bottom: 4 })
                    .wordBreak(WordBreak.BREAK_WORD)
                    .textAlign(this.getTableAlign(ci))
                }, (cell: string, ci: number) => 'c' + ci)
              }.width('100%').backgroundColor(ri === 0 ? 'rgba(108,99,255,0.15)' : (ri % 2 === 0 ? 'rgba(255,255,255,0.04)' : 'transparent'))
            }, (row: string[], ri: number) => 'r' + ri)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .borderRadius(8)
        .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
        .margin({ top: 4, bottom: 4 })
      } else {
        MarkdownInlineText({
          spans: this.block.spans,
          fontSize: 14,
          fontColor: Color.White,
          lineHeight: 20
        }).margin({ top: 1, bottom: 1 })
      }
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
}

@Component
export struct MarkdownContent {
  @Prop @Watch('onContentChange') content: string = '';
  @State blocks: MdBlock[] = [];

  onContentChange(): void {
    this.blocks = parseMarkdownBlocks(this.content);
  }

  aboutToAppear(): void {
    this.onContentChange();
  }

  build() {
    Column({ space: 6 }) {
      ForEach(this.blocks, (block: MdBlock, idx: number) => {
        MarkdownBlockItem({ block: block })
      }, (block: MdBlock, idx: number) => 'md_' + idx + '_' + block.type + '_' + this.content.length)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .constraintSize({ maxWidth: '100%' })
    .clip(true)
  }
}
