/// NIM GAME multi-language string definitions.
/// Default language: English. Supported: English, Korean.
class AppStrings {
  final String locale;
  AppStrings(this.locale);

  static final Map<String, Map<String, String>> _strings = {
    // ── App-wide ──
    'appTitle': {
      'en': 'Math NIM',
      'ko': 'Math NIM - 수학 님 게임',
    },
    'appSubtitle': {
      'en': 'Math NIM Strategy Game with Midnight',
      'ko': 'Midnight와 함께하는 수학 님 게임',
    },

    // ── Home Screen ──
    'mathNimSubtitle': {
      'en': 'Math NIM Game',
      'ko': '수학 님 게임',
    },
    'midnightGreeting': {
      'en': "Hi! I'm Midnight!",
      'ko': '안녕! 나는 Midnight야 🎀',
    },
    'continueGame': {
      'en': 'Continue',
      'ko': '이어하기',
    },
    'startGame': {
      'en': 'Start',
      'ko': '시작하기',
    },
    'selectStage': {
      'en': 'Select Stage',
      'ko': '스테이지 선택',
    },
    'startFromBeginning': {
      'en': 'Start from beginning',
      'ko': '처음부터 시작',
    },
    'clearProgress': {
      'en': 'Clear: {0}/100 Stages',
      'ko': 'Clear: {0}/100 Stages',
    },
    'settings': {
      'en': 'Settings',
      'ko': '설정',
    },
    'selectLanguage': {
      'en': 'Select Language',
      'ko': '언어 선택',
    },
    'selectLanguageDesc': {
      'en': 'Please choose your language.\nYou can change it later in Settings.',
      'ko': '사용할 언어를 선택해주세요.\n나중에 설정에서 변경할 수 있습니다.',
    },

    // ── World Select ──
    'worldSelect': {
      'en': 'Select World',
      'ko': '월드 선택',
    },
    'worldAlleyCorner': {
      'en': 'Alley Corner',
      'ko': 'Alley Corner',
    },
    'worldNeonTavern': {
      'en': 'Neon Tavern',
      'ko': 'Neon Tavern',
    },
    'worldSmokeDen': {
      'en': 'Smoke Den',
      'ko': 'Smoke Den',
    },
    'worldShadowMarket': {
      'en': 'Shadow Market',
      'ko': 'Shadow Market',
    },
    'worldTheLastBet': {
      'en': 'The Last Bet',
      'ko': 'The Last Bet',
    },
    'worldSubtitleSingleRow': {
      'en': 'Single Row NIM',
      'ko': '한 줄 님게임',
    },
    'worldSubtitleDoubleRow': {
      'en': 'Double Row NIM',
      'ko': '두 줄 님게임',
    },
    'worldSubtitlePepero': {
      'en': 'Pepero Game',
      'ko': '빼빼로 게임',
    },
    'worldSubtitleTripleRow': {
      'en': 'Triple Row NIM',
      'ko': '세 줄 님게임',
    },
    'worldSubtitleQuadRow': {
      'en': 'Quad Row NIM',
      'ko': '네 줄 님게임',
    },
    'worldSubtitleChallenge': {
      'en': 'Ultimate Challenge',
      'ko': '종합 도전',
    },
    'worldLocked': {
      'en': '???',
      'ko': '???',
    },
    'clearPreviousWorld': {
      'en': 'Clear the previous world',
      'ko': '이전 월드를 클리어하세요',
    },
    // (2026-07-02) 해금 조건: 이전 월드에서 3판 클리어 (빠른 패스)
    'unlockHint3Stages': {
      'en': 'Clear any 3 stages of the previous world to unlock',
      'ko': '앞 월드에서 3판만 깨면 열려요',
    },

    // ── Game Screen: Mode Titles ──
    'modeSingleRow': {
      'en': 'Single Row NIM',
      'ko': '한 줄 님게임',
    },
    'modeDoubleRow': {
      'en': 'Double Row NIM',
      'ko': '두 줄 님게임',
    },
    'modePepero': {
      'en': 'Pepero Game',
      'ko': '빼빼로 게임',
    },
    'modeTripleRow': {
      'en': 'Triple Row NIM',
      'ko': '세 줄 님게임',
    },
    'modeQuadRow': {
      'en': 'Quad Row NIM',
      'ko': '네 줄 님게임',
    },

    // ── Game Screen: Rules ──
    'ruleSingleRow': {
      'en': 'You can take 1~{0} stones.\nThe one who takes the last stone loses!',
      'ko': '돌을 1~{0}개 가져갈 수 있어요.\n마지막 돌을 가져가는 사람이 져요!',
    },
    'ruleDoubleRow': {
      'en': 'You can only take stones from one row.\nThe one who takes the last stone loses!',
      'ko': '한 줄에서만 돌을 가져갈 수 있어요.\n마지막 돌을 가져가는 사람이 져요!',
    },
    'rulePepero': {
      'en': "Split a pepero bundle into two.\nYou can't split into equal halves!\nThe one who can't split loses!",
      'ko': '빼빼로 묶음을 두 개로 나눠요.\n같은 수로는 나눌 수 없어요!\n더 나눌 수 없는 사람이 져요!',
    },
    'ruleTripleRow': {
      'en': 'You can only take stones from one row.\nThe one who takes the last stone loses!',
      'ko': '한 줄에서만 돌을 가져갈 수 있어요.\n마지막 돌을 가져가는 사람이 져요!',
    },
    'ruleQuadRow': {
      'en': 'Four rows of stones!\nYou can only take stones from one row.\nThe one who takes the last stone loses!',
      'ko': '네 줄의 돌이 있어요!\n한 줄에서만 돌을 가져갈 수 있어요.\n마지막 돌을 가져가는 사람이 져요!',
    },
    'initialState': {
      'en': 'Initial: {0}',
      'ko': '초기 상태: {0}',
    },

    // ── Game Screen: Turn ──
    'whoGoesFirst': {
      'en': 'Who goes first?',
      'ko': '누가 먼저 할까?',
    },
    'meFirst': {
      'en': 'Me first!',
      'ko': '내가 먼저!',
    },
    'midnightFirst': {
      'en': 'Midnight first!',
      'ko': 'Midnight 먼저!',
    },
    'myTurn': {
      'en': '🎯 My Turn',
      'ko': '🎯 내 턴',
    },
    'midnightTurn': {
      'en': "💭 Midnight's Turn...",
      'ko': '💭 Midnight 턴...',
    },
    'victory': {
      'en': '🎉 Victory!',
      'ko': '🎉 승리!',
    },
    // (귀여움 규칙 L2·M3) 패배는 침울 금지 — 재도전 프레임, 조용하게.
    'defeat': {
      'en': 'Almost!',
      'ko': '아깝다!',
    },

    // ── Game Screen: Actions ──
    'takeFromRow': {
      'en': 'Take from row {0}',
      'ko': '{0}번 줄에서 가져가기',
    },
    'takeCount': {
      'en': 'Number to take',
      'ko': '가져갈 개수',
    },
    'tapToSelect': {
      'en': 'Tap stones to pick',
      'ko': '돌을 탭해 선택',
    },

    // ── Game Screen: HUD 라벨 (한국어 완역, 2026-07-02) ──
    'stageLabel': {
      'en': 'STAGE {0}',
      'ko': '스테이지 {0}',
    },
    'logLabel': {
      'en': 'LOG',
      'ko': '기록',
    },
    'logFirst': {
      'en': 'FIRST · {0}',
      'ko': '선공 · {0}',
    },
    'movesCount': {
      'en': '{0} moves',
      'ko': '{0}수',
    },
    'nameYou': {
      'en': 'YOU',
      'ko': '나',
    },
    'nameMidnight': {
      'en': 'MIDNIGHT',
      'ko': '미드나잇',
    },
    'logStart': {
      'en': 'START · {0} first',
      'ko': '시작 · {0} 선공',
    },
    'caseLabel': {
      'en': 'CASE #{0}',
      'ko': '사건 #{0}',
    },
    'modeLabel': {
      'en': 'MODE',
      'ko': '모드',
    },
    'initLabel': {
      'en': 'INIT',
      'ko': '시작 배치',
    },

    // ── Settings: 게임플레이/초기화/규칙 (2026-07-02) ──
    'settingsGameplay': {
      'en': 'Gameplay',
      'ko': '게임',
    },
    'musicTitle': {
      'en': 'Background Music',
      'ko': '배경음악',
    },
    'musicDesc': {
      'en': 'Retro chiptune loop',
      'ko': '고전 게임풍 칩튠',
    },
    'hapticsTitle': {
      'en': 'Vibration',
      'ko': '진동 효과',
    },
    'hapticsDesc': {
      'en': 'Gentle vibration when picking stones',
      'ko': '돌을 집을 때 살짝 진동',
    },
    'howToPlay': {
      'en': 'How to Play',
      'ko': '게임 규칙',
    },
    'resetProgress': {
      'en': 'Reset Progress',
      'ko': '진행도 초기화',
    },
    'resetConfirmTitle': {
      'en': 'Reset all progress?',
      'ko': '모든 진행도를 초기화할까요?',
    },
    'resetConfirmBody': {
      'en': "All cleared stages will be locked again. This can't be undone.",
      'ko': '클리어 기록이 모두 사라져요. 되돌릴 수 없어요.',
    },
    'cancel': {
      'en': 'Cancel',
      'ko': '취소',
    },
    'resetDo': {
      'en': 'Reset',
      'ko': '초기화',
    },
    'resetDone': {
      'en': 'Progress has been reset.',
      'ko': '초기화 완료!',
    },
    'versionLabel': {
      'en': 'Version',
      'ko': '버전',
    },
    'takeNStones': {
      'en': 'Take {0}!',
      'ko': '{0}개 가져가기!',
    },
    'rowLabel': {
      'en': 'Row {0}',
      'ko': '{0}번 줄',
    },
    'peperoBundles': {
      'en': 'Pepero Bundles',
      'ko': '빼빼로 묶음',
    },
    'nPieces': {
      'en': '{0} pcs',
      'ko': '{0}개',
    },
    'split': {
      'en': 'Split',
      'ko': '나누기',
    },
    'splitAction': {
      'en': 'Split into {0} + {1}!',
      'ko': '{0} + {1}로 나누기!',
    },
    'selectSplittable': {
      'en': 'Select a bundle to split',
      'ko': '나눌 수 있는 묶음을 선택하세요',
    },

    // ── Game Screen: Result ──
    'stageClear': {
      'en': 'Stage Clear!',
      'ko': 'Stage Clear!',
    },
    'stageClearDesc': {
      'en': 'Stage {0} Cleared!',
      'ko': '스테이지 {0} 클리어!',
    },
    'nextStage': {
      'en': 'Next Stage',
      'ko': '다음 스테이지',
    },
    'backToStageSelect': {
      'en': 'Back to stage select',
      'ko': '스테이지 선택으로',
    },
    'retry': {
      'en': 'Retry',
      'ko': '다시하기',
    },
    'goBack': {
      'en': 'Go Back',
      'ko': '돌아가기',
    },

    // ── Midnight Messages: Greetings ──
    'greetReady': {
      'en': 'Stage {0}! Ready?',
      'ko': '스테이지 {0}! 준비됐어?',
    },
    // 톤: 승/패를 직접 말하지 않음. 웃음·놀림·장난기 위주.
    'greetWin': {
      'en': "Hehe, shall we play? 😼",
      'ko': '헤헤, 한판 놀아볼까? 😼',
    },
    'greetConfident': {
      'en': "Ooh, today feels fun~",
      'ko': '오늘은 왠지 재밌을 것 같은데~',
    },
    'greetLetsGo': {
      'en': "Let's have fun! 😸",
      'ko': '즐겁게 해보자냥~ 😸',
    },
    'turnPlayerFirst': {
      'en': 'Ooh, you first? Go on~',
      'ko': '오, 네가 먼저? 해봐~',
    },
    'turnMidnightFirst': {
      'en': "Hehe, me first then~ 😼",
      'ko': '헤헤, 내가 먼저 갈게~ 😼',
    },

    // ── Midnight Messages: 우위 상태 (놀리는/느긋한 느낌, 승패 직접 언급 X) ──
    'midnightWinLate1': {
      'en': "Hehe~ 😼",
      'ko': '헤헤~ 😼',
    },
    'midnightWinLate2': {
      'en': "Hmm-hmm~ 🎵",
      'ko': '흐음~ 🎵',
    },
    'midnightWinLate3': {
      'en': "Purr~ 😸",
      'ko': '냐하~ 😸',
    },
    'midnightWinEarly1': {
      'en': 'Interesting~',
      'ko': '재밌어지는걸~',
    },
    'midnightWinEarly2': {
      'en': "Hmm, let's see?",
      'ko': '흠, 어떻게 될까~?',
    },
    'midnightWinEarly3': {
      'en': 'Hehe 🐾',
      'ko': '헤헤 🐾',
    },

    // ── Midnight Messages: 열세 상태 (감탄/놀람, 패배 직접 언급 X) ──
    'midnightLoseLate1': {
      'en': "Oho? 😺",
      'ko': '오호? 😺',
    },
    'midnightLoseLate2': {
      'en': 'Wow, nice move~',
      'ko': '우와, 좋은 수인걸~',
    },
    'midnightLoseLate3': {
      'en': "Mrr... sneaky~",
      'ko': '므으... 얄밉네~',
    },
    'midnightLoseEarly1': {
      'en': 'Hmm, tricky~',
      'ko': '음, 까다로운걸~',
    },
    'midnightLoseEarly2': {
      'en': 'Oh? Let me think...',
      'ko': '어라? 생각 좀 해야겠어...',
    },
    'midnightLoseEarly3': {
      'en': 'Hmmm... 🤔',
      'ko': '흐으음... 🤔',
    },

    // ── Midnight Messages: AI moves ──
    'midnightTakeN': {
      'en': "I'll grab {0}~ 🐾",
      'ko': '{0}개 콕~ 🐾',
    },
    'midnightTakeFromRow': {
      'en': 'Row {1}, {0} pieces~ 🐾',
      'ko': '{1}번 줄에서 {0}개~ 🐾',
    },
    'midnightSplit': {
      'en': "Snap~ {0} and {1}! ✂️",
      'ko': '톡~ {0}과 {1}로! ✂️',
    },

    // ── Midnight Messages: AI turn animation ──
    'midnightThinking': {
      'en': "Hehe, let me think~ 😼",
      'ko': '헤헤, 뭘 가져갈까~ 😼',
    },
    'midnightTookTotal': {
      'en': 'Took {0}~ 🐾',
      'ko': '{0}개 가져갔지롱~ 🐾',
    },
    'midnightTookFromRowTotal': {
      'en': 'Row {1}, {0} pieces~ 🐾',
      'ko': '{1}번 줄에서 {0}개~ 🐾',
    },
    'yourTurnNow': {
      'en': 'Your turn~ 😸',
      'ko': '자, 네 차례~ 😸',
    },

    // ── Midnight Messages: Game Over (승/패 직접 언급 없이 톤만) ──
    'midnightLost': {
      'en': "Mrrr~ you got me this time! 🐾",
      'ko': '므으~ 이번엔 당했네! 🐾',
    },
    'midnightWon': {
      'en': 'Hehe~ that was fun! 😼',
      'ko': '헤헤~ 재밌었어! 😼',
    },
    'midnightNextTime': {
      'en': "Come play again~ 😸",
      'ko': '또 놀러 와~ 😸',
    },

    // ── Hints ── (😻 살짝 귀띔해주는 느낌)
    'hintPepero': {
      'en': '😻 Psst~ try splitting into {0} and {1}!',
      'ko': '😻 살짝 알려줄게~ {0}과 {1}로 나눠봐!',
    },
    'hintSingleRow': {
      'en': '😻 Psst~ try taking {0}!',
      'ko': '😻 살짝 알려줄게~ {0}개 가져가봐!',
    },
    'hintMultiRow': {
      'en': '😻 Psst~ try taking {0} from row {1}!',
      'ko': '😻 살짝 알려줄게~ {1}번 줄에서 {0}개!',
    },
    // (id=1201) nimSum=0 (이미 져버린 상태)에서 누르는 힌트: 다음 판 선공/후공 추천
    'hintLosingNextChoice': {
      'en': "😿 This round is mine already! Next time, pick '{0}' to win!",
      'ko': "😿 이번 판은 Midnight이 이기는 상태야. 다시 도전할 때 '{0}'를 선택하면 이길 수 있어!",
    },

    // ── Tutorial (예린 시나리오 W1~W5) ──
    'tutNext': {
      'en': 'Next',
      'ko': '다음',
    },
    'tutStart': {
      'en': 'Let\'s Start!',
      'ko': '시작하기!',
    },
    // W1: 기초 NIM
    'tutW1_1': {
      'en': "Hi! I'm Midnight. Let me show you this game!",
      'ko': '안녕! 나는 미드나잇. 이 게임을 알려줄게!',
    },
    'tutW1_2': {
      'en': "There are stones here. We take turns grabbing them.",
      'ko': '여기 돌이 있어. 우리가 번갈아 가져가는 거야.',
    },
    'tutW1_3': {
      'en': "You can take 1 or 2 stones at a time.",
      'ko': '한 번에 1개 또는 2개를 가져갈 수 있어.',
    },
    'tutW1_4': {
      'en': "If you grab the LAST stone... you lose! Be careful!",
      'ko': '마지막 돌을 가져가면... 지는 거야! 조심해!',
    },
    'tutW1_5': {
      'en': "One more thing — I can't hide my feelings. When I smirk, YOU are in trouble. Strike when my face turns worried!",
      'ko': '하나 더 — 난 표정을 못 숨겨. 내가 히죽거리면 네가 불리하다는 뜻! 내 표정이 굳는 순간을 노려!',
    },
    'tutW1_6': {
      'en': "It's your turn! How many will you take?",
      'ko': '네 차례야! 몇 개를 가져갈래?',
    },
    // W2: 2행 NIM
    'tutW2_1': {
      'en': "Now it's different! The stones are in two rows.",
      'ko': '이번엔 좀 달라! 돌이 두 줄로 나뉘어 있어.',
    },
    'tutW2_2': {
      'en': "You can only take from ONE row per turn.",
      'ko': '한 번에 한 줄에서만 가져갈 수 있어.',
    },
    'tutW2_3': {
      'en': "But within a row, take as many as you want!",
      'ko': '한 줄에서는 원하는 만큼 가져가도 돼!',
    },
    'tutW2_4': {
      'en': "Try tapping the top row first!",
      'ko': '위쪽 줄을 한번 눌러볼래?',
    },
    // W3: 세 줄 NIM (2026-07-02 월드 재배치)
    'tutW3_1': {
      'en': "Three rows now! Each has a different count.",
      'ko': '이제 세 줄이야! 줄마다 개수가 달라.',
    },
    'tutW3_2': {
      'en': "Same as before — one row per turn, as many as you want.",
      'ko': '규칙은 그대로 — 한 번에 한 줄에서만, 원하는 만큼!',
    },
    'tutW3_3': {
      'en': "Watch all three rows. The balance between them is the key.",
      'ko': '세 줄 전체를 봐. 줄 사이의 균형이 핵심이야.',
    },
    'tutW3_4': {
      'en': "Your turn! Which row and how many?",
      'ko': '이제 네 차례! 어떤 줄에서 몇 개?',
    },
    // W4: 네 줄 NIM (2026-07-02 월드 재배치)
    'tutW4_1': {
      'en': "Four rows! Now it's getting serious.",
      'ko': '네 줄이야! 슬슬 진지해지는걸.',
    },
    'tutW4_2': {
      'en': "Rules unchanged — one row per turn.",
      'ko': '규칙은 똑같아 — 한 번에 한 줄!',
    },
    'tutW4_3': {
      'en': "Tip: two rows with EQUAL counts cancel out. Find the odd ones!",
      'ko': '팁: 개수가 같은 두 줄은 서로 상쇄돼. 어긋난 줄을 찾아봐!',
    },
    'tutW4_4': {
      'en': "Where will you start?",
      'ko': '어디서 시작할래?',
    },
    // W5: 빼빼로(분할) — 최종 월드 (2026-07-02 월드 재배치)
    'tutW5_1': {
      'en': "Final world! The rule changes completely here.",
      'ko': '마지막 월드야! 여기선 규칙이 완전히 달라.',
    },
    'tutW5_2': {
      'en': "Don't take stones — SPLIT one bundle into two UNEQUAL parts.",
      'ko': '돌을 가져가는 게 아니야 — 한 묶음을 서로 \'다른\' 크기 둘로 쪼개!',
    },
    'tutW5_3': {
      'en': "If you can't split anything on your turn... you lose. I'm playing for real now!",
      'ko': '네 차례에 쪼갤 게 없으면… 지는 거야. 이번엔 나도 진심이야!',
    },
    // 2회 연속 패배 힌트
    'tutHintW1': {
      'en': "Hint: Don't be forced to take the last stone.",
      'ko': '힌트: 마지막 돌을 가져가지 않도록 해봐.',
    },
    'tutHintW2': {
      'en': "Hint: Try to leave rows with equal counts.",
      'ko': '힌트: 줄의 개수가 같게 남기도록 해봐.',
    },
    'tutHintW3': {
      'en': "Hint: two rows with equal counts cancel out — like mirrors.",
      'ko': '힌트: 개수가 같은 두 줄은 거울처럼 서로 지워져.',
    },
    'tutHintW4': {
      'en': "Hint: pair up equal rows first, then fix what's left.",
      'ko': '힌트: 같은 줄끼리 먼저 짝짓고, 남는 줄을 맞춰봐.',
    },
    'tutHintW5': {
      'en': "Hint: bundles of 1 or 2 can never be split.",
      'ko': '힌트: 1개나 2개짜리 묶음은 절대 못 쪼개.',
    },
    'tutHintGeneric': {
      'en': "Hint: Think about what you want to leave for your opponent.",
      'ko': '힌트: 상대에게 남길 돌을 먼저 생각해봐.',
    },

    // ── Settings ──
    'language': {
      'en': 'Language',
      'ko': '언어',
    },
    'english': {
      'en': 'English',
      'ko': 'English',
    },
    'korean': {
      'en': '한국어',
      'ko': '한국어',
    },
    'languageSettings': {
      'en': 'Languages',
      'ko': '언어 설정',
    },
    'privacyPolicy': {
      'en': 'Privacy Policy',
      'ko': '개인정보처리방침',
    },
    'aboutSettings': {
      'en': 'About',
      'ko': '정보',
    },
  };

  String get(String key, [List<String>? args]) {
    final map = _strings[key];
    if (map == null) return key;
    String text = map[locale] ?? map['en'] ?? key;
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        text = text.replaceAll('{$i}', args[i]);
      }
    }
    return text;
  }
}
