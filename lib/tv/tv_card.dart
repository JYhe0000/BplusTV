import 'package:PiliPlus/tv/tv_constants.dart';
import 'package:PiliPlus/tv/tv_focus.dart';
import 'package:flutter/material.dart';

/// Wraps a card so it can be navigated with a TV remote and shows a clear
/// highlight (scale + ring). The inner [child] must not be focusable itself.
class TvCard extends StatelessWidget {
  const TvCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.autofocus = false,
    this.focusNode,
    this.radius,
    this.scale = TvConstants.focusScale,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final FocusNode? focusNode;
  final double? radius;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,
      onLongPress: onLongPress,
      autofocus: autofocus,
      focusNode: focusNode,
      builder: (context, focused, hovered) {
        return AnimatedScale(
          scale: focused ? scale : 1.0,
          duration: TvConstants.focusDuration,
          curve: Curves.easeOut,
          child: TvFocusHighlight(
            focused: focused,
            radius: radius,
            child: child,
          ),
        );
      },
    );
  }
}
