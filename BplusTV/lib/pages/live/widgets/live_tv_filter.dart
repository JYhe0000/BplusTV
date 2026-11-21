import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:material_ui/material_ui.dart';

/// 保持选中态与遥控焦点独立，短标签也提供完整的确认目标。
class LiveTvFilter extends StatelessWidget {
  const LiveTvFilter({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 12,
        child: Container(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? scheme.secondaryContainer : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
