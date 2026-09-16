// 이야기·대사 엑셀 대본 (대표님 집필용)
//   node tool/story_template.js export  → 볼트에 NIM_대본.xlsx (현재 ko 문장 + 빈 칸)
//   node tool/story_template.js import  → xlsx 의 "문장" 칸을 app_strings.dart 'ko' 에 반영.
//                                          새로 채운 빈 칸은 새 키로 추가(en=ko 임시). 바뀐 키 → tool/story_changed.txt
// 규칙: "문장" 칸만 고치세요. 키 칸은 건드리지 마세요. 줄바꿈 없이 한 줄.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const STRINGS = path.join(ROOT, 'lib/l10n/app_strings.dart');
const XLSX = path.win32.normalize('C:/Users/leeyuseok/Desktop/endolphin/03_프로젝트/NIM_GAME/NIM_대본.xlsx');
const CHANGED = path.join(__dirname, 'story_changed.txt');
const PS1 = path.join(__dirname, 'story_xlsx.ps1');
const TMP = path.join(__dirname, 'story_sheets.json');
const LANGS = ['en', 'ko', 'ja', 'zh', 'es', 'pt', 'de', 'fr', 'id', 'vi'];

const WORLDS = [
  [1, '등교길', '사탕 · 한 줄 님게임'], [2, '점심시간 옥상', '초콜릿 · 두 줄 님게임'], [3, '방과후 교실', '쿠키 · 세 줄 님게임'],
  [4, '밤의 도서관', '막대과자 · 쪼개기'], [5, '체육관', '마카롱 · 카일즈'], [6, '과학실', '도넛 · 위토프'],
  [7, '뒤뜰 토끼장', '젤리 · 피보나치 님'], [8, '매점', '춉'], [9, '미술실', '점과 상자'],
  [10, '수학 동아리실', '심'], [11, '온실', '스프라우트'], [12, '보드게임부', '헥스'],
];
const SHORT = ['예린', '나', '예린', '예린', '나', '예린'];
const LONG = ['예린', '예린', '나', '예린', '나', '예린', '예린', '나', '예린', '나', '예린', '예린'];
const SHORT_FACE = ['평온', '-', '자신만만', '살짝 곤란', '-', '미소'];
const LONG_FACE = ['평온', '생각 중', '-', '자신만만', '-', '살짝 곤란', '당황', '-', '미소', '-', '미소', '활짝'];
const POOLS = [
  ['greet', '판 시작 인사', 6], ['won', '예린이 이겼을 때', 6], ['lost', '예린이 졌을 때', 6],
  ['winEarly', '내가 지고 있을 때 (초반)', 5], ['winLate', '내가 계속 지고 있을 때', 5], ['daily_win', '오늘의 한 판 이겼을 때', 5],
];
const SINGLES = [
  ['midnightGreeting', '홈 화면 인사'], ['dailyGreet', '오늘의 한 판 시작'], ['yourTurnNow', '내 차례'], ['midnightThinking', '예린 생각 중'],
  ['pokeReact1', '예린 찌르기 1'], ['pokeReact2', '예린 찌르기 2'], ['pokeReact3', '예린 찌르기 3'],
  ['simOpening', '심 시작 (예린이 먼저 한 줄)'], ['hintLosingRetry', '힌트: 이미 진 판'], ['replayNone', '되감기: 결정적 실수 없음'],
  ['dotsExtraTurn', '점과 상자: 한 번 더'], ['g1_1', '튜토리얼 1 인사'], ['g1_2', '튜토리얼 1 지시'], ['g1_3', '튜토리얼 1 마무리'],
  ['g2_1', '튜토리얼 21 인사'], ['g3_1', '튜토리얼 41 인사'], ['g4_1', '튜토리얼 61 인사'],
];
const RULE_KEYS = ['ruleSingleRow', 'ruleDoubleRow', 'ruleTripleRow', 'rulePepero', 'ruleKayles', 'ruleWythoff', 'ruleFibonacci', 'ruleChomp', 'ruleDots', 'ruleSim', 'ruleSprouts', 'ruleHex'];

function readMap() {
  const src = fs.readFileSync(STRINGS, 'utf8').replace(/\r\n/g, '\n');
  const map = {};
  const re = /^    '([A-Za-z0-9_]+)': \{\n([\s\S]*?)^    \},/gm;
  let m;
  while ((m = re.exec(src))) {
    const ko = /^      'ko': '((?:[^'\\]|\\.)*)',/m.exec(m[2]);
    if (ko) map[m[1]] = ko[1].replace(/\\'/g, "'").replace(/\\n/g, ' ').replace(/\\\\/g, '\\');
  }
  return map;
}
function ps(args) {
  return execFileSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', PS1, ...args], { encoding: 'utf8' });
}

function exportXlsx() {
  const ko = readMap();
  const g = k => ko[k] ?? '';
  const sheets = [];
  sheets.push({
    name: '안내', cols: ['방과후 님게임 대본 — 쓰는 법'], widths: [110], rows: [
      ['1. 각 시트의 파란 "문장" 칸만 고치세요. 키·수업·화자 칸은 그대로 두세요.'],
      ['2. 문장은 한 줄로. 줄바꿈(Alt+Enter)은 쓰지 마세요. 60자 안쪽이면 대화 상자에 잘 들어갑니다.'],
      ['3. 빈 칸을 채우면 새 대사가 추가됩니다(랜덤 목록). 비워 두면 그대로 없는 것으로 칩니다.'],
      ['4. 예린 말투: 반말, 무뚝뚝, 속은 따뜻함. "나"는 플레이어의 짧은 대답. 상표명 과자 이름은 쓰지 마세요.'],
      ['5. 이야기 시트: 수업마다 5·10·15판째 = 중간 장면 6줄(예린↔나), 20판 다 깨면 = 긴 장면 12줄. 화자 순서는 고정입니다.'],
      ['6. 표정은 코드에 고정되어 있습니다(참고용). 바꾸고 싶으면 따로 말씀해 주세요.'],
      ['7. 다 쓰시면 저장하고 "대본 반영해 줘"라고 하시면 됩니다. 한국어를 게임에 넣고 바뀐 줄만 9개 언어로 다시 번역합니다.'],
      ['   (직접: 프로젝트 폴더에서 node tool/story_template.js import)'],
    ],
  });
  // 이야기
  const story = [];
  for (const [n, name] of WORLDS) {
    for (let k = 1; k <= 4; k++) {
      const kind = k === 4 ? '긴 장면 (20판 다 깨면)' : `중간 장면 (${k * 5}판째)`;
      const sp = k === 4 ? LONG : SHORT, fc = k === 4 ? LONG_FACE : SHORT_FACE;
      story.push([`sc_w${n}_${k}_title`, `${n}. ${name}`, `${n}-${k}`, kind, '제목', '', '', g(`sc_w${n}_${k}_title`)]);
      for (let i = 0; i < sp.length; i++) {
        story.push([`sc_w${n}_${k}_${i + 1}`, `${n}. ${name}`, `${n}-${k}`, kind, String(i + 1), sp[i], fc[i], g(`sc_w${n}_${k}_${i + 1}`)]);
      }
    }
  }
  sheets.push({ name: '이야기', cols: ['키', '수업', '장면', '종류', '줄', '화자', '표정(참고)', '문장'], widths: [16, 16, 7, 20, 5, 6, 11, 70], editCol: 7, rows: story });
  // 한마디
  const dc = [];
  for (const [n, name] of WORLDS) {
    for (let i = 1; i <= 6; i++) dc.push([`dc_w${n}_${i}`, `${n}. ${name}`, g(`dc_w${n}_${i}`)]);
  }
  sheets.push({ name: '클리어 한마디', cols: ['키', '수업', '문장 (이길 때마다 이 중 하나가 랜덤. 빈 칸 채우면 추가)'], widths: [12, 16, 80], editCol: 2, rows: dc });
  // 대사풀
  const pool = [];
  for (const [base, sit, n] of POOLS) for (let i = 1; i <= n; i++) pool.push([`${base}_${i}`, sit, g(`${base}_${i}`)]);
  for (const [k, sit] of SINGLES) pool.push([k, sit, g(k)]);
  sheets.push({ name: '상황별 대사', cols: ['키', '상황', '문장 (같은 상황은 랜덤. 빈 칸 채우면 추가)'], widths: [16, 28, 80], editCol: 2, rows: pool });
  // 규칙
  const rules = [];
  for (const [n, name, sub] of WORLDS) {
    rules.push([RULE_KEYS[n - 1], `${n}. ${name} (${sub})`, '게임 규칙 본문 ({0}=간식 이름, {1}=최대 개수 — 그대로 두세요)', g(RULE_KEYS[n - 1])]);
    rules.push([`rx_w${n}_1`, `${n}. ${name}`, '보충 설명 1', g(`rx_w${n}_1`)]);
    rules.push([`rx_w${n}_2`, `${n}. ${name}`, '보충 설명 2', g(`rx_w${n}_2`)]);
    if (n === 4) for (let i = 1; i <= 4; i++) rules.push([`ri_w4_${i}`, '4. 밤의 도서관', `규칙 설명 화면 ${i}쪽 (그림과 함께)`, g(`ri_w4_${i}`)]);
  }
  sheets.push({ name: '규칙 설명', cols: ['키', '수업', '무엇', '문장'], widths: [14, 24, 30, 80], editCol: 3, rows: rules });
  fs.writeFileSync(TMP, JSON.stringify(sheets), 'utf8');
  console.log(ps(['export', TMP, XLSX]).trim());
}

function escKo(v) { return v.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$'); }

function importXlsx() {
  const json = path.join(__dirname, 'story_import.json');
  console.log(ps(['import', XLSX, json]).trim());
  const data = JSON.parse(fs.readFileSync(json, 'utf8'));
  const ko = readMap();
  const raw = fs.readFileSync(STRINGS, 'utf8');
  const crlf = raw.includes('\r\n');
  let src = raw.replace(/\r\n/g, '\n');
  const changed = [], added = [];
  for (const sheet of Object.keys(data)) {
    const rows = data[sheet];
    if (!rows.length) continue;
    const last = rows[0].length - 1; // 문장 = 마지막 칸
    for (let r = 1; r < rows.length; r++) {
      const key = String(rows[r][0] || '').trim();
      const text = String(rows[r][last] || '').replace(/\s+/g, ' ').trim();
      if (!/^[A-Za-z0-9_]+$/.test(key) || !text) continue;
      if (key in ko) {
        if (text === ko[key]) continue;
        const re = new RegExp(`(^    '${key}': \\{\\n[\\s\\S]*?^      'ko': ')((?:[^'\\\\]|\\\\.)*)(',)`, 'm');
        if (!re.test(src)) continue;
        src = src.replace(re, (_, a, __, c) => a + escKo(text) + c);
        changed.push(`${key}\t${text}`);
      } else {
        // 새 키: 모든 언어를 ko 로 임시 채움 (번역은 Claude 가)
        const block = `    '${key}': {\n` + LANGS.map(l => `      '${l}': '${escKo(text)}',`).join('\n') + `\n    },\n`;
        const getIdx = src.indexOf('  String get(String key');
        const endMap = src.lastIndexOf('\n  };\n', getIdx);
        src = src.slice(0, endMap + 1) + block + src.slice(endMap + 1);
        added.push(`${key}\t${text}`);
      }
    }
  }
  fs.writeFileSync(STRINGS, crlf ? src.replace(/\n/g, '\r\n') : src, 'utf8');
  fs.writeFileSync(CHANGED, [...changed, ...added].join('\n') + (changed.length + added.length ? '\n' : ''), 'utf8');
  console.log(`changed ${changed.length}, added ${added.length} → ${CHANGED}`);
}

const cmd = process.argv[2];
if (cmd === 'export') exportXlsx();
else if (cmd === 'import') importXlsx();
else console.log('usage: node tool/story_template.js export|import');
