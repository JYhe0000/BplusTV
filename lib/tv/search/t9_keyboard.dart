import 'package:PiliPlus/tv/tv_focus.dart';
import 'package:flutter/material.dart';

/// A 3x4 T9 keypad that can be operated entirely with a TV remote.
///
/// Repeatedly activating the same key cycles through its characters
/// (classic multi-tap). [onChanged] is called whenever the text changes and
/// [onSubmit] when the user confirms the query.
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
  };

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['*', '0', '#'],
  ];

  late String _text = widget.initialText;
  String? _lastKey;
  int _lastIndex = 0;
  DateTime _lastPress = DateTime.fromMillisecondsSinceEpoch(0);

  static const Duration _cycleWindow = Duration(milliseconds: 1200);

  void _onKey(String key) {
    if (key == '*') {
      _delete();
      return;
    }
    if (key == '#') {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final key in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _T9Key(
                      label: key,
                      hint: _groups[key]?.first.toUpperCase(),
                      onTap: () => _onKey(key),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _T9Action(
                label: '删除',
                onTap: _delete,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _T9Action(
                label: '搜索',
                primary: true,
                color: colorScheme.primary,
                onTap: _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _T9Key extends StatelessWidget {
  const _T9Key({required this.label, required this.onTap, this.hint});

  final String label;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        radius: 12,
        focused: focused,
        child: Container(
          width: 76,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: focused
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (hint != null)
                Text(
                  hint!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _T9Action extends StatelessWidget {
  const _T9Action({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        radius: 12,
        focused: focused,
        child: Container(
          width: 120,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary
                ? (focused ? colorScheme.primary : color)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primary ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
