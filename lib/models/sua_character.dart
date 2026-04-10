/// 깜냥이(나이트) 캐릭터의 감정 상태
enum NightEmotion {
  smirk,      // 😏 교활한 미소 (자신있을 때)
  confident,  // 🃏 카드 굴리며 여유
  neutral,    // 🎩 중절모 아래 무표정
  thinking,   // 🤔 칩 굴리며 고민
  surprised,  // 😾 놀란 표정
  defeated,   // 😿 모자로 얼굴 가림
}

/// 깜냥이(나이트) - 어둠 속 프로 도박꾼 고양이
class SuaCharacter {
  NightEmotion emotion;

  SuaCharacter({this.emotion = NightEmotion.neutral});

  String get emoji {
    switch (emotion) {
      case NightEmotion.smirk: return '😏';
      case NightEmotion.confident: return '🃏';
      case NightEmotion.neutral: return '🎩';
      case NightEmotion.thinking: return '🤔';
      case NightEmotion.surprised: return '😾';
      case NightEmotion.defeated: return '😿';
    }
  }

  String get name => '깜냥이';

  /// 게임 상황에 따른 감정 업데이트
  void updateEmotion({
    required bool isSuaTurn,
    required bool suaIsWinning,
    required bool isGameOver,
    required bool suaWon,
  }) {
    if (isGameOver) {
      emotion = suaWon ? NightEmotion.smirk : NightEmotion.defeated;
      return;
    }

    if (isSuaTurn) {
      emotion = suaIsWinning ? NightEmotion.confident : NightEmotion.thinking;
    } else {
      emotion = suaIsWinning ? NightEmotion.smirk : NightEmotion.neutral;
    }
  }

  /// 상황별 대사 (도박꾼 톤)
  String getDialogue({
    required bool isSuaTurn,
    required bool suaIsWinning,
    required bool isGameOver,
    required bool suaWon,
    required bool isGameStart,
  }) {
    if (isGameStart) {
      return _randomPick([
        '...자리에 앉아. 판을 시작하지. 🎩',
        '오늘 밤, 운이 좋길 빌어.',
        '칩을 올려. 게임 시작이야.',
      ]);
    }

    if (isGameOver) {
      if (suaWon) {
        return _randomPick([
          '훌륭한 판이었어... 내 쪽으로 기울었지만. 😏',
          '다음엔 좀 더 신중하게 배팅해.',
          '이 골목에서 나를 이기긴 쉽지 않지.',
        ]);
      } else {
        return _randomPick([
          '...흥. 이번엔 네가 이겼군. 😿',
          '다음 판에서 되찾아주지.',
          '인정하마. 꽤 하는데.',
        ]);
      }
    }

    if (isSuaTurn) {
      if (suaIsWinning) {
        return _randomPick([
          '후... 이 수는 읽히는군. 🃏',
          '슬슬 끝을 보자.',
          '내 차례다. 지켜봐.',
        ]);
      } else {
        return _randomPick([
          '...잠깐. 생각 좀 하자. 🤔',
          '이거 좀 까다로운데...',
          '서두르면 지는 법이야.',
        ]);
      }
    } else {
      if (suaIsWinning) {
        return _randomPick([
          '어디 한번 둬봐. 😏',
          '네 수를 기다리고 있어.',
          '신중하게... 아니면 끝이야.',
        ]);
      } else {
        return _randomPick([
          '네 차례야. 잘 골라.',
          '이 판, 아직 모르는 거야.',
          '한 수 한 수가 중요해.',
        ]);
      }
    }
  }

  String _randomPick(List<String> options) {
    options.shuffle();
    return options.first;
  }
}
