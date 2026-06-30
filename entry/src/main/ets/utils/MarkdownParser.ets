import { MdBlock, MdBlockType, MdInlineSpan, MdListItem, emptyMdBlock } from '../models/MarkdownTypes';

interface HeadingInfo {
  level: number;
  title: string;
}

function pushSpan(spans: MdInlineSpan[], text: string, bold: boolean, italic: boolean, code: boolean, link: boolean): void {
  if (text.length === 0) {
    return;
  }
  const span: MdInlineSpan = { text: text, bold: bold, italic: italic, code: code, link: link };
  spans.push(span);
}

function parseHeadingLine(line: string): HeadingInfo | null {
  if (line.length < 2 || line.charAt(0) !== '#') {
    return null;
  }
  let level = 0;
  let j = 0;
  while (j < line.length && j < 6 && line.charAt(j) === '#') {
    level++;
    j++;
  }
  if (level === 0 || j >= line.length || line.charAt(j) !== ' ') {
    return null;
  }
  const title = line.substring(j + 1).trim();
  if (title.length === 0) {
    return null;
  }
  const info: HeadingInfo = { level: level, title: title };
  return info;
}

function isHrLine(line: string): boolean {
  const t = line.trim();
  if (t.length < 3) {
    return false;
  }
  const ch = t.charAt(0);
  if (ch !== '-' && ch !== '*' && ch !== '_') {
    return false;
  }
  for (let i = 1; i < t.length; i++) {
    if (t.charAt(i) !== ch && t.charAt(i) !== ' ') {
      return false;
    }
  }
  return true;
}

function isUnorderedItem(line: string): boolean {
  if (line.length < 2) {
    return false;
  }
  const ch = line.charAt(0);
  if (ch !== '-' && ch !== '*' && ch !== '+') {
    return false;
  }
  return line.charAt(1) === ' ';
}

function unorderedItemText(line: string): string {
  return line.substring(2);
}

function isOrderedItem(line: string): boolean {
  let i = 0;
  while (i < line.length && line.charAt(i) >= '0' && line.charAt(i) <= '9') {
    i++;
  }
  if (i === 0) {
    return false;
  }
  return i + 1 < line.length && line.charAt(i) === '.' && line.charAt(i + 1) === ' ';
}

function orderedItemText(line: string): string {
  let i = 0;
  while (i < line.length && line.charAt(i) >= '0' && line.charAt(i) <= '9') {
    i++;
  }
  return line.substring(i + 2);
}

function isSpecialLine(line: string): boolean {
  if (line.startsWith('```')) {
    return true;
  }
  if (parseHeadingLine(line) !== null) {
    return true;
  }
  if (isHrLine(line)) {
    return true;
  }
  if (line.startsWith('> ')) {
    return true;
  }
  if (isUnorderedItem(line)) {
    return true;
  }
  if (isOrderedItem(line)) {
    return true;
  }
  if (line.startsWith('|')) {
    return true;
  }
  return false;
}

function isTableSeparator(line: string): boolean {
  const trimmed = line.trim();
  if (!trimmed.startsWith('|')) return false;
  const cells = trimmed.split('|');
  for (const cell of cells) {
    const t = cell.trim();
    if (t.length === 0) continue;
    for (let j = 0; j < t.length; j++) {
      const ch = t.charAt(j);
      if (ch !== '-' && ch !== ':' && ch !== ' ') return false;
    }
  }
  return true;
}

function matchAt(text: string, pos: number, marker: string): boolean {
  if (pos + marker.length > text.length) {
    return false;
  }
  return text.substring(pos, pos + marker.length) === marker;
}

/** 解析行内 Markdown：粗体、斜体、行内代码、链接 */
export function parseInline(text: string): MdInlineSpan[] {
  const out: MdInlineSpan[] = [];
  let plain = '';
  let i = 0;

  const emitPlain = (): void => {
    if (plain.length > 0) {
      pushSpan(out, plain, false, false, false, false);
      plain = '';
    }
  };

  while (i < text.length) {
    if (text.charAt(i) === '`') {
      const close = text.indexOf('`', i + 1);
      if (close > i) {
        emitPlain();
        pushSpan(out, text.substring(i + 1, close), false, false, true, false);
        i = close + 1;
        continue;
      }
    }

    if (matchAt(text, i, '***') || matchAt(text, i, '___')) {
      const close = text.indexOf(text.substring(i, i + 3), i + 3);
      if (close > i) {
        emitPlain();
        pushSpan(out, text.substring(i + 3, close), true, true, false, false);
        i = close + 3;
        continue;
      }
    }

    if (matchAt(text, i, '**') || matchAt(text, i, '__')) {
      const close = text.indexOf(text.substring(i, i + 2), i + 2);
      if (close > i) {
        emitPlain();
        pushSpan(out, text.substring(i + 2, close), true, false, false, false);
        i = close + 2;
        continue;
      }
    }

    if ((text.charAt(i) === '*' || text.charAt(i) === '_') && !matchAt(text, i, '**')) {
      const ch = text.charAt(i);
      const close = text.indexOf(ch, i + 1);
      if (close > i && text.charAt(i + 1) !== ch) {
        emitPlain();
        pushSpan(out, text.substring(i + 1, close), false, true, false, false);
        i = close + 1;
        continue;
      }
    }

    if (text.charAt(i) === '[') {
      const closeBracket = text.indexOf(']', i + 1);
      if (closeBracket > i && closeBracket + 1 < text.length && text.charAt(closeBracket + 1) === '(') {
        const closeParen = text.indexOf(')', closeBracket + 2);
        if (closeParen > closeBracket) {
          emitPlain();
          pushSpan(out, text.substring(i + 1, closeBracket), false, false, false, true);
          i = closeParen + 1;
          continue;
        }
      }
    }

    plain += text.charAt(i);
    i++;
  }

  emitPlain();
  if (out.length === 0) {
    pushSpan(out, text, false, false, false, false);
  }
  return out;
}

/** 将 Markdown 文本解析为块结构 */
export function parseMarkdownBlocks(md: string): MdBlock[] {
  if (md.length === 0) {
    return [];
  }

  const lines = md.split('\n');
  const blocks: MdBlock[] = [];
  let i = 0;
  let inCode = false;
  let codeLang = '';
  const codeLines: string[] = [];

  while (i < lines.length) {
    const line = lines[i];

    if (line.startsWith('```')) {
      if (!inCode) {
        inCode = true;
        codeLang = line.substring(3).trim();
        codeLines.length = 0;
      } else {
        inCode = false;
        const codeBlock = emptyMdBlock(MdBlockType.CODE);
        codeBlock.code = codeLines.join('\n');
        codeBlock.lang = codeLang;
        blocks.push(codeBlock);
      }
      i++;
      continue;
    }

    if (inCode) {
      codeLines.push(line);
      i++;
      continue;
    }

    const heading = parseHeadingLine(line);
    if (heading !== null) {
      const block = emptyMdBlock(MdBlockType.HEADING);
      block.level = heading.level;
      block.spans = parseInline(heading.title);
      blocks.push(block);
      i++;
      continue;
    }

    if (isHrLine(line)) {
      blocks.push(emptyMdBlock(MdBlockType.HR));
      i++;
      continue;
    }

    if (line.startsWith('> ') || line === '>') {
      const quoteLines: string[] = [];
      while (i < lines.length && (lines[i].startsWith('> ') || lines[i] === '>')) {
        quoteLines.push(lines[i].startsWith('> ') ? lines[i].substring(2) : '');
        i++;
      }
      const quoteBlock = emptyMdBlock(MdBlockType.QUOTE);
      quoteBlock.spans = parseInline(quoteLines.join('\n'));
      blocks.push(quoteBlock);
      continue;
    }

    if (isUnorderedItem(line)) {
      const items: MdListItem[] = [];
      while (i < lines.length && isUnorderedItem(lines[i])) {
        const item: MdListItem = { spans: parseInline(unorderedItemText(lines[i])) };
        items.push(item);
        i++;
      }
      const listBlock = emptyMdBlock(MdBlockType.LIST);
      listBlock.items = items;
      listBlock.ordered = false;
      blocks.push(listBlock);
      continue;
    }

    if (isOrderedItem(line)) {
      const items: MdListItem[] = [];
      while (i < lines.length && isOrderedItem(lines[i])) {
        const item: MdListItem = { spans: parseInline(orderedItemText(lines[i])) };
        items.push(item);
        i++;
      }
      const listBlock = emptyMdBlock(MdBlockType.LIST);
      listBlock.items = items;
      listBlock.ordered = true;
      blocks.push(listBlock);
      continue;
    }

    // Table detection
    if (line.startsWith('|') && (i + 1) < lines.length && isTableSeparator(lines[i + 1])) {
      const rows: string[][] = [];
      const align: string[] = [];
      // Parse header
      const headerCells = line.split('|').filter((c: string) => c.length > 0);
      const headerRow: string[] = [];
      for (const cell of headerCells) headerRow.push(cell.trim());
      rows.push(headerRow);
      // Parse separator
      const sepCells = lines[i + 1].split('|').filter((c: string) => c.length > 0);
      for (const sep of sepCells) {
        const t = sep.trim();
        if (t.startsWith(':') && t.endsWith(':')) align.push('center');
        else if (t.endsWith(':')) align.push('right');
        else align.push('left');
      }
      i += 2;
      // Parse body rows
      while (i < lines.length && lines[i].startsWith('|')) {
        const bodyCells = lines[i].split('|').filter((c: string) => c.length > 0);
        const bodyRow: string[] = [];
        for (const cell of bodyCells) bodyRow.push(cell.trim());
        rows.push(bodyRow);
        i++;
      }
      const tableBlock = emptyMdBlock(MdBlockType.TABLE);
      tableBlock.rows = rows;
      tableBlock.align = align;
      blocks.push(tableBlock);
      continue;
    }

    if (line.trim().length === 0) {
      i++;
      continue;
    }

    const paraLines: string[] = [line];
    i++;
    while (i < lines.length) {
      const next = lines[i];
      if (next.trim().length === 0 || isSpecialLine(next)) {
        break;
      }
      paraLines.push(next);
      i++;
    }
    const paraBlock = emptyMdBlock(MdBlockType.PARAGRAPH);
    paraBlock.spans = parseInline(paraLines.join('\n'));
    blocks.push(paraBlock);
  }

  if (inCode) {
    const codeBlock = emptyMdBlock(MdBlockType.CODE);
    codeBlock.code = codeLines.join('\n');
    codeBlock.lang = codeLang;
    blocks.push(codeBlock);
  }

  return blocks;
}
