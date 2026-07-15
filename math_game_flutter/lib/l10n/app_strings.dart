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
      'en': 'Math NIM Strategy Game with Yerin',
      'ko': '예린이와 함께하는 수학 님 게임',
    },

    // ── Home Screen ──
    'mathNimSubtitle': {
      'en': 'Math NIM Game',
      'ko': '수학 님 게임',
    },
    'midnightGreeting': {
      'en': "Hi! I'm Yerin!",
      'ko': '안녕! 나는 예린이야 🎀',
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
      'en': 'Clear: {0}/80 Stages',
      'ko': 'Clear: {0}/80 Stages',
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
      'en':
          'Please choose your language.\nYou can change it later in Settings.',
      'ko': '사용할 언어를 선택해주세요.\n나중에 설정에서 변경할 수 있습니다.',
    },

    // ── World Select ──
    'worldSelect': {
      'en': 'Select World',
      'ko': '월드 선택',
    },
    'worldAlleyCorner': {
      'en': 'Alley Corner',
      'ko': '뒷골목 입구',
    },
    'worldNeonTavern': {
      'en': 'Neon Tavern',
      'ko': '네온 술집',
    },
    'worldSmokeDen': {
      'en': 'Smoke Den',
      'ko': '연기 아지트',
    },
    'worldShadowMarket': {
      'en': 'Shadow Market',
      'ko': '그림자 시장',
    },
    'worldTheLastBet': {
      'en': 'The Last Bet',
      'ko': '마지막 배팅',
    },
    // ── 🧪 테스트 월드 3종 ──
    'worldAlleyLanes': {
      'en': 'Alley Lanes',
      'ko': '골목 볼링장',
    },
    'worldGoldenScale': {
      'en': 'Golden Scale',
      'ko': '황금 저울',
    },
    'worldRabbitHole': {
      'en': 'Rabbit Hole',
      'ko': '토끼 굴',
    },
    'worldSubtitleKayles': {
      'en': 'Kayles · TEST',
      'ko': '카일즈 · 테스트',
    },
    'worldSubtitleWythoff': {
      'en': 'Wythoff · TEST',
      'ko': '위토프 · 테스트',
    },
    'worldSubtitleFibonacci': {
      'en': 'Fibonacci NIM · TEST',
      'ko': '피보나치 님 · 테스트',
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
    // (2026-07-02) 해금 조건 — 게임식 표기: "1-3 클리어 시 해금!" ({0}=이전 월드 번호)
    'unlockHint3Stages': {
      'en': 'Clear {0}-3 to unlock!',
      'ko': '{0}-3 클리어 시 해금!',
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
    'modeKayles': {
      'en': 'Kayles',
      'ko': '카일즈',
    },
    'modeWythoff': {
      'en': 'Wythoff',
      'ko': '위토프',
    },
    'modeFibonacci': {
      'en': 'Fibonacci NIM',
      'ko': '피보나치 님',
    },

    // ── Game Screen: Rules ──
    'ruleSingleRow': {
      'en':
          'You can take 1~{0} stones.\nThe one who takes the last stone loses!',
      'ko': '돌을 1~{0}개 가져갈 수 있어요.\n마지막 돌을 가져가는 사람이 져요!',
    },
    'ruleDoubleRow': {
      'en':
          'You can only take stones from one row.\nThe one who takes the last stone loses!',
      'ko': '한 줄에서만 돌을 가져갈 수 있어요.\n마지막 돌을 가져가는 사람이 져요!',
    },
    'rulePepero': {
      'en':
          "Split a pepero bundle into two.\nYou can't split into equal halves!\nThe one who can't split loses!",
      'ko': '빼빼로 묶음을 두 개로 나눠요.\n같은 수로는 나눌 수 없어요!\n더 나눌 수 없는 사람이 져요!',
    },
    'ruleTripleRow': {
      'en':
          'You can only take stones from one row.\nThe one who takes the last stone loses!',
      'ko': '한 줄에서만 돌을 가져갈 수 있어요.\n마지막 돌을 가져가는 사람이 져요!',
    },
    'ruleQuadRow': {
      'en':
          'Four rows of stones!\nYou can only take stones from one row.\nThe one who takes the last stone loses!',
      'ko': '네 줄의 돌이 있어요!\n한 줄에서만 돌을 가져갈 수 있어요.\n마지막 돌을 가져가는 사람이 져요!',
    },
    'ruleKayles': {
      'en':
          'Take 1 or 2 ADJACENT stones from anywhere.\nTaking from the middle splits the row in two!\nThe one who takes the LAST stone WINS!',
      'ko':
          '아무 위치에서나 붙어있는 돌을 1~2개 가져가요.\n가운데를 빼면 줄이 두 동강 나요!\n마지막 돌을 가져가는 사람이 이겨요!',
    },
    'ruleWythoff': {
      'en':
          'Two piles. Take any amount from ONE pile,\nor the SAME amount from BOTH.\nThe one who takes the LAST stone WINS!',
      'ko':
          '무더기가 두 개! 한쪽에서 원하는 만큼 가져가거나,\n양쪽에서 똑같은 개수를 가져가요.\n마지막 돌을 가져가는 사람이 이겨요!',
    },
    'ruleFibonacci': {
      'en':
          "First move: you can't take everything.\nAfter that: up to DOUBLE what your opponent just took.\nThe one who takes the LAST stone WINS!",
      'ko':
          '첫 수엔 전부 가져가기 금지!\n그 다음부턴 상대가 방금 가져간 개수의 2배까지.\n마지막 돌을 가져가는 사람이 이겨요!',
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
      'en': 'Yerin first!',
      'ko': '예린이 먼저!',
    },
    'myTurn': {
      'en': '🎯 My Turn',
      'ko': '🎯 내 턴',
    },
    'midnightTurn': {
      'en': "💭 Yerin's Turn...",
      'ko': '💭 예린이 턴...',
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
    'tapToSelectCta': {
      'en': 'Tap a stone to pick!',
      'ko': '돌을 눌러 골라봐!',
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
      'en': 'YERIN',
      'ko': '예린',
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
    // 인게임 정보 칩 — 항상 보이는 숫자 정보 (줄글 규칙 대체)
    'stonesLeft': {
      'en': 'Stones {0}',
      'ko': '남은 돌 {0}',
    },
    'takeRange': {
      'en': 'Take 1~{0}',
      'ko': '한 번에 1~{0}개',
    },
    'takeAny': {
      'en': 'Take any amount',
      'ko': '원하는 만큼',
    },
    'peperoChip': {
      'en': 'Split in two',
      'ko': '둘로 쪼개기',
    },
    'peperoNoEqualChip': {
      'en': 'No equal halves',
      'ko': '같은 개수 ❌',
    },
    'peperoTapBundle': {
      'en': 'Tap a bundle to pick it up!',
      'ko': '쪼갤 묶음을 눌러 골라봐!',
    },
    'peperoTapStick': {
      'en': 'Tap a stick to move the break line!',
      'ko': '막대를 누르면 쪼갤 위치가 바뀌어!',
    },
    'peperoNoEqual': {
      'en': "Equal halves not allowed! Make one side bigger.",
      'ko': '같은 개수로는 못 쪼개! 한쪽을 더 크게~',
    },
    'peperoDeadTray': {
      'en': 'Too small to split',
      'ko': '더 못 쪼개는 조각',
    },
    // ── 🧪 테스트 모드 칩/안내 ──
    'lastStoneWinChip': {
      'en': 'Last stone WINS',
      'ko': '마지막 돌 = 승리!',
    },
    'kaylesChip': {
      'en': 'Adjacent 1~2',
      'ko': '붙어있는 1~2개',
    },
    'wythoffChip': {
      'en': 'One pile · or both equally',
      'ko': '한 줄 맘껏 · 양쪽 같이',
    },
    'kaylesTapCta': {
      'en': 'Tap any stone — grab its neighbor too!',
      'ko': '아무 돌이나 눌러봐! 옆 돌도 이어서 잡을 수 있어',
    },
    'wythoffInvalid': {
      'en': 'One pile only — or BOTH equally!',
      'ko': '한 줄에서만! 아니면 양쪽 똑같이!',
    },
    'midnightTookBoth': {
      'en': 'Took {0} from both piles!',
      'ko': '양쪽에서 {0}개씩 가져갔어!',
    },
    // ── 힌트 = 광고 보고 보기 ──
    'hintDialogTitle': {
      'en': 'See a hint!',
      'ko': '힌트 보기!',
    },
    'hintDialogBody': {
      'en':
          "Watch an ad and Yerin will whisper a move~ ✏️\n(Hints left: {0})",
      'ko': '광고를 보면 예린이가 수를 살짝 알려줄게~ ✏️\n(남은 힌트: {0}개)',
    },
    'hintWatchAd': {
      'en': 'Watch ad & see hint',
      'ko': '광고 보고 힌트 보기',
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
    'sfxTitle': {
      'en': 'Sound Effects',
      'ko': '효과음',
    },
    'sfxDesc': {
      'en': 'Swoosh when stones are taken',
      'ko': '돌 가져갈 때 슉!',
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
      'en': "Hehe, shall we play? 😝",
      'ko': '후후, 한판 붙어볼래? 😝',
    },
    'greetConfident': {
      'en': "Ooh, today feels fun~",
      'ko': '오늘 왠지 느낌 좋단 말이지~',
    },
    'greetLetsGo': {
      'en': "Let's have fun! ✌️",
      'ko': '재밌게 해보자구~ ✌️',
    },
    'turnPlayerFirst': {
      'en': 'Ooh, you first? Go on~',
      'ko': '오~ 네가 먼저? 어디 해봐~',
    },
    'turnMidnightFirst': {
      'en': "Hehe, me first then~ 😏",
      'ko': '후후, 그럼 내가 먼저 간다? 😏',
    },

    // ── Midnight Messages: 우위 상태 (놀리는/느긋한 느낌, 승패 직접 언급 X) ──
    'midnightWinLate1': {
      'en': "Hehe~ 😏",
      'ko': '후후~ 😏',
    },
    'midnightWinLate2': {
      'en': "Hmm-hmm~ 🎵",
      'ko': '콧노래 나온다~ 🎵',
    },
    'midnightWinLate3': {
      'en': "Yay~ ✨",
      'ko': '아싸~ ✨',
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
      'en': 'Hehe ✌️',
      'ko': '헤헤 ✌️',
    },

    // ── Midnight Messages: 열세 상태 (감탄/놀람, 패배 직접 언급 X) ──
    'midnightLoseLate1': {
      'en': "Huh?! 😳",
      'ko': '어?! 😳',
    },
    'midnightLoseLate2': {
      'en': 'Wow, nice move~',
      'ko': '헐, 방금 뭐야~ 좀 치는데?',
    },
    'midnightLoseLate3': {
      'en': "Hey... that's sneaky~ 💢",
      'ko': '아 뭐야... 얄미워~ 💢',
    },
    'midnightLoseEarly1': {
      'en': 'Hmm, tricky~',
      'ko': '음, 이거 은근 까다롭네~',
    },
    'midnightLoseEarly2': {
      'en': 'Oh? Let me think...',
      'ko': '잠깐, 생각 좀 할게...',
    },
    'midnightLoseEarly3': {
      'en': 'Hmmm... 🤔',
      'ko': '흐으음... 🤔',
    },

    // ── Midnight Messages: AI moves ──
    'midnightTakeN': {
      'en': "I'll grab {0}~ ✏️",
      'ko': '{0}개 콕~ ✏️',
    },
    'midnightTakeFromRow': {
      'en': 'Row {1}, {0} pieces~ ✏️',
      'ko': '{1}번 줄에서 {0}개~ ✏️',
    },
    'midnightSplit': {
      'en': "Snap~ {0} and {1}! ✂️",
      'ko': '톡~ {0}과 {1}로! ✂️',
    },

    // ── Midnight Messages: AI turn animation ──
    'midnightThinking': {
      'en': "Hmm, let me think~ 🤔",
      'ko': '음~ 뭘 가져갈까나~ 🤔',
    },
    'midnightTookTotal': {
      'en': 'Took {0}~ 😝',
      'ko': '{0}개 가져갔지롱~ 😝',
    },
    'midnightTookFromRowTotal': {
      'en': 'Row {1}, {0} pieces~ ✏️',
      'ko': '{1}번 줄에서 {0}개~ ✏️',
    },
    'yourTurnNow': {
      'en': 'Your turn~ 😊',
      'ko': '자, 네 차례야~ 😊',
    },

    // ── Midnight Messages: Game Over (승/패 직접 언급 없이 톤만) ──
    'midnightLost': {
      'en': "What?! You got me this time! 😳",
      'ko': '아 뭐야~ 이번엔 내가 당했잖아! 😳',
    },
    'midnightWon': {
      'en': 'Hehe~ that was fun! 😝',
      'ko': '후후~ 재밌었어! 😝',
    },
    'midnightNextTime': {
      'en': "Come challenge me again~ 📚",
      'ko': '또 도전하러 와~ 📚',
    },

    // ── Hints ── (🤫 살짝 귀띔해주는 느낌)
    'hintPepero': {
      'en': '🤫 Psst~ try splitting into {0} and {1}!',
      'ko': '🤫 살짝 알려줄게~ {0}과 {1}로 나눠봐!',
    },
    'hintSingleRow': {
      'en': '🤫 Psst~ try taking {0}!',
      'ko': '🤫 살짝 알려줄게~ {0}개 가져가봐!',
    },
    'hintMultiRow': {
      'en': '🤫 Psst~ try taking {0} from row {1}!',
      'ko': '🤫 살짝 알려줄게~ {1}번 줄에서 {0}개!',
    },
    // (id=1201) nimSum=0 (이미 져버린 상태)에서 누르는 힌트: 다음 판 선공/후공 추천
    'hintLosingNextChoice': {
      'en': "😥 This round is mine already! Next time, pick '{0}' to win!",
      'ko': "😥 이번 판은 예린이가 이기는 상태야. 다시 도전할 때 '{0}'를 선택하면 이길 수 있어!",
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
    // W1: 기초 NIM — 짧고 액션 지시형 (줄글 설명 금지, 따라 하면 무조건 승리)
    'tutW1_1': {
      'en': "Hi! I'm Yerin. Let's just play!",
      'ko': '안녕! 나는 예린! 바로 해보자~',
    },
    'tutW1_2': {
      'en': 'Tap a stone to grab it. Tap again to put it back.',
      'ko': '돌을 누르면 집고, 다시 누르면 내려놔.',
    },
    'tutW1_3': {
      'en': 'Grab the LAST stone and you lose!',
      'ko': '마지막 돌을 가져가면 지는 거야!',
    },
    'tutW1_4': {
      'en': 'Now grab 2 stones and hit Take!',
      'ko': '자! 돌 2개를 집고, 가져가기를 눌러봐!',
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
      'en':
          "If you can't split anything on your turn... you lose. I'm playing for real now!",
      'ko': '네 차례에 쪼갤 게 없으면… 지는 거야. 이번엔 나도 진심이야!',
    },
    // 🧪 카일즈 튜토리얼
    'tutW6_1': {
      'en': 'Alley Lanes! Take 1 or 2 stones from ANYWHERE in a row.',
      'ko': '골목 볼링장! 이번엔 아무 위치의 돌이나 가져갈 수 있어.',
    },
    'tutW6_2': {
      'en':
          'Two stones must be side by side. Take from the middle — the row SPLITS!',
      'ko': '2개를 잡으려면 붙어있어야 해. 가운데를 빼면 줄이 두 동강!',
    },
    'tutW6_3': {
      'en': 'And here... the one who takes the LAST stone WINS!',
      'ko': '그리고 여기선… 마지막 돌을 가져가는 사람이 이겨!',
    },
    // 🧪 위토프 튜토리얼
    'tutW7_1': {
      'en': 'Golden Scale! Two piles. Take as many as you want from ONE.',
      'ko': '황금 저울! 무더기 두 개. 한쪽에서 마음껏 가져가.',
    },
    'tutW7_2': {
      'en': 'Or take the SAME amount from BOTH piles at once!',
      'ko': '아니면 양쪽에서 똑같은 개수를 한번에!',
    },
    'tutW7_3': {
      'en': 'The one who takes the LAST stone WINS. Balance carefully~',
      'ko': '마지막 돌을 가져가면 승리야. 저울을 잘 맞춰봐~',
    },
    // 🧪 피보나치 튜토리얼
    'tutW8_1': {
      'en': "Rabbit Hole rule: first move, you CAN'T take them all!",
      'ko': '토끼 굴 규칙: 첫 수엔 전부 가져가기 금지!',
    },
    'tutW8_2': {
      'en': 'After that: up to DOUBLE what I just took. Watch the chip!',
      'ko': '그 다음부턴 내가 방금 가져간 개수의 2배까지만. 칩을 잘 봐!',
    },
    'tutW8_3': {
      'en': 'Take the LAST stone to WIN. Hop hop~',
      'ko': '마지막 돌을 가져가면 승리! 깡총깡총~',
    },
    // 2회 연속 패배 힌트
    'tutHintW1': {
      'en': 'Hint: grab 2 stones and you win!',
      'ko': '힌트: 2개를 집으면 이겨!',
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
