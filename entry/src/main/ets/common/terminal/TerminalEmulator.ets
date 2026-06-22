export class TerminalEmulator {
  private columns: number = 80;
  private rows: number = 24;
  private cursorRow: number = 0;
  private cursorColumn: number = 0;
  private savedRow: number = 0;
  private savedColumn: number = 0;
  private screen: string[][] = [];
  private history: string[] = [];
  private readonly historyLimit: number = 2000;
  private parserState: number = 0;
  private csi: string = '';

  constructor(columns: number = 80, rows: number = 24) {
    this.resize(columns, rows);
  }

  resize(columns: number, rows: number): void {
    this.columns = Math.max(1, columns);
    this.rows = Math.max(1, rows);
    while (this.screen.length < this.rows) {
      this.screen.push(this.blankLine());
    }
    while (this.screen.length > this.rows) {
      this.history.push(this.lineText(this.screen.shift() as string[]));
    }
    this.cursorRow = Math.min(this.cursorRow, this.rows - 1);
    this.cursorColumn = Math.min(this.cursorColumn, this.columns - 1);
    this.trimHistory();
  }

  consume(input: string): void {
    for (let index: number = 0; index < input.length; index++) {
      const character: string = input.charAt(index);
      if (this.parserState === 2) {
        if (character >= '@' && character <= '~') {
          this.applyCsi(character);
          this.parserState = 0;
          this.csi = '';
        } else {
          this.csi += character;
        }
        continue;
      }
      if (this.parserState === 3) {
        if (character === '\u0007') {
          this.parserState = 0;
        } else if (character === '\u001b') {
          this.parserState = 4;
        }
        continue;
      }
      if (this.parserState === 4) {
        this.parserState = character === '\\' ? 0 : 3;
        continue;
      }
      if (this.parserState === 1) {
        if (character === '[') {
          this.parserState = 2;
          this.csi = '';
        } else if (character === ']') {
          this.parserState = 3;
        } else if (character === '7') {
          this.savedRow = this.cursorRow;
          this.savedColumn = this.cursorColumn;
          this.parserState = 0;
        } else if (character === '8') {
          this.cursorRow = this.savedRow;
          this.cursorColumn = this.savedColumn;
          this.parserState = 0;
        } else if (character === 'c') {
          this.reset();
          this.parserState = 0;
        } else {
          this.parserState = 0;
        }
        continue;
      }
      if (character === '\u001b') {
        this.parserState = 1;
      } else if (character === '\r') {
        this.cursorColumn = 0;
      } else if (character === '\n') {
        this.lineFeed();
      } else if (character === '\b') {
        this.cursorColumn = Math.max(0, this.cursorColumn - 1);
      } else if (character === '\t') {
        const nextTab: number = Math.min(this.columns - 1, (Math.floor(this.cursorColumn / 8) + 1) * 8);
        this.cursorColumn = nextTab;
      } else if (character >= ' ') {
        this.put(character);
      }
    }
  }

  render(): string {
    const lines: string[] = this.history.slice();
    this.screen.forEach((line: string[]) => lines.push(this.lineText(line)));
    while (lines.length > 0 && lines[lines.length - 1].length === 0) {
      lines.pop();
    }
    return lines.join('\n');
  }

  reset(): void {
    this.cursorRow = 0;
    this.cursorColumn = 0;
    this.history = [];
    this.screen = [];
    while (this.screen.length < this.rows) {
      this.screen.push(this.blankLine());
    }
  }

  private blankLine(): string[] {
    const line: string[] = [];
    for (let index: number = 0; index < this.columns; index++) {
      line.push(' ');
    }
    return line;
  }

  private lineText(line: string[]): string {
    let end: number = line.length;
    while (end > 0 && line[end - 1] === ' ') end--;
    return line.slice(0, end).join('');
  }

  private trimHistory(): void {
    if (this.history.length > this.historyLimit) {
      this.history = this.history.slice(this.history.length - this.historyLimit);
    }
  }

  private lineFeed(): void {
    this.cursorRow++;
    if (this.cursorRow >= this.rows) {
      this.history.push(this.lineText(this.screen.shift() as string[]));
      this.screen.push(this.blankLine());
      this.cursorRow = this.rows - 1;
      this.trimHistory();
    }
  }

  private put(character: string): void {
    if (this.cursorColumn >= this.columns) {
      this.cursorColumn = 0;
      this.lineFeed();
    }
    this.screen[this.cursorRow][this.cursorColumn] = character;
    this.cursorColumn++;
  }

  private parameter(index: number, fallback: number = 1): number {
    const normalized: string = this.csi.replace('?', '').replace('>', '');
    const values: string[] = normalized.split(';');
    if (index >= values.length || values[index].length === 0) return fallback;
    const value: number = Number(values[index]);
    return Number.isNaN(value) ? fallback : value;
  }

  private applyCsi(finalCharacter: string): void {
    const amount: number = Math.max(1, this.parameter(0, 1));
    if (finalCharacter === 'A') {
      this.cursorRow = Math.max(0, this.cursorRow - amount);
    } else if (finalCharacter === 'B') {
      this.cursorRow = Math.min(this.rows - 1, this.cursorRow + amount);
    } else if (finalCharacter === 'C') {
      this.cursorColumn = Math.min(this.columns - 1, this.cursorColumn + amount);
    } else if (finalCharacter === 'D') {
      this.cursorColumn = Math.max(0, this.cursorColumn - amount);
    } else if (finalCharacter === 'G') {
      this.cursorColumn = Math.min(this.columns - 1, Math.max(0, amount - 1));
    } else if (finalCharacter === 'H' || finalCharacter === 'f') {
      this.cursorRow = Math.min(this.rows - 1, Math.max(0, this.parameter(0, 1) - 1));
      this.cursorColumn = Math.min(this.columns - 1, Math.max(0, this.parameter(1, 1) - 1));
    } else if (finalCharacter === 'J') {
      const mode: number = this.parameter(0, 0);
      if (mode === 2 || mode === 3) {
        this.screen = [];
        while (this.screen.length < this.rows) this.screen.push(this.blankLine());
        this.cursorRow = 0;
        this.cursorColumn = 0;
        if (mode === 3) this.history = [];
      } else {
        for (let row: number = this.cursorRow; row < this.rows; row++) {
          const start: number = row === this.cursorRow ? this.cursorColumn : 0;
          for (let column: number = start; column < this.columns; column++) this.screen[row][column] = ' ';
        }
      }
    } else if (finalCharacter === 'K') {
      const mode: number = this.parameter(0, 0);
      const start: number = mode === 1 || mode === 2 ? 0 : this.cursorColumn;
      const end: number = mode === 0 ? this.columns : Math.min(this.columns, this.cursorColumn + 1);
      for (let column: number = start; column < end; column++) this.screen[this.cursorRow][column] = ' ';
    } else if (finalCharacter === 's') {
      this.savedRow = this.cursorRow;
      this.savedColumn = this.cursorColumn;
    } else if (finalCharacter === 'u') {
      this.cursorRow = this.savedRow;
      this.cursorColumn = this.savedColumn;
    }
  }
}
