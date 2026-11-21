import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/search/tv_full_keyboard.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:flutter/material.dart';

/// Shows a TV dialog for entering free-form text with the on-screen full
/// keyboard. Returns the entered text, or null if dismissed. Down from the
/// keyboard's action row hands focus to the 取消/确定 row below; Up there
/// returns to the keyboard.
Future<String?> showTvTextInput(
  BuildContext context, {
  required String title,
  String initialValue = '',
  int? maxLength,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _TvTextInputDialog(
      title: title,
      initialValue: initialValue,
      maxLength: maxLength,
    ),
  );
}

class _TvTextInputDialog extends StatefulWidget {
  const _TvTextInputDialog({
    required this.title,
    required this.initialValue,
    this.maxLength,
  });

  final String title;
  final String initialValue;
  final int? maxLength;

  @override
  State<_TvTextInputDialog> createState() => _TvTextInputDialogState();
}

class _TvTextInputDialogState extends State<_TvTextInputDialog> {
  /// Source of truth: the keyboard owns the buffer and reports every change
  /// through [_onChanged], which clamps it to [maxLength] (the keyboard itself
  /// does not). No local mirror here — an earlier version kept its own copy and
  /// rejected any shorter callback, which silently swallowed backspace/clear.
  late String _text;

  final FocusNode _cancelFocus = FocusNode(debugLabel: 'TvTextInputCancel');
  final FocusNode _confirmFocus = FocusNode(debugLabel: 'TvTextInputConfirm');

  @override
  void initState() {
    super.initState();
    _text = widget.initialValue;
  }

  @override
  void dispose() {
    _cancelFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final maxLength = widget.maxLength;
    // 长度与截断都按字素（grapheme）计算，避免在代理对中间截断
    final next = maxLength != null && text.characters.length > maxLength
        ? text.characters.take(maxLength).toString()
        : text;
    // Re-keying the keyboard on truncation makes it drop the overflow itself,
    // so its buffer and what the dialog shows can never diverge.
    if (next != _text) {
      setState(() => _text = next);
    }
  }

  void _confirm() {
    Navigator.of(context).pop(_text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(40),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: netflixSurface(
        radius: 24,
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 14),
                child: Container(
                  height: 52,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    _text.isEmpty ? ' ' : _text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      color: _text.isEmpty
                          ? colorScheme.outline
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: TvFullKeyboard(
                    // Keyed on the clamped text so the keyboard re-syncs its
                    // own buffer whenever we truncate: without it the keyboard
                    // keeps appending to text the dialog no longer shows.
                    key: ValueKey(_text),
                    initialText: _text,
                    onChanged: _onChanged,
                    onSubmit: (value) =>
                        Navigator.of(context).pop(value.trim()),
                    onExitDown: _cancelFocus.requestFocus,
                    autofocus: true,
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                // Wrap so the two buttons never overflow the 520px panel at a
                // large text scale.
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _ActionButton(
                      label: '取消',
                      focusNode: _cancelFocus,
                      onTap: () => Navigator.of(context).pop(null),
                    ),
                    _ActionButton(
                      label: '确定',
                      focusNode: _confirmFocus,
                      primary: true,
                      onTap: _confirm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.focusNode,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final FocusNode focusNode;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      focusNode: focusNode,
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 12,
        child: Container(
          constraints: const BoxConstraints(minWidth: 110, minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: primary
                ? colorScheme.primary.withValues(alpha: 0.92)
                : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primary
                  ? Colors.white
                  : Colors.white70.withValues(alpha: focused ? 1 : 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
