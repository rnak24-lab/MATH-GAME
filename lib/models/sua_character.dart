/// 수아 캐릭터의 감정 상태
enum SuaEmotion {
  happy,     // 😊 행복
  confident, // 😏 자신
  neutral,   // 😐 보통
  worried,   // 😟 걱정
  sad,       // 😢 슬픔
  angry,     // 😠 화남
}

/// 수아 AI 캐릭터 시스템
class SuaCharacter {
  SuaEmotion emotion;

  SuaCharacter({this.emotion = SuaEmotion.neutral});

  String get emoji {
    switch (emotion) {
      case SuaEmotion.happy: return '😊';
      case SuaEmotion.confident: return '😏';
      case SuaEmotion.neutral: return '😐';
      case SuaEmotion.worried: return '😟';
      case SuaEmotion.sad: return '😢';
      case SuaEmotion.angry: return '😠';
    }
  }

  String get name => '수아';

  /// 게임 상황에 따른 감정 업데이트
  void updateEmotion({
    required bool isSuaTurn,
    required bool suaIsWinning,
    required bool isGameOver,
    required bool suaWon,
  }) {
    if (isGameOver) {
      emotion = suaWon ? SuaEmotion.happy : SuaEmotion.sad;
      return;
    }

    if (isSuaTurn) {
      emotion = suaIsWinning ? SuaEmotion.confident : SuaEmotion.worried;
    } else {
      emotion = suaIsWinning ? SuaEmotion.confident : SuaEmotion.neutral;
    }
  }

  /// 상황별 대사
  String getDialogue({
    required bool isSuaTurn,
    required bool suaIsWinning,
    required bool isGameOver,
    required bool suaWon,
    required bool isGameStart,
  }) {
    if (isGameStart) {
      return _randomPick([
        '안녕! 나는 수아야~ 같이 해보자! 🎀',
        '이번엔 내가 이길 거야!',
        '준비됐어? 시작하자~!',
      ]);
    }

    if (isGameOver) {
      if (suaWon) {
        return _randomPick([
          '헤헤~ 내가 이겼다! 😊',
          '다음엔 더 잘할 수 있을 거야!',
          '역시 수학은 재밌어~',
        ]);
      } else {
        return _randomPick([
          '으앙... 졌다... 😢',
          '다음엔 꼭 이길 거야!',
          '대단해! 어떻게 한 거야?',
        ]);
      }
    }

    if (isSuaTurn) {
      if (suaIsWinning) {
        return _randomPick([
          '후후~ 내 차례야! 😏',
          '이번 수가 중요해~',
          '잘 생각해볼게!',
        ]);
      } else {
        return _randomPick([
          '음... 어떻게 하지... 😟',
          '이거 좀 어려운데...',
          '잠깐만, 생각 중이야!',
        ]);
      }
    } else {
      if (suaIsWinning) {
        return _randomPick([
          '어디 한번 해봐~ 😏',
          '잘 생각해서 골라봐!',
          '쉽지 않을걸?',
        ]);
      } else {
        return _randomPick([
          '네 차례야! 잘 해봐~',
          '어떤 수를 둘 건지 궁금해!',
          '신중하게 골라봐!',
        ]);
      }
    }
  }

  String _randomPick(List<String> options) {
    options.shuffle();
    return options.first;
  }
}
