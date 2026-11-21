import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// Shows a TV numeric keypad dialog for entering things like a phone number
/// or an SMS code, which have no sensible letter mapping. Returns the entered
/// text, or null if dismissed.
///
/// Like [T9Keyboard] the keypad owns a single [Focus] node and translates
/// D-pad moves into a highlighted (row, col) position, so a TV remote can
/// operate it without any on-screen soft keyboard.
Future<String?> showTvNumpad(
  BuildContext context, {
  required String title,
  String initialValue = '',
  int? maxLength,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _TvNumpadDialog(
      title: title,
      initialValue: initialValue,
      maxLength: maxLength,
    ),
  );
}

class _TvNumpadDialog extends StatefulWidget {
  const _TvNumpadDialog({
    required this.title,
    required this.initialValue,
    this.maxLength,
  });

  final String title;
  final String initialValue;
  final int? maxLength;

  @override
  State<_TvNumpadDialog> createState() => _TvNumpadDialogState();
}

class _TvNumpadDialogState extends State<_TvNumpadDialog> {
  static const List<String> _rows = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'del',
    '0',
    'ok',
  ];

  late final FocusNode _focusNode = FocusNode(debugLabel: 'TvNumpad');
  late String _text = widget.initialValue;
  int _row = 1;
  int _col = 1;

  /// 0 = keypad, 1 = cancel, -1 = no virtual cursor (focus elsewhere).
  int _focusTarget = 0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _append(String digit) {
    if (widget.maxLength != null && _text.length >= widget.maxLength!) return;
    setState(() => _text += digit);
  }

  void _del() {
    if (_text.isNotEmpty) {
      // Digits only, so a plain code-unit drop is safe.
      setState(() => _text = _text.substring(0, _text.length - 1));
    }
  }

  void _submit() {
    if (_text.isEmpty) {
      // Don't swallow the press silently: the 确定 key would look broken.
      SmartDialog.showToast('请输入内容');
      return;
    }
    Navigator.of(context).pop(_text);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (_focusTarget != 0) {
          setState(() => _focusTarget = 0);
        } else if (_col > 0) {
          setState(() => _col--);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (_focusTarget != 0) {
          setState(() => _focusTarget = 0);
        } else if (_col < 2) {
          setState(() => _col++);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (_focusTarget == 1) {
          setState(() => _focusTarget = 0);
        } else if (_row > 0) {
          setState(() => _row--);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_row < 3) {
          setState(() => _row++);
        } else {
          setState(() => _focusTarget = 1);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        if (_focusTarget == 1) {
          Navigator.of(context).maybePop();
        } else {
          final key = _rows[_row * 3 + _col];
          if (key == 'del') {
            _del();
          } else if (key == 'ok') {
            _submit();
          } else {
            _append(key);
          }
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.backspace:
        _del();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      insetPadding: const EdgeInsets.all(40),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: netflixSurface(
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(
                width: 260,
                height: 52,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF181818)
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                child: Text(
                  _text.isEmpty ? '请输入' : _text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    letterSpacing: 2,
                    color: _text.isEmpty
                        ? colorScheme.outline
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Focus(
                focusNode: _focusNode,
                autofocus: true,
                onFocusChange: (hasFocus) {
                  // Leaving the keypad must drop the virtual cursor, otherwise
                  // the key that was last "selected" keeps painting a highlight
                  // next to the real focus (two cursors on screen).
                  if (!hasFocus && _focusTarget == 0) {
                    setState(() => _focusTarget = -1);
                  } else if (hasFocus && _focusTarget != 0) {
                    setState(() => _focusTarget = 0);
                  }
                },
                onKeyEvent: _onKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var r = 0; r < 4; r++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var c = 0; c < 3; c++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: _NumpadKey(
                                  label: _rows[r * 3 + c],
                                  focused:
                                      _focusTarget == 0 &&
                                      r == _row &&
                                      c == _col,
                                  onTap: () {
                                    final key = _rows[r * 3 + c];
                                    if (key == 'del') {
                                      _del();
                                    } else if (key == 'ok') {
                                      _submit();
                                    } else {
                                      _append(key);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TvFocusable(
                autofocus: false,
                onFocusChange: (focused) {
                  if (focused && _focusTarget != 1) {
                    setState(() => _focusTarget = 1);
                  }
                },
                onTap: () => Navigator.of(context).maybePop(),
                builder: (context, focused, hovered) => TvFocusHighlight(
                  radius: 12,
                  focused: focused,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _focusTarget == 1 && !focused
                          ? Colors.white.withValues(alpha: 0.08)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({
    required this.label,
    required this.focused,
    required this.onTap,
  });

  final String label;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAction = label == 'del' || label == 'ok';
    final showLabel = label == 'del'
        ? '删除'
        : label == 'ok'
        ? '确定'
        : label;
    return GestureDetector(
      onTap: onTap,
      child: TvFocusHighlight(
        focused: focused,
        overlay: true,
        radius: 14,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 76,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isAction
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            showLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isAction ? 16 : 24,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
