import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/dialogue.dart';
import '../utils/nim_theme.dart';

/// 미연시식 대화 상자 — 화면 아래에 뜬다. 왼쪽 위에 화자 이름표([예린]/[나]),
/// 한 글자씩 타이핑되고, 탭하면 다 보여주기 → 다음 줄. 마지막 줄에서 탭하면 [onDone].
/// 표정·화자는 [onLine] 으로 바깥(큰 예린)에 넘긴다 — 화면에 예린은 항상 한 명.
class DialogueBox extends StatefulWidget {
  final List<DialogueLine> lines;
  final String yerinName;
  final String meName;
  final String? title; // 장면 제목 (오른쪽 위 작게)
  final void Function(DialogueLine line) onLine;
  final VoidCallback onDone;

  const DialogueBox({
    super.key,
    required this.lines,
    required this.yerinName,
    required this.meName,
    required this.onLine,
    required this.onDone,
    this.title,
  });

  @override
  State<DialogueBox> createState() => DialogueBoxState();
}

class DialogueBoxState extends State<DialogueBox> {
  int _index = 0;
  int _shown = 0; // 타이핑된 글자 수
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startLine();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DialogueLine get _line => widget.lines[_index];
  String get _text => _line.text;
  bool get _complete => _shown >= _text.length;

  void _startLine() {
    _timer?.cancel();
    _shown = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLine(_line);
    });
    _timer = Timer.periodic(const Duration(milliseconds: 28), (t) {
      if (!mounted) return;
      setState(() => _shown++);
      if (_complete) t.cancel();
    });
  }

  /// 바깥(전체 화면 탭)에서도 부를 수 있게 공개.
  void tap() {
    if (!_complete) {
      _timer?.cancel();
      setState(() => _shown = _text.length);
      return;
    }
    if (_index + 1 >= widget.lines.length) {
      widget.onDone();
      return;
    }
    setState(() => _index++);
    _startLine();
  }

  @override
  Widget build(BuildContext context) {
    final bool last = _index + 1 >= widget.lines.length;
    final bool me = _line.speaker == Speaker.me;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xF2241F18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: me ? NimTheme.cream : NimTheme.gold, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 화자 이름표 — 왼쪽 위
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: me ? NimTheme.cream : NimTheme.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    me ? widget.meName : widget.yerinName,
                    style: const TextStyle(
                      fontFamily: NimTheme.font,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: NimTheme.deskBottom,
                    ),
                  ),
                ),
                if (widget.title != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: NimTheme.font,
                        fontSize: 12,
                        color: NimTheme.cream.withOpacity(0.7),
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                Text(
                  '${_index + 1}/${widget.lines.length}',
                  style: TextStyle(
                    fontFamily: NimTheme.font,
                    fontSize: 11,
                    color: NimTheme.cream.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Text(
                _text.substring(0, _shown.clamp(0, _text.length)),
                style: const TextStyle(
                  fontFamily: NimTheme.font,
                  fontSize: 16,
                  height: 1.5,
                  color: NimTheme.cream,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _complete ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  last ? Icons.check_rounded : Icons.arrow_drop_down_rounded,
                  color: NimTheme.gold,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
