import 'package:PiliPlus/tv/tv_focus.dart';
import 'package:material_ui/material_ui.dart';

class ComBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double width;
  final double height;
  final String? tooltip;
  final bool autofocus;

  const ComBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.width = 34,
    this.height = 34,
    this.tooltip,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: width,
      height: height,
      child: TvFocusable(
        onTap: onTap,
        onLongPress: onLongPress,
        autofocus: autofocus,
        builder: (context, focused, hovered) => TvFocusHighlight(
          radius: 8,
          focused: focused,
          child: Center(child: icon),
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: child);
    }
    return child;
  }
}
