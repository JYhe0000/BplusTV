import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'dart:math' as math;

/// A 3x4 T9 keypad with index based navigation so a TV remote can always
/// operate it. Repeatedly activating the same key cycles through its
/// characters (classic multi-tap).
class T9Keyboard extends StatefulWidget {
  const T9Keyboard({
    super.key,
    required this.onChanged,
    this.onSubmit,
    this.initialText = '',
    this.autofocus = true,
    this.focusNode,
    this.onExitLeft,
    this.onExitRight,
    this.onExitUp,
    this.onExitDown,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmit;
  final String initialText;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Called when the D-pad moves past the corresponding edge, so the host can
  /// hand focus to a neighbouring widget.
  final VoidCallback? onExitLeft;
  final VoidCallback? onExitRight;
  final VoidCallback? onExitUp;
  final VoidCallback? onExitDown;

  @override
  State<T9Keyboard> createState() => _T9KeyboardState();
}

class _T9KeyboardState extends State<T9Keyboard> {
  static const Map<String, List<String>> _groups = {
    '1': ['1', '.', ',', '?', '!'],
    '2': ['a', 'b', 'c', '2'],
    '3': ['d', 'e', 'f', '3'],
    '4': ['g', 'h', 'i', '4'],
    '5': ['j', 'k', 'l', '5'],
    '6': ['m', 'n', 'o', '6'],
    '7': ['p', 'q', 'r', 's', '7'],
    '8': ['t', 'u', 'v', '8'],
    '9': ['w', 'x', 'y', 'z', '9'],
    '0': ['0', ' '],
  };

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['del', '0', 'search'],
  ];

  late final FocusNode _focusNode =
      widget.focusNode ?? FocusNode(debugLabel: 'T9Keyboard');
  int _row = 1;
  int _col = 1;
  final ScrollController _scrollController = ScrollController();
  double _keyHeight = 56;
  double _gap = 8;

  late String _text = widget.initialText;
  String? _lastKey;
  int _lastIndex = 0;
  DateTime _lastPress = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _cycleWindow = Duration(milliseconds: 1200);

  @override
  void didUpdateWidget(covariant T9Keyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText != _text) {
      _text = widget.initialText;
      _lastKey = null;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _pressKey(String key) {
    if (key == 'del') {
      _delete();
      return;
    }
    if (key == 'search') {
      _submit();
      return;
    }
    final group = _groups[key];
    if (group == null) return;
    final now = DateTime.now();
    // Multi-tap: only treat this as a cycle when the previous character was
    // produced by the same key. `_text` can be replaced from outside
    // (initialText sync, or a resolved Chinese keyword), so never assume the
    // last character belongs to this key.
    final prevChar = _text.isEmpty ? '' : _text.substring(_text.length - 1);
    final cycling =
        _lastKey == key &&
        prevChar.isNotEmpty &&
        group.contains(prevChar) &&
        now.difference(_lastPress) < _cycleWindow;
    if (cycling) {
      _lastIndex = (_lastIndex + 1) % group.length;
      _text = _replaceLastChar(_text, group[_lastIndex]);
    } else {
      _lastIndex = 0;
      _text += group[0];
    }
    _lastKey = key;
    _lastPress = now;
    _notify();
  }

  /// Replaces the last character of [value] without splitting a surrogate
  /// pair (a trailing lone low surrogate would make `substring` throw).
  static String _replaceLastChar(String value, String next) =>
      _dropLastChar(value) + next;

  /// Drops the last character of [value], keeping surrogate pairs intact.
  static String _dropLastChar(String value) {
    if (value.isEmpty) return value;
    final units = value.codeUnits;
    var cut = units.length - 1;
    if (cut > 0 &&
        _isLowSurrogate(units[cut]) &&
        _isHighSurrogate(units[cut - 1])) {
      cut--;
    }
    return String.fromCharCodes(units.sublist(0, cut));
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  static bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

  void _delete() {
    _lastKey = null;
    if (_text.isNotEmpty) {
      _text = _dropLastChar(_text);
      _notify();
    }
  }

  void _submit() {
    final keyword = _text.trim();
    if (keyword.isNotEmpty) {
      widget.onSubmit?.call(keyword);
    }
  }

  void _notify() {
    setState(() {});
    widget.onChanged(_text);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (_col == 0) {
          widget.onExitLeft?.call();
        } else {
          setState(() => _col--);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (_col >= _rows[_row].length - 1) {
          widget.onExitRight?.call();
        } else {
          setState(() => _col++);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (_row == 0) {
          widget.onExitUp?.call();
        } else {
          setState(() {
            _row--;
            _col = _col.clamp(0, _rows[_row].length - 1);
          });
          _revealRow();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_row >= _rows.length - 1) {
          widget.onExitDown?.call();
        } else {
          setState(() {
            _row++;
            _col = _col.clamp(0, _rows[_row].length - 1);
          });
          _revealRow();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.gameButtonA:
        if (event is KeyRepeatEvent) return KeyEventResult.handled;
        _pressKey(_rows[_row][_col]);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _revealRow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final rowTop = _row * (_keyHeight + _gap);
      final viewport = _scrollController.position.viewportDimension;
      final current = _scrollController.offset;
      final target = rowTop < current
          ? rowTop
          : rowTop + _keyHeight + _gap > current + viewport
          ? rowTop + _keyHeight + _gap - viewport
          : current;
      _scrollController.animateTo(
        target
            .clamp(
              _scrollController.position.minScrollExtent,
              _scrollController.position.maxScrollExtent,
            )
            .toDouble(),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (_) {
        _lastKey = null;
        if (mounted) setState(() {});
      },
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 300.0;
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 300.0;
          final gap = (math.min(maxWidth, maxHeight) * 0.016).clamp(3.0, 10.0);
          final keyWidth = ((maxWidth - gap * 3) / 3).clamp(1.0, 112.0);
          final keyHeight = ((maxHeight - gap * 4) / 4)
              .clamp(48.0, 64.0)
              .toDouble();
          _keyHeight = keyHeight;
          _gap = gap.toDouble();
          return SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var r = 0; r < _rows.length; r++)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: gap / 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var c = 0; c < _rows[r].length; c++)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: gap / 2,
                              ),
                              child: _T9Key(
                                label: _rows[r][c],
                                hint: _hintFor(_rows[r][c]),
                                width: keyWidth,
                                height: keyHeight,
                                focused:
                                    _focusNode.hasFocus &&
                                    r == _row &&
                                    c == _col,
                                onTap: () {
                                  _focusNode.requestFocus();
                                  _row = r;
                                  _col = c;
                                  _pressKey(_rows[r][c]);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _hintFor(String key) {
    if (key == 'del' || key == 'search') return null;
    final group = _groups[key];
    if (group == null) return null;
    if (key == '0') return '空格';
    return group.join().toUpperCase();
  }
}

class _T9Key extends StatelessWidget {
  const _T9Key({
    required this.label,
    required this.focused,
    required this.onTap,
    required this.width,
    required this.height,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool focused;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isAction = label == 'del' || label == 'search';
    final showHint = hint != null && !isAction && label != '*';
    return TvFocusHighlight(
      focused: focused,
      radius: 14,
      borderWidth: 2,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: focused ? 1.04 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: NetflixSegment(
            radius: 14,
            child: SizedBox(
              width: width,
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: isAction
                        ? _KeyLabel(
                            label == 'del' ? '删除' : '搜索',
                            style: TextStyle(
                              fontSize: (height * 0.28).clamp(11.0, 15.0),
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _KeyLabel(
                                label,
                                style: TextStyle(
                                  fontSize: (height * 0.42).clamp(20.0, 24.0),
                                  height: 1.05,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (showHint)
                                _KeyLabel(
                                  hint!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 描边保证按键文字在明暗主题下均清晰可读。
class _KeyLabel extends StatelessWidget {
  const _KeyLabel(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : Colors.black;
    final outline = dark ? Colors.black : Colors.white;
    return Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8
                ..strokeJoin = StrokeJoin.round
                ..color = outline.withValues(alpha: 0.9),
            ),
          ),
        ),
        Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: style.copyWith(color: foreground),
        ),
      ],
    );
  }
}
