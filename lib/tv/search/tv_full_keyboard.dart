import 'dart:math' as math;

import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A TV on-screen keyboard modelled after BiliTV/BLILI: an action row
/// (clear / back / search) above a 6-column A–Z + 0–9 grid.
///
/// Navigation is index based so a remote can always reach every key. When the
/// D-pad moves past an edge the matching `onExit*` callback is fired so the
/// host can hand focus to a neighbouring pane.
class TvFullKeyboard extends StatefulWidget {
  const TvFullKeyboard({
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
  final VoidCallback? onExitLeft;
  final VoidCallback? onExitRight;
  final VoidCallback? onExitUp;
  final VoidCallback? onExitDown;

  @override
  State<TvFullKeyboard> createState() => _TvFullKeyboardState();
}

class _TvFullKeyboardState extends State<TvFullKeyboard> {
  static const List<List<String>> _gridRows = [
    ['A', 'B', 'C', 'D', 'E', 'F'],
    ['G', 'H', 'I', 'J', 'K', 'L'],
    ['M', 'N', 'O', 'P', 'Q', 'R'],
    ['S', 'T', 'U', 'V', 'W', 'X'],
    ['Y', 'Z', '0', '1', '2', '3'],
    ['4', '5', '6', '7', '8', '9'],
  ];
  static const List<String> _actions = ['清空', '后退', '搜索'];

  late final FocusNode _focusNode =
      widget.focusNode ?? FocusNode(debugLabel: 'TvFullKeyboard');

  /// -1 is the action row, 0.. are the grid rows.
  int _row = 0;
  int _col = 0;
  bool _focused = false;
  final ScrollController _scrollController = ScrollController();
  double _keyHeight = 56;
  double _gap = 8;

  late String _text = widget.initialText;

  int _lengthOf(int row) => row < 0 ? _actions.length : _gridRows[row].length;

  @override
  void didUpdateWidget(covariant TvFullKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText) {
      _text = widget.initialText;
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

  void _notify() {
    setState(() {});
    widget.onChanged(_text);
  }

  void _append(String char) {
    _text += char;
    _notify();
  }

  void _backspace() {
    if (_text.isEmpty) return;
    // 按字素删除，避免把代理对（emoji/生僻字）截成半个
    _text = _text.characters.skipLast(1).toString();
    _notify();
  }

  void _clear() {
    if (_text.isEmpty) return;
    _text = '';
    _notify();
  }

  void _submit() {
    final keyword = _text.trim();
    if (keyword.isNotEmpty) {
      widget.onSubmit?.call(keyword);
    }
  }

  void _activate() {
    if (_row < 0) {
      switch (_col) {
        case 0:
          _clear();
        case 1:
          _backspace();
        case 2:
          _submit();
      }
    } else {
      _append(_gridRows[_row][_col]);
    }
  }

  void _moveH(int delta) {
    final length = _lengthOf(_row);
    final next = _col + delta;
    if (next < 0) {
      widget.onExitLeft?.call();
    } else if (next >= length) {
      widget.onExitRight?.call();
    } else {
      setState(() => _col = next);
    }
  }

  void _moveV(int delta) {
    final nextRow = _row + delta;
    if (nextRow < -1) {
      widget.onExitUp?.call();
      return;
    }
    if (nextRow >= _gridRows.length) {
      widget.onExitDown?.call();
      return;
    }
    setState(() {
      _row = nextRow;
      _col = _col.clamp(0, _lengthOf(_row) - 1);
    });
    _revealRow();
  }

  void _revealRow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final rowIndex = _row < 0 ? 0 : _row + 1;
      final rowTop = rowIndex * (_keyHeight + _gap);
      final current = _scrollController.offset;
      final viewport = _scrollController.position.viewportDimension;
      final target = rowTop < current
          ? rowTop
          : rowTop + _keyHeight > current + viewport
          ? rowTop + _keyHeight - viewport
          : current;
      _scrollController.animateTo(
        target
            .clamp(
              _scrollController.position.minScrollExtent,
              _scrollController.position.maxScrollExtent,
            )
            .toDouble(),
        duration: TvConstants.focusScrollDuration,
        curve: TvConstants.focusScrollCurve,
      );
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _moveH(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _moveH(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _moveV(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _moveV(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.gameButtonA:
        if (event is KeyRepeatEvent) return KeyEventResult.handled;
        _activate();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (value) {
        if (_focused != value) setState(() => _focused = value);
      },
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 420.0;
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 420.0;
          _gap = (math.min(maxWidth, maxHeight) * 0.018)
              .clamp(3.0, 8.0)
              .toDouble();
          _gap = math.min(
            _gap,
            math.max(0.0, (maxWidth - 6 * 48) / 5),
          );
          _keyHeight = ((maxHeight - _gap * 6) / 7)
              .clamp(48.0, 56.0)
              .toDouble();
          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionRow(_gap, _keyHeight),
                SizedBox(height: _gap),
                for (var r = 0; r < _gridRows.length; r++) ...[
                  if (r > 0) SizedBox(height: _gap),
                  _buildGridRow(r, _gap, _keyHeight),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionRow(double gap, double keyHeight) {
    return Row(
      children: [
        for (var c = 0; c < _actions.length; c++) ...[
          if (c > 0) SizedBox(width: gap),
          Expanded(
            child: _KeyTile(
              label: _actions[c],
              focused: _focused && _row == -1 && _col == c,
              emphasized: c == _actions.length - 1,
              height: keyHeight,
              onTap: () {
                _focusNode.requestFocus();
                setState(() {
                  _row = -1;
                  _col = c;
                });
                _activate();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGridRow(int r, double gap, double keyHeight) {
    return Row(
      children: [
        for (var c = 0; c < _gridRows[r].length; c++) ...[
          if (c > 0) SizedBox(width: gap),
          Expanded(
            child: _KeyTile(
              label: _gridRows[r][c],
              focused: _focused && _row == r && _col == c,
              height: keyHeight,
              onTap: () {
                _focusNode.requestFocus();
                setState(() {
                  _row = r;
                  _col = c;
                });
                _append(_gridRows[r][c]);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyTile extends StatelessWidget {
  const _KeyTile({
    required this.label,
    required this.focused,
    required this.onTap,
    required this.height,
    this.emphasized = false,
  });

  final String label;
  final bool focused;
  final bool emphasized;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: TvFocusHighlight(
        focused: focused,
        overlay: true,
        radius: 14,
        child: NetflixSegment(
          radius: 14,
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: emphasized
                  ? colorScheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: label.length > 1 ? 15 : 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
