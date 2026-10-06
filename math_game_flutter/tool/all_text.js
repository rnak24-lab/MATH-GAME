// 게임 안 모든 글 (한국어) 엑셀 — 대표님 전체 검수용 (2026-10-07)
//   node tool/all_text.js export   → 볼트 NIM_GAME/NIM_게임글_전체.xlsx  (1열 상황, 2열 문장, 3열 키)
//   node tool/all_text.js import [xlsx]  → 2열을 app_strings.dart 'ko' 에 반영, 바뀐 키 → tool/story_changed.txt
// 키 칸(3열)은 건드리지 않는다. 줄바꿈이 필요한 문장(규칙 설명)은 칸 안 줄바꿈 그대로.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const T = require('./story_template.js');

const ROOT = path.resolve(__dirname, '..');
const STRINGS = path.join(ROOT, 'lib/l10n/app_strings.dart');
const XLSX = path.win32.normalize('C:/Users/leeyuseok/Desktop/endolphin/03_프로젝트/NIM_GAME/NIM_게임글_전체.xlsx');
const PS1 = path.join(__dirname, 'story_xlsx.ps1');
const CHANGED = path.join(__dirname, 'story_changed.txt');
const LANGS = ['en', 'ko', 'ja', 'zh', 'es', 'pt', 'de', 'fr', 'id', 'vi'];

function readKo() {
  const src = fs.readFileSync(STRINGS, 'utf8').replace(/\r\n/g, '\n');
  const map = {};
  const re = /^    '([A-Za-z0-9_]+)': \{\n([\s\S]*?)^    \},/gm;
  let m;
  while ((m = re.exec(src))) {
    const ko = /^      'ko': '((?:[^'\\]|\\.)*)',/m.exec(m[2]);
    if (ko) map[m[1]] = ko[1].replace(/\\(.)/g, (_, c) => (c === 'n' ? '\n' : c));
  }
  return map;
}

// ── 화면 글자·규칙·대사 키별 상황 설명 (쓰는 키만) ──
const L = {
  // 홈·공통
  appTitle: '게임 이름 (로딩 화면)', appSubtitle: '게임 부제 (로딩 화면)', mathNimSubtitle: '게임 부제 (홈 화면 제목 밑)',
  midnightGreeting: '홈 화면 예린 인사 (다시 온 사람)', midnightGreetingNew: '홈 화면 예린 인사 (처음 온 사람)',
  continueGame: '홈 큰 버튼 (진행 중일 때)', startGame: '홈 큰 버튼 (처음일 때)', dailyButton: '홈 작은 버튼: 오늘 한 판',
  dailyDone: '홈 작은 버튼: 오늘 한 판 이미 함 ({0}=연속 일수)', galleryButton: '홈 작은 버튼: 이야기 모음', noteButton: '홈 작은 버튼: 규칙 노트',
  settings: '설정 화면 제목', worldSelect: '월드 선택 화면 제목', tierNim: '월드 선택: 위쪽 묶음 이름', tierBoard: '월드 선택: 아래쪽 묶음 이름',
  unlockHint3Stages: '월드 선택: 잠긴 월드 안내 ({0}=앞 월드 번호)', stageLabel: '게임 화면 위: 스테이지 번호 ({0})',
  nameYou: '이야기 대화창 이름표 (플레이어)', nameMidnight: '이야기 대화창 이름표 (예린)',
  // 월드 이름 / 게임 종류
  worldMorningRoad: '월드 1 이름', worldRooftopLunch: '월드 2 이름', worldAfterSchool: '월드 3 이름', worldNightLibrary: '월드 4 이름',
  worldGym: '월드 5 이름', worldScienceLab: '월드 6 이름', worldRabbitHutch: '월드 7 이름', worldSnackBar: '월드 8 이름',
  worldArtRoom: '월드 9 이름', worldMathClub: '월드 10 이름', worldGreenhouse: '월드 11 이름', worldBoardClub: '월드 12 이름',
  worldSubtitleSingleRow: '월드 1 부제 (게임 종류)', worldSubtitleDoubleRow: '월드 2 부제', worldSubtitleTripleRow: '월드 3 부제',
  worldSubtitlePepero: '월드 4 부제', worldSubtitleKayles: '월드 5 부제', worldSubtitleWythoff: '월드 6 부제', worldSubtitleFibonacci: '월드 7 부제',
  modeSingleRow: '게임 종류 이름: 월드 1', modeDoubleRow: '게임 종류 이름: 월드 2', modeTripleRow: '게임 종류 이름: 월드 3', modePepero: '게임 종류 이름: 월드 4',
  modeKayles: '게임 종류 이름: 월드 5', modeWythoff: '게임 종류 이름: 월드 6', modeFibonacci: '게임 종류 이름: 월드 7', modeChomp: '게임 종류 이름: 월드 8',
  modeDots: '게임 종류 이름: 월드 9', modeSim: '게임 종류 이름: 월드 10', modeSprouts: '게임 종류 이름: 월드 11', modeHex: '게임 종류 이름: 월드 12',
  modeQuadRow: '게임 종류 이름: 네 줄 (예전 것, 규칙 노트에만)',
  candy: '간식 이름: 월드 1', chocolate: '간식 이름: 월드 2', cookie: '간식 이름: 월드 3', stick: '간식 이름: 월드 4',
  macaron: '간식 이름: 월드 5', donut: '간식 이름: 월드 6', jelly: '간식 이름: 월드 7', generic: '간식 이름: 그 밖',
  // 게임 화면
  victory: '게임 끝: 이겼을 때 도장', defeat: '게임 끝: 졌을 때 도장', retry: '졌을 때 버튼: 다시하기', goBack: '졌을 때 버튼: 돌아가기',
  stageClear: '클리어 창 제목', stageClearDesc: '클리어 창 설명 ({0}=스테이지)', nextStage: '클리어 창 버튼: 다음', backToStageSelect: '클리어 창 버튼: 스테이지 선택으로',
  storyNext: '클리어 창: 다음 이야기까지 ({0}=남은 판)', storyWorldDone: '클리어 창: 이 월드 이야기 다 봄',
  takeNStones: '님게임 버튼: 가져가기 ({0}=개수)', takeRange: '님게임 칩: 한 번에 가져갈 수 있는 개수 ({0}=최대)', takeAny: '님게임 칩: 원하는 만큼',
  lastStoneWinChip: '님게임 칩: 승리 조건 ({0}=간식)', pickFirstCta: '님게임 버튼 안내: 아직 안 골랐을 때 ({0}=간식)',
  kaylesChip: '월드 5 칩', kaylesTapCta: '월드 5 버튼 안내 ({0}=간식)', wythoffChip: '월드 6 칩', wythoffInvalid: '월드 6 잘못 골랐을 때',
  chipPepero: '월드 4 칩', peperoTapStick: '월드 4 안내: 막대 누르기', peperoDeadTray: '월드 4: 더 못 쪼개는 조각 칸 이름', splitAction: '월드 4 버튼: 나누기 ({0}+{1})',
  chipChomp1: '월드 8 칩 1', chipChomp2: '월드 8 칩 2', chipDots1: '월드 9 칩 1', chipDots2: '월드 9 칩 2', chipSim1: '월드 10 칩 1', chipSim2: '월드 10 칩 2',
  chipSprouts1: '월드 11 칩 1', chipSprouts2: '월드 11 칩 2', chipHex1: '월드 12 칩 1', chipHex2: '월드 12 칩 2',
  ctaChomp: '월드 8 버튼 안내', ctaDots: '월드 9 버튼 안내', ctaSim: '월드 10 버튼 안내', ctaSprouts: '월드 11 버튼 안내', ctaHex: '월드 12 버튼 안내', ctaConnect2: '점 하나 고른 뒤 안내 (월드 9~11)',
  dotsExtraTurn: '월드 9: 네모 완성해서 한 번 더', dotsOpening: '월드 9 시작 예린 대사', simOpening: '월드 10·11 시작 예린 대사',
  menuTitle: '게임 메뉴 제목', menuResume: '게임 메뉴: 계속하기',
  hintDialogTitle: '힌트 창 제목', hintDialogBody: '힌트 창 설명 (광고 있을 때)', hintWatchAd: '힌트 창 버튼 (광고 있을 때)',
  hintDialogBodyFree: '힌트 창 설명 (광고 없을 때)', hintShow: '힌트 창 버튼 (광고 없을 때)',
  hintSingleRow: '힌트 결과: 한 줄 ({0}=개수)', hintMultiRow: '힌트 결과: 여러 줄 ({0}=개수, {1}=줄)', hintPepero: '힌트 결과: 막대과자 ({0}+{1})',
  hintBoard: '힌트 결과: 보드 게임', hintLosingRetry: '힌트 결과: 이미 지는 판일 때',
  yourTurnNow: '예린 대사: 내 차례 왔을 때', midnightThinking: '예린 대사: 예린이 생각 중',
  midnightTakeN: '예린 대사: 예린이 가져갈 때 ({0}=개수)', midnightTakeFromRow: '예린 대사: 예린이 줄에서 가져갈 때 ({0}=개수, {1}=줄)',
  midnightTookTotal: '예린 대사: 예린이 가져간 뒤 ({0})', midnightTookFromRowTotal: '예린 대사: 예린이 줄에서 가져간 뒤 ({0}, {1})',
  midnightTookBoth: '예린 대사: 월드 6 양쪽에서 가져감 ({0})', midnightSplit: '예린 대사: 막대과자 쪼갤 때 ({0}+{1})',
  pokeReact1: '예린 찌르면 1', pokeReact2: '예린 찌르면 2', pokeReact3: '예린 찌르면 3',
  // 튜토리얼
  g1_1: '첫 판 안내 1 ({0}=간식)', g1_2: '첫 판 안내 2', g1_3: '첫 판 안내 3', g1_win: '첫 판 이겼을 때 예린 한마디',
  g2_1: '월드 2 첫 판 안내 1', g2_2: '월드 2 첫 판 안내 2', g2_3: '월드 2 첫 판 안내 3', g2_4: '월드 2 첫 판 안내 4',
  g3_1: '월드 3 첫 판 안내 1', g3_2: '월드 3 첫 판 안내 2', g3_3: '월드 3 첫 판 안내 3', g3_4: '월드 3 첫 판 안내 4',
  g4_1: '월드 4 첫 판 안내 1', g4_2: '월드 4 첫 판 안내 2', g4_3: '월드 4 첫 판 안내 3',
  gFollow: '안내: 하늘색 따라 하기 ({0}=간식)', gFollowBoard: '안내: 하늘색 따라 하기 (보드)',
  guideTap: '안내 글씨 ① ({0}=간식)', guideConfirm: '안내 글씨 ②', guideTapBoard: '안내 글씨 (보드 게임)',
  tutNext: '안내 버튼: 다음', tutStart: '안내 버튼: 시작',
  tutW6_1: '월드 5 첫 판 안내 1 ({0}=간식)', tutW6_2: '월드 5 첫 판 안내 2', tutW7_1: '월드 6 첫 판 안내 1', tutW7_2: '월드 6 첫 판 안내 2',
  tutW8_1: '월드 7 첫 판 안내 1', tutW8_2: '월드 7 첫 판 안내 2',
  // 규칙 화면
  ruleIntroTitle: '규칙 설명 화면 제목', ruleIntroBack: '규칙 설명 버튼: 이전', ruleIntroStart: '규칙 설명 버튼: 시작', riLast: '규칙 그림 글씨: 마지막', riTake: '규칙 그림 글씨: 가져가기',
  ddCaption: '규칙 마지막 장 아래 글', ddOk: '규칙 마지막 장: 되는 것 제목', ddNo: '규칙 마지막 장: 안 되는 것 제목',
  noteTitle: '규칙 노트 화면 제목', howToPlay: '설정: 게임 규칙 버튼', rulesTitle: '게임 규칙 창 제목', ok: '확인 버튼',
  // 이야기·오늘 한 판
  galleryTitle: '이야기 모음 화면 제목', storyLockedAt: '이야기 모음: 잠긴 장면 ({0}=판 수)', sceneSkip: '이야기 화면: 건너뛰기',
  dailyTitle: '오늘 한 판: 게임 화면 제목', dailyGreet: '오늘 한 판: 시작 예린 대사', dailyClear: '오늘 한 판: 이겼을 때 ({0}=연속 일수)', dailyDoneHint: '오늘 한 판: 이미 이겼을 때',
  // 설정
  languageSettings: '설정: 언어 칸 제목', settingsGameplay: '설정: 게임 칸 제목', musicTitle: '설정: 배경음악', sfxTitle: '설정: 효과음', hapticsTitle: '설정: 진동',
  focusModeTitle: '설정: 집중 모드', focusModeDesc: '설정: 집중 모드 설명', resetProgress: '설정: 진행도 초기화', resetConfirmTitle: '초기화 확인 창 제목',
  resetConfirmBody: '초기화 확인 창 설명', cancel: '취소 버튼', resetDo: '초기화 확인 창 버튼', resetDone: '초기화 끝 알림',
  aboutSettings: '설정: 정보 칸 제목', privacyPolicy: '설정: 개인정보처리방침', versionLabel: '설정: 버전',
  telemetryTitle: '설정: 테스트 리포트', telemetrySummary: '설정: 테스트 리포트 설명 ({0}세션, {1}판, {2}전송)', telemetryNever: '테스트 리포트: 보낸 적 없음',
  telemetrySend: '테스트 리포트 버튼', telemetrySent: '테스트 리포트 보낸 뒤 알림', telemetryFailCopied: '테스트 리포트 실패 알림',
};
const RULES = ['ruleSingleRow', 'ruleDoubleRow', 'ruleTripleRow', 'rulePepero', 'ruleKayles', 'ruleWythoff', 'ruleFibonacci', 'ruleChomp', 'ruleDots', 'ruleSim', 'ruleSprouts', 'ruleHex'];
const FACE_KO = { neutral: '평온', happy1: '미소', happy2: '활짝', worried1: '살짝 곤란', worried2: '당황', confident: '자신만만', thinking: '생각 중' };

function exportXlsx() {
  const ko = readKo();
  const g = k => ko[k] ?? '';
  const script = T.readSceneScript();
  const W = T.WORLDS;
  const used = new Set();
  const row = (sit, key) => { used.add(key); return [sit, g(key), key]; };

  // 1. 이야기
  const story = [];
  for (const [n, name] of W) {
    for (let k = 1; k <= 4; k++) {
      const id = `sc_w${n}_${k}`;
      const when = k === 4 ? '20판 다 깨면 (긴 장면)' : `${k * 5}판째`;
      story.push(row(`${n}. ${name} / ${n}-${k} 장면 제목 (${when})`, `${id}_title`));
      T.sceneLayout(n, k, script).forEach((l, i) => {
        story.push(row(`${n}-${k} ${i + 1}번째 줄 · ${l.who === 'y' ? '예린' : '나'}${l.who === 'y' ? ' [' + (FACE_KO[l.face] || l.face) + ']' : ''}`, `${id}_${i + 1}`));
      });
    }
  }
  // 2. 예린 대사 (게임 중)
  const talk = [];
  for (const [n, name] of W) for (let i = 1; i <= 30 && (`dc_w${n}_${i}` in ko); i++) talk.push(row(`${n}. ${name} 판 이겼을 때 예린 한마디 (이 중 하나 랜덤)`, `dc_w${n}_${i}`));
  for (const [base, label] of T.POOLS) for (let i = 1; i <= 30 && (`${base}_${i}` in ko); i++) talk.push(row(`${label} (이 중 하나 랜덤)`, `${base}_${i}`));
  const talkKeys = ['midnightGreeting', 'midnightGreetingNew', 'yourTurnNow', 'midnightThinking', 'midnightTakeN', 'midnightTakeFromRow', 'midnightTookTotal',
    'midnightTookFromRowTotal', 'midnightTookBoth', 'midnightSplit', 'pokeReact1', 'pokeReact2', 'pokeReact3', 'dotsOpening', 'simOpening', 'dotsExtraTurn',
    'g1_win', 'dailyGreet', 'dailyClear', 'dailyDoneHint'];
  for (const k of talkKeys) talk.push(row(L[k], k));
  // 3. 튜토리얼·규칙
  const rules = [];
  for (const k of ['g1_1', 'g1_2', 'g1_3', 'g2_1', 'g2_2', 'g2_3', 'g2_4', 'g3_1', 'g3_2', 'g3_3', 'g3_4', 'g4_1', 'g4_2', 'g4_3', 'tutW6_1', 'tutW6_2', 'tutW7_1', 'tutW7_2', 'tutW8_1', 'tutW8_2',
    'gFollow', 'gFollowBoard', 'guideTap', 'guideConfirm', 'guideTapBoard', 'tutNext', 'tutStart']) rules.push(row(L[k], k));
  for (const [n, name] of W) {
    rules.push(row(`${n}. ${name} 규칙 본문 (게임 화면 ?·규칙 설명 1쪽). {0}=간식, {1}=최대 개수`, RULES[n - 1]));
    rules.push(row(`${n}. ${name} 규칙 설명 2쪽`, `rx_w${n}_1`));
    rules.push(row(`${n}. ${name} 규칙 설명 3쪽`, `rx_w${n}_2`));
    if (n === 4) for (let i = 1; i <= 4; i++) rules.push(row(`4. 막대과자 규칙 설명 ${i}쪽 (그림과 함께)`, `ri_w4_${i}`));
    rules.push(row(`${n}. ${name} 규칙 마지막 장: 이건 돼 (줄마다 하나씩)`, `dd_w${n}_ok`));
    rules.push(row(`${n}. ${name} 규칙 마지막 장: 이건 안 돼 (줄마다 하나씩)`, `dd_w${n}_no`));
  }
  for (const k of ['ruleIntroTitle', 'ruleIntroBack', 'ruleIntroStart', 'riLast', 'riTake', 'ddCaption', 'ddOk', 'ddNo', 'noteTitle', 'rulesTitle', 'howToPlay']) rules.push(row(L[k], k));
  // 4. 화면 글자 (나머지 설명 있는 키 전부)
  const ui = [];
  for (const k of Object.keys(L)) if (!used.has(k) && k in ko) ui.push(row(L[k], k));

  const head = ['상황', '게임 글 (여기만 고치기)', '키 (건드리지 않기)'];
  const widths = [46, 80, 22];
  const sheets = [
    { name: '안내', cols: ['방과후 님게임 — 게임 안 모든 글 (한국어)'], widths: [110], rows: [
      ['2열 "게임 글" 칸만 고치면 된다. 1열은 언제 나오는 글인지, 3열은 게임 연결용이라 그대로 둔다.'],
      ['{0} {1} 같은 괄호 숫자는 게임이 숫자나 간식 이름을 넣는 자리라 지우지 않는다.'],
      ['규칙 마지막 장(이건 돼/안 돼)은 칸 안에서 줄을 바꾸면 줄마다 한 항목이 된다.'],
      ['다 고치면 저장하고 "게임글 반영해 줘". 바뀐 줄만 다른 9개 언어로 다시 번역한다.'],
    ] },
    { name: '이야기', cols: head, widths, editCol: 1, rows: story },
    { name: '예린 대사', cols: head, widths, editCol: 1, rows: talk },
    { name: '튜토리얼·규칙', cols: head, widths, editCol: 1, rows: rules },
    { name: '화면 글자', cols: head, widths, editCol: 1, rows: ui },
  ];
  const tmp = path.join(__dirname, 'all_text_sheets.json');
  fs.writeFileSync(tmp, JSON.stringify(sheets), 'utf8');
  console.log(execFileSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', PS1, 'export', tmp, XLSX], { encoding: 'utf8' }).trim());
  console.log(`rows: 이야기 ${story.length}, 예린 대사 ${talk.length}, 튜토리얼·규칙 ${rules.length}, 화면 글자 ${ui.length}`);
}

function esc(v) { return v.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$').replace(/\n/g, '\\n'); }
function norm(v) { return String(v || '').replace(/\r/g, '').split('\n').map(x => x.replace(/[ \t]+/g, ' ').trim()).filter(Boolean).join('\n'); }

// 편집 페이지(NIM_게임글_전체_편집.html)에서 받은 {edits: {key: text}} → 엑셀과 같은 경로로 반영
function importJson(file) {
  const d = JSON.parse(fs.readFileSync(file, 'utf8'));
  const rows = [['상황', '글', '키'], ...Object.entries(d.edits || {}).map(([k, v]) => ['', v, k])];
  applyRows({ page: rows });
}

function importXlsx(file) {
  const xl = path.win32.normalize(file || XLSX);
  const json = path.join(__dirname, 'all_text_import.json');
  console.log(execFileSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', PS1, 'import', xl, json], { encoding: 'utf8' }).trim());
  applyRows(JSON.parse(fs.readFileSync(json, 'utf8')));
}

function applyRows(data) {
  const raw = fs.readFileSync(STRINGS, 'utf8');
  const crlf = raw.includes('\r\n');
  let src = raw.replace(/\r\n/g, '\n');
  const ko = readKo();
  const changed = [], noKey = [];
  for (const sheet of Object.keys(data)) {
    for (const r of (data[sheet] || []).slice(1)) {
      const key = String(r[2] || '').trim();
      const text = norm(r[1]);
      if (!key) { if (text) noKey.push(`${sheet}: ${text}`); continue; }
      if (!/^[A-Za-z0-9_]+$/.test(key) || !text || !(key in ko)) continue;
      if (norm(ko[key]) === text) continue;
      const re = new RegExp(`(^    '${key}': \\{\\n[\\s\\S]*?^      'ko': ')((?:[^'\\\\]|\\\\.)*)(',)`, 'm');
      if (!re.test(src)) continue;
      src = src.replace(re, (_, a, __, c) => a + esc(text) + c);
      changed.push(`${key}\t${text.replace(/\n/g, ' / ')}`);
    }
  }
  fs.writeFileSync(STRINGS, crlf ? src.replace(/\n/g, '\r\n') : src, 'utf8');
  fs.writeFileSync(CHANGED, changed.join('\n') + (changed.length ? '\n' : ''), 'utf8');
  console.log(`changed ${changed.length} → ${CHANGED}`);
  if (noKey.length) console.log('키 없는 새 줄 (수동 확인):\n' + noKey.join('\n'));
}

if (require.main === module) {
  const cmd = process.argv[2];
  if (cmd === 'export') exportXlsx();
  else if (cmd === 'import') importXlsx(process.argv[3]);
  else if (cmd === 'importjson') importJson(process.argv[3]);
  else console.log('usage: node tool/all_text.js export|import [xlsx]');
}
