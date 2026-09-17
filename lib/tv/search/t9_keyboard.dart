import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A 3x4 T9 keypad with index based navigation so a TV remote can always
/// operate it. Repeatedly activating the same key cycles through its
/// characters (classic multi-tap).
class T9Keyboard extends StatefulWidget {
  const T9Keyboard({
    super.key,
    required this.onChanged,
    this.onSubmit,
    this.initialText = '',
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmit;
  final String initialText;

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
    '*': ['*'],
    '#': ['#'],
  };

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['*', '0', '#'],
    ['del', 'search'],
  ];

  final FocusNode _focusNode = FocusNode(debugLabel: 'T9Keyboard');
  int _row = 1;
  int _col = 1;

  late String _text = widget.initialText;
  String? _lastKey;
  int _lastIndex = 0;
  DateTime _lastPress = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _cycleWindow = Duration(milliseconds: 1200);

  @override
  void dispose() {
    _focusNode.dispose();
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
    final cycling =
        _lastKey == key && now.difference(_lastPress) < _cycleWindow;
    if (cycling) {
      _lastIndex = (_lastIndex + 1) % group.length;
      _text = _text.substring(0, _text.length - 1) + group[_lastIndex];
    } else {
      _lastIndex = 0;
      _text += group[0];
    }
    _lastKey = key;
    _lastPress = now;
    _notify();
  }

  void _delete() {
    _lastKey = null;
    if (_text.isNotEmpty) {
      _text = _text.substring(0, _text.length - 1);
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
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        setState(() => _col = (_col - 1).clamp(0, _rows[_row].length - 1));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        setState(() => _col = (_col + 1).clamp(0, _rows[_row].length - 1));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _row = (_row - 1).clamp(0, _rows.length - 1);
          _col = _col.clamp(0, _rows[_row].length - 1);
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _row = (_row + 1).clamp(0, _rows.length - 1);
          _col = _col.clamp(0, _rows[_row].length - 1);
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        _pressKey(_rows[_row][_col]);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < _rows.length; r++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var c = 0; c < _rows[r].length; c++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: _T9Key(
                        label: _rows[r][c],
                        hint: _hintFor(_rows[r][c]),
                        focused: r == _row && c == _col,
                        onTap: () => _pressKey(_rows[r][c]),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String? _hintFor(String key) {
    if (key == 'del') return null;
    if (key == 'search') return null;
    final group = _groups[key];
    if (group == null) return null;
    return group.first.toUpperCase();
  }
}

class _T9Key extends StatelessWidget {
  const _T9Key({
    required this.label,
    required this.focused,
    required this.onTap,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAction = label == 'del' || label == 'search';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: isAction ? 120 : 80,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: focused
              ? colorScheme.primary
              : (isAction
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: focused ? colorScheme.onPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: isAction
            ? Text(
                label == 'del' ? '删除' : '搜索',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: focused
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: focused
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint!,
                      style: TextStyle(
                        fontSize: 11,
                        color: focused
                            ? colorScheme.onPrimary.withValues(alpha: 0.8)
                            : colorScheme.outline,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
