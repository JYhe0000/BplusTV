import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:material_ui/material_ui.dart';

class TvOption<T> {
  const TvOption({
    required this.value,
    required this.label,
    this.leading,
    this.subtitle,
    this.enabled = true,
  });

  final T value;
  final String label;
  final Widget? leading;
  final String? subtitle;
  final bool enabled;
}

/// TV-friendly list selector: opens a focus-scoped dialog, navigated with the
/// D-pad, and resolves with the chosen value (or null when dismissed).
Future<T?> showTvOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<TvOption<T>> options,
  T? current,
}) {
  return showDialog<T>(
    context: context,
    builder: (_) => _TvOptionPickerDialog<T>(
      title: title,
      options: options,
      current: current,
    ),
  );
}

class _TvOptionPickerDialog<T> extends StatefulWidget {
  const _TvOptionPickerDialog({
    required this.title,
    required this.options,
    this.current,
  });

  final String title;
  final List<TvOption<T>> options;
  final T? current;

  @override
  State<_TvOptionPickerDialog<T>> createState() =>
      _TvOptionPickerDialogState<T>();
}

class _TvOptionPickerDialogState<T> extends State<_TvOptionPickerDialog<T>> {
  /// 首次定位先让懒加载列表构建目标项，再把焦点目标滚到可视区。
  final GlobalKey _currentKey = GlobalKey();
  ScrollController? _scroll;
  bool _initialRevealScheduled = false;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final current = widget.current;
    final currentIndex = options.indexWhere((o) => o.value == current);
    final focusIndex = currentIndex >= 0 && options[currentIndex].enabled
        ? currentIndex
        : options.indexWhere((option) => option.enabled);
    // 固定行高随文字缩放增长，初始偏移可准确定位到屏外的当前项。
    final itemExtent = MediaQuery.textScalerOf(context).scale(20) + 40;
    _scroll ??= ScrollController(
      initialScrollOffset:
          (focusIndex - 2).clamp(0, options.length) * itemExtent,
    );
    if (focusIndex >= 0 && !_initialRevealScheduled) {
      _initialRevealScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _currentKey.currentContext;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(ctx, alignment: 0.5);
        }
      });
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(60),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: tvDialog(
        netflixSurface(
          radius: 24,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 360,
              maxWidth: 520,
              maxHeight: 560,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                Flexible(
                  child: ListView.builder(
                    controller: _scroll,
                    itemExtent: itemExtent,
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: options.length,
                    itemBuilder: (context, index) => _TvOptionTile<T>(
                      key: index == focusIndex ? _currentKey : null,
                      option: options[index],
                      selected: options[index].value == current,
                      autofocus: index == focusIndex,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TvOptionTile<T> extends StatelessWidget {
  const _TvOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.autofocus,
  });

  final TvOption<T> option;
  final bool selected;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      canRequestFocus: option.enabled,
      onTap: option.enabled
          ? () => Navigator.of(context).pop(option.value)
          : null,
      builder: (context, focused, hovered) {
        final onColor = option.enabled ? Colors.white : Colors.white38;
        final tile = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (option.leading case final leading?) ...[
                SizedBox(width: 24, child: Center(child: leading)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    color: onColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              // Must be flex: a bare Text gives the Row an unbounded width
              // constraint and a long subtitle overflows the tile.
              if (option.subtitle case final subtitle?) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      color: focused
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
              if (selected) ...[
                const SizedBox(width: 10),
                Icon(Icons.check_rounded, color: onColor),
              ],
            ],
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TvFocusHighlight(
            focused: focused,
            overlay: true,
            radius: 10,
            child: tile,
          ),
        );
      },
    );
  }
}
