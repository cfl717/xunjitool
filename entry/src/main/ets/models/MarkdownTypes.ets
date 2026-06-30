/** Markdown 行内样式片段 */
export interface MdInlineSpan {
  text: string;
  bold: boolean;
  italic: boolean;
  code: boolean;
  link: boolean;
}

/** 列表项 */
export interface MdListItem {
  spans: MdInlineSpan[];
}

/** Markdown 块类型 */
export enum MdBlockType {
  PARAGRAPH = 'paragraph',
  HEADING = 'heading',
  CODE = 'code',
  LIST = 'list',
  QUOTE = 'quote',
  HR = 'hr',
  TABLE = 'table'
}

/** Markdown 块 */
export interface MdBlock {
  type: MdBlockType;
  level: number;
  spans: MdInlineSpan[];
  code: string;
  lang: string;
  items: MdListItem[];
  ordered: boolean;
  rows: string[][];
  align: string[];
}

export function emptyMdBlock(type: MdBlockType): MdBlock {
  return {
    type: type,
    level: 0,
    spans: [],
    code: '',
    lang: '',
    items: [],
    ordered: false,
    rows: [],
    align: []
  };
}
