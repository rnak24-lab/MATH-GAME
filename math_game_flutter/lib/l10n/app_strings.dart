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
    'defeat': {
      'en': '😢 Defeat...',
      'ko': '😢 패배...',
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
    'greetWin': {
      'en': "I'll win this time~",
      'ko': '이번엔 내가 이길 거야~',
    },
    'greetConfident': {
      'en': "Hmph, I'm confident this round!",
      'ko': '흥, 이번 판은 자신있어!',
    },
    'greetLetsGo': {
      'en': "Let's go! 😊",
      'ko': '한번 해볼까? 😊',
    },
    'turnPlayerFirst': {
      'en': 'OK, you go first!',
      'ko': '좋아, 네가 먼저 해!',
    },
    'turnMidnightFirst': {
      'en': "I'll go first~",
      'ko': '내가 먼저 할게~',
    },

    // ── Midnight Messages: AI winning ──
    'midnightWinLate1': {
      'en': "Hehe, looks like I'll win~",
      'ko': '후후, 이대로면 내가 이길 것 같아~',
    },
    'midnightWinLate2': {
      'en': 'Almost there! 😆',
      'ko': '거의 다 됐어! 😆',
    },
    'midnightWinLate3': {
      'en': "It's my victory!",
      'ko': '이번엔 내 승리!',
    },
    'midnightWinEarly1': {
      'en': 'Good start~',
      'ko': '좋은 흐름이야~',
    },
    'midnightWinEarly2': {
      'en': "Not bad so far?",
      'ko': '이 정도면 괜찮은데?',
    },
    'midnightWinEarly3': {
      'en': 'Hehe, feeling confident!',
      'ko': '흐흐, 자신있어!',
    },

    // ── Midnight Messages: AI losing ──
    'midnightLoseLate1': {
      'en': "Ugh... this isn't good...",
      'ko': '으으... 이러면 안되는데...',
    },
    'midnightLoseLate2': {
      'en': 'What should I do... 😰',
      'ko': '어떡하지... 😰',
    },
    'midnightLoseLate3': {
      'en': "Ahh, I'm losing...!",
      'ko': '아앗, 불리해...!',
    },
    'midnightLoseEarly1': {
      'en': 'Hmm... this is tricky...',
      'ko': '음... 좀 어렵네...',
    },
    'midnightLoseEarly2': {
      'en': 'This one needs thinking...',
      'ko': '이건 좀 고민되는데...',
    },
    'midnightLoseEarly3': {
      'en': 'Hmm...',
      'ko': '흐음...',
    },

    // ── Midnight Messages: AI moves ──
    'midnightTakeN': {
      'en': "I'll take {0}~",
      'ko': '{0}개 가져갈게~',
    },
    'midnightTakeFromRow': {
      'en': '{0} from row {1}!',
      'ko': '{1}번 줄에서 {0}개!',
    },
    'midnightSplit': {
      'en': "I'll split into {0} and {1}!",
      'ko': '{0}과 {1}로 나눌게!',
    },

    // ── Midnight Messages: AI turn animation ──
    'midnightThinking': {
      'en': "Midnight's turn...",
      'ko': 'Midnight의 차례...',
    },
    'midnightTookTotal': {
      'en': 'Midnight took {0}!',
      'ko': 'Midnight이 {0}개 가져갔어!',
    },
    'midnightTookFromRowTotal': {
      'en': 'Midnight took {0} from row {1}!',
      'ko': 'Midnight이 {1}번 줄에서 {0}개 가져갔어!',
    },
    'yourTurnNow': {
      'en': 'Your turn!',
      'ko': '당신의 차례!',
    },

    // ── Midnight Messages: Game Over ──
    'midnightLost': {
      'en': "Ugh... I lost... I'll win next time!",
      'ko': '으으... 졌어... 다음엔 꼭 이길 거야!',
    },
    'midnightWon': {
      'en': 'Yay~! I won! 🎉',
      'ko': '야호~! 내가 이겼다! 🎉',
    },
    'midnightNextTime': {
      'en': "Ugh... I'll get you next time!",
      'ko': '으으... 다음엔 안 질 거야!',
    },

    // ── Hints ──
    'hintPepero': {
      'en': '💡 Try splitting into {0} and {1}!',
      'ko': '💡 {0}과 {1}로 나눠보세요!',
    },
    'hintSingleRow': {
      'en': '💡 Try taking {0}!',
      'ko': '💡 {0}개를 가져가보세요!',
    },
    'hintMultiRow': {
      'en': '💡 Try taking {0} from row {1}!',
      'ko': '💡 {1}번 줄에서 {0}개를 가져가보세요!',
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
