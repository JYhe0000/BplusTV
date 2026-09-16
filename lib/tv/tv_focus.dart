import 'package:PiliPlus/tv/tv_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef TvFocusBuilder =
    Widget Function(BuildContext context, bool focused, bool hovered);

/// A focusable wrapper for Android TV.
///
/// Handles D-pad focus, hover, and activation (OK / Enter / Space / gamepad A)
/// and exposes the current focus state to [builder] so callers can render a
/// focus highlight.
class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.mouseCursor = SystemMouseCursors.click,
  });

  final TvFocusBuilder builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool canRequestFocus;
  final MouseCursor mouseCursor;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _focused = false;
  bool _hovered = false;

  void _onTap() => widget.onTap?.call();

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.canRequestFocus,
      mouseCursor: widget.mouseCursor,
      onShowFocusHighlight: (value) {
        if (_focused != value) {
          setState(() => _focused = value);
          widget.onFocusChange?.call(value);
        }
      },
      onShowHoverHighlight: (value) {
        if (_hovered != value) {
          setState(() => _hovered = value);
        }
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onLongPress: widget.onLongPress,
        child: widget.builder(context, _focused, _hovered),
      ),
    );
  }
}

/// Renders an animated focus ring around [child] when [focused] is true.
class TvFocusHighlight extends StatelessWidget {
  const TvFocusHighlight({
    super.key,
    required this.focused,
    required this.child,
    this.radius,
    this.color,
    this.borderWidth,
  });

  final bool focused;
  final Widget child;
  final double? radius;
  final Color? color;
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final focusColor = color ?? Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: TvConstants.focusDuration,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? TvConstants.focusRadius),
        border: Border.all(
          color: focused ? focusColor : Colors.transparent,
          width: borderWidth ?? TvConstants.focusBorderWidth,
        ),
      ),
      child: child,
    );
  }
}

/// Focus traversal policy that moves focus geometrically in the pressed
/// direction, which is what a TV remote's D-pad expects.
class TvFocusTraversalPolicy extends FocusTraversalPolicy
    with DirectionalFocusTraversalPolicyMixin {
  TvFocusTraversalPolicy();

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    return descendants;
  }
}
