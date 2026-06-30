param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$TypeScriptPath = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\ets\build-tools\ets-loader\node_modules\typescript"
)

$ErrorActionPreference = "Stop"
$sourcePath = Join-Path $ProjectRoot "entry\src\main\ets\common\terminal\TerminalEmulator.ets"
if (-not (Test-Path -LiteralPath $sourcePath)) {
  throw "Terminal emulator source not found: $sourcePath"
}
if (-not (Test-Path -LiteralPath $TypeScriptPath)) {
  throw "DevEco TypeScript package not found. Pass -TypeScriptPath explicitly."
}
$node = (Get-Command node -ErrorAction Stop).Source
$nodeScript = @'
const fs = require('fs');
const ts = require(process.argv[1]);
const sourcePath = process.argv[2];
const source = fs.readFileSync(sourcePath, 'utf8');
const compilerOptions = {
  noEmit: true,
  target: ts.ScriptTarget.ES2021,
  module: ts.ModuleKind.ES2020,
  strict: true,
  allowNonTsExtensions: true,
  skipLibCheck: true
};
const host = ts.createCompilerHost(compilerOptions);
const defaultGetSourceFile = host.getSourceFile;
host.getSourceFile = (fileName, languageVersion, onError, shouldCreateNewSourceFile) => {
  if (fileName === sourcePath) {
    return ts.createSourceFile(fileName, source, languageVersion, true, ts.ScriptKind.TS);
  }
  return defaultGetSourceFile(fileName, languageVersion, onError, shouldCreateNewSourceFile);
};
const program = ts.createProgram([sourcePath], compilerOptions, host);
const diagnostics = ts.getPreEmitDiagnostics(program);
if (diagnostics.length > 0) {
  for (const diagnostic of diagnostics) {
    const message = ts.flattenDiagnosticMessageText(diagnostic.messageText, ' ');
    process.stderr.write(`${message}\n`);
  }
  process.exit(1);
}
process.stdout.write('PASS semantic diagnostics\n');
const output = ts.transpileModule(source, {
  compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS }
}).outputText;
const loaded = { exports: {} };
new Function('module', 'exports', output)(loaded, loaded.exports);
const TerminalEmulator = loaded.exports.TerminalEmulator;

function check(name, actual, expected) {
  if (actual !== expected) {
    throw new Error(`${name}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
  process.stdout.write(`PASS ${name}\n`);
}

let terminal = new TerminalEmulator(10, 3);
terminal.consume('abc\rZ');
check('cursor overwrite', terminal.render(), 'Zbc');
terminal.consume('\u001b[31mR\u001b[38;5;46mG\u001b[48;2;1;2;3mB');
let runs = terminal.renderLines().flatMap((line) => line.runs);
check('16 color', runs.some((run) => run.text.includes('R') && run.foreground === '#CD3131'), true);
check('256 color', runs.some((run) => run.text.includes('G') && run.foreground === '#00FF00'), true);
check('truecolor background', runs.some((run) => run.text.includes('B') && run.background === '#010203'), true);

terminal = new TerminalEmulator(8, 2);
terminal.consume('main\u001b[?1049halt');
check('alternate screen hides primary history', terminal.render(), 'alt');
terminal.consume('\u001b[?1049l');
check('alternate screen restore', terminal.render(), 'main');
terminal.consume('\u001b]2;remote title\u0007');
check('OSC title', terminal.getTitle(), 'remote title');
terminal.consume('\u009d2;safe\n title\u009c');
check('C1 OSC and title sanitization', terminal.getTitle(), 'safe title');
terminal.consume('\u001b[2;3H\u001b[6n\u001b[c');
check('DSR and DA', terminal.drainResponses(), '\u001b[2;3R\u001b[?1;2c');

terminal = new TerminalEmulator(6, 2);
terminal.consume('A\u0301\u4E2DB');
check('combining and wide text', terminal.render(), 'A\u0301\u4E2DB');
terminal = new TerminalEmulator(4, 2);
terminal.consume('1111\r\n2222\r\n3333');
check('bounded scroll', terminal.render(), '1111\n2222\n3333');
terminal = new TerminalEmulator(6, 2);
terminal.consume('\u001b(0lqk\u001b(B');
check('DEC line drawing', terminal.render(), '\u250C\u2500\u2510');

terminal = new TerminalEmulator(40, 8);
let seed = 0x13579BDF;
const fragments = ['abc', '\r', '\n', '\b', '\t', '\u001b[2J', '\u001b[31m', '\u001b[0m',
  '\u001b[2;6r', '\u001b[1L', '\u001b[2P', '\u001b[?1049h', '\u001b[?1049l', '\u4E2D', 'e\u0301'];
for (let index = 0; index < 2000; index++) {
  seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
  terminal.consume(fragments[seed % fragments.length]);
  if (index % 50 === 0) terminal.renderLines();
}
check('deterministic control-sequence fuzz', terminal.renderLines().length > 0, true);
process.stdout.write('TerminalEmulator functional checks: PASS\n');
'@

& $node -e $nodeScript $TypeScriptPath $sourcePath
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
