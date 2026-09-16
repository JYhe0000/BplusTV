import 'package:PiliPlus/tv/search/t9_keyboard.dart';
import 'package:PiliPlus/tv/search/tv_qr_search.dart';
import 'package:PiliPlus/tv/tv_focus.dart';
import 'package:flutter/material.dart';

/// TV search entry: a T9 on-screen keypad plus a "scan with phone" option.
/// Resolves with the keyword to search, or null if dismissed.
Future<String?> showTvSearchInput(
  BuildContext context, {
  String initialText = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => TvSearchInputDialog(initialText: initialText),
  );
}

class TvSearchInputDialog extends StatefulWidget {
  const TvSearchInputDialog({super.key, this.initialText = ''});

  final String initialText;

  @override
  State<TvSearchInputDialog> createState() => _TvSearchInputDialogState();
}

class _TvSearchInputDialogState extends State<TvSearchInputDialog> {
  late String _text = widget.initialText;

  Future<void> _scan() async {
    final keyword = await showTvQrSearch(context);
    if (keyword != null && mounted) {
      Navigator.of(context).pop(keyword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('搜索', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Container(
              width: 420,
              height: 56,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _text.isEmpty ? '输入关键词' : _text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  color: _text.isEmpty
                      ? colorScheme.outline
                      : colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            T9Keyboard(
              initialText: _text,
              onChanged: (text) => setState(() => _text = text),
              onSubmit: (keyword) => Navigator.of(context).pop(keyword),
            ),
            const SizedBox(height: 8),
            TvFocusable(
              onTap: _scan,
              builder: (context, focused, hovered) => TvFocusHighlight(
                radius: 12,
                focused: focused,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '手机扫码输入',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
