import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:flutter/material.dart';

/// 为卡片或列表行提供遥控器导航和统一的焦点高亮。
class TvFocusCard extends StatelessWidget {
  const TvFocusCard({
    super.key,
    required this.child,
    this.onTap,
    this.onSecondaryTap,
    this.onLongPress,
    this.onFocusChange,
    this.radius = 12,
    this.borderWidth = 2,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// 外接指针的辅助按键回调。
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onFocusChange;
  final double radius;
  final double borderWidth;

  /// 默认启用；仅在调用方已有焦点处理时显式关闭包装。
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    return TvFocusable(
      onTap: onTap,
      onSecondaryTap: onSecondaryTap,
      onLongPress: onLongPress,
      onFocusChange: onFocusChange,
      autofocus: autofocus,
      focusNode: focusNode,
      focusRadius: radius,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: radius,
        borderWidth: borderWidth,
        color: Theme.of(context).colorScheme.primary,
        child: child,
      ),
    );
  }
}

/// 为原生按钮提供统一焦点高亮，并通过 [ExcludeFocus] 避免双重焦点。
class TvFocusButton extends StatelessWidget {
  const TvFocusButton({
    super.key,
    required this.child,
    this.onTap,
    this.onSecondaryTap,
    this.enabled = true,
    this.radius = 12,
    this.borderWidth = 2,
    this.autofocus = false,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// 外接指针的辅助按键回调。
  final VoidCallback? onSecondaryTap;

  /// 默认启用；仅在调用方已有焦点处理时显式关闭包装。
  final bool enabled;
  final double radius;
  final double borderWidth;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    return TvFocusable(
      onTap: onTap,
      onSecondaryTap: onSecondaryTap,
      autofocus: autofocus,
      focusNode: focusNode,
      focusRadius: radius,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: radius,
        borderWidth: borderWidth,
        color: Theme.of(context).colorScheme.primary,
        child: ExcludeFocus(child: child),
      ),
    );
  }
}

/// Draws the shared focus highlight around [child] while the
/// child — or any of its descendants — holds focus, WITHOUT taking focus
/// itself.
///
/// [TvFocusCard] can't be used for native `ListTile`s and `Switch`es: it owns
/// the focus node and needs `ExcludeFocus` on the child, which also strips the
/// child's own Enter/Space handling. This wrapper instead mounts a
/// non-focusable [Focus] as an ancestor, so `hasFocus` turns true when the
/// inner control is focused while activation still runs through that control.
///
/// 默认启用，显式关闭时透传 [child]。
class TvFocusRing extends StatefulWidget {
  const TvFocusRing({
    super.key,
    required this.child,
    this.enabled = true,
    this.radius = TvConstants.focusRadius,
    this.borderWidth = TvConstants.focusBorderWidth,
  });

  final Widget child;

  /// 默认启用；仅在调用方已有焦点处理时显式关闭包装。
  final bool enabled;
  final double radius;
  final double borderWidth;

  @override
  State<TvFocusRing> createState() => _TvFocusRingState();
}

class _TvFocusRingState extends State<TvFocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) {
        if (_focused != value) {
          setState(() => _focused = value);
        }
      },
      child: TvFocusHighlight(
        focused: _focused,
        radius: widget.radius,
        borderWidth: widget.borderWidth,
        color: Theme.of(context).colorScheme.primary,
        child: widget.child,
      ),
    );
  }
}
