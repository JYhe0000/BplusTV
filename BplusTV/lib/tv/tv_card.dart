import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:flutter/material.dart';

/// Wraps a card so it can be navigated with a TV remote and shows a clear
/// highlight (scale + ring). The inner [child] must not be focusable itself.
class TvCard extends StatelessWidget {
  const TvCard({
    super.key,
    required this.child,
    this.onTap,
    this.onSecondaryTap,
    this.onLongPress,
    this.autofocus = false,
    this.focusNode,
    this.radius,
    this.scale = TvConstants.focusScale,
    this.focusColor,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// 外接指针的辅助按键回调。
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final FocusNode? focusNode;
  final double? radius;
  final double scale;
  final Color? focusColor;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,
      onSecondaryTap: onSecondaryTap,
      onLongPress: onLongPress,
      autofocus: autofocus,
      focusNode: focusNode,
      focusRadius: radius ?? TvConstants.focusRadius,
      builder: (context, focused, hovered) {
        return TvFocusHighlight(
          focused: focused,
          radius: radius,
          color: focusColor ?? Theme.of(context).colorScheme.primary,
          borderWidth: TvConstants.focusBorderWidth,
          focusedScale: scale,
          child: child,
        );
      },
    );
  }
}
