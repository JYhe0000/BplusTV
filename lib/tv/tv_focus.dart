import 'dart:math' show max, min;

import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

typedef TvFocusBuilder = Widget Function(
  BuildContext context,
  bool focused,
  bool hovered,
);

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
    this.onSecondaryTap,
    this.onLongPress,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.focusRadius = TvConstants.focusRadius,
    this.mouseCursor = SystemMouseCursors.click,
  });

  final TvFocusBuilder builder;
  final VoidCallback? onTap;

  /// 外接指针的辅助按键回调。
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool canRequestFocus;
  final double focusRadius;
  final MouseCursor mouseCursor;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  static const _activationShortcuts = {
    SingleActivator(
      LogicalKeyboardKey.select,
      includeRepeats: false,
    ): ActivateIntent(),
    SingleActivator(
      LogicalKeyboardKey.enter,
      includeRepeats: false,
    ): ActivateIntent(),
    SingleActivator(
      LogicalKeyboardKey.numpadEnter,
      includeRepeats: false,
    ): ActivateIntent(),
    SingleActivator(
      LogicalKeyboardKey.space,
      includeRepeats: false,
    ): ActivateIntent(),
    SingleActivator(
      LogicalKeyboardKey.gameButtonA,
      includeRepeats: false,
    ): ActivateIntent(),
  };

  final _highlightChanges = ValueNotifier<({bool focused, bool hovered})>(
    (focused: false, hovered: false),
  );
  late final _actions = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) {
        _onTap();
        return null;
      },
    ),
  };

  void _onTap() => widget.onTap?.call();

  void _onSecondaryTap() => widget.onSecondaryTap?.call();

  void _onFocusChange(bool value) {
    final current = _highlightChanges.value;
    if (current.focused == value) return;
    _highlightChanges.value = (focused: value, hovered: current.hovered);
    widget.onFocusChange?.call(value);
  }

  void _onShowHoverHighlight(bool value) {
    final current = _highlightChanges.value;
    if (current.hovered == value) return;
    _highlightChanges.value = (focused: current.focused, hovered: value);
  }

  @override
  void dispose() {
    _highlightChanges.dispose();
    super.dispose();
  }

  KeyEventResult _handleActivationRepeat(FocusNode node, KeyEvent event) {
    // 未匹配的重复事件会继续命中应用的默认快捷键，必须在冒泡前消费。
    if (widget.onTap != null &&
        event is KeyRepeatEvent &&
        _activationShortcuts.keys.any(
          (activator) => activator.trigger == event.logicalKey,
        )) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // directional 导航模式下 FAD 的 enabled=false 仍可聚焦，需显式隔离禁用项。
    return ExcludeFocus(
      excluding: !widget.canRequestFocus,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _handleActivationRepeat,
        child: FocusableActionDetector(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: widget.canRequestFocus,
          mouseCursor: widget.mouseCursor,
          onFocusChange: _onFocusChange,
          onShowHoverHighlight: _onShowHoverHighlight,
          // 纯焦点容器不注册空的激活动作，让确认键继续交给上层播放器。
          shortcuts: widget.onTap == null ? null : _activationShortcuts,
          actions: widget.onTap == null ? null : _actions,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.canRequestFocus && widget.onTap != null
                ? _onTap
                : null,
            onSecondaryTap:
                widget.canRequestFocus && widget.onSecondaryTap != null
                ? _onSecondaryTap
                : null,
            onLongPress: widget.canRequestFocus ? widget.onLongPress : null,
            child: ValueListenableBuilder<({bool focused, bool hovered})>(
              valueListenable: _highlightChanges,
              builder: (context, value, _) =>
                  widget.builder(context, value.focused, value.hovered),
            ),
          ),
        ),
      ),
    );
  }
}

/// 页面和弹窗共用的焦点有效性与默认目标规则。
abstract final class TvFocusUtils {
  static bool isFocusable(FocusNode? node, {FocusNode? within}) {
    if (node == null || node is FocusScopeNode) return false;
    final context = node.context;
    return context != null &&
        context.mounted &&
        node.canRequestFocus &&
        !node.skipTraversal &&
        (within == null || node.ancestors.contains(within)) &&
        context.findRenderObject()?.attached == true;
  }

  static FocusNode? firstFocusable(FocusScopeNode scope) {
    for (final node in scope.traversalDescendants) {
      if (isFocusable(node, within: scope)) return node;
    }
    return null;
  }
}

/// Smartisan 使用主题焦点色，默认主题使用白色边框和柔和缩放。
class TvFocusHighlight extends StatelessWidget {
  const TvFocusHighlight({
    super.key,
    required this.focused,
    required this.child,
    this.radius,
    this.color,
    this.borderWidth = TvConstants.focusBorderWidth,
    this.focusedScale = 1.025,
    this.overlay = false,
  });

  final bool focused;
  final Widget child;
  final double? radius;
  final Color? color;
  final double borderWidth;
  final double focusedScale;

  /// Kept for compatibility; the pane always covers the item.
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = radius ?? TvConstants.focusRadius;
    final isDark = theme.brightness == Brightness.dark;
    final smartisan = SmartisanStyle.of(context);
    final accent = SmartisanStyle.accentOf(theme.brightness);
    final focusFill = smartisan
        ? SmartisanStyle.rowSelectedOf(theme.brightness)
        : (color ?? Colors.white).withValues(alpha: 0.08);
    final strokeWidth = borderWidth;
    final showRing = focused && strokeWidth > 0;
    final visibleFlatFill = smartisan
        ? focusFill.withValues(alpha: isDark ? 0.42 : 0.58)
        : focusFill;

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ringColor = smartisan ? accent : Colors.white;
    return AnimatedScale(
      scale: !smartisan && focused && !reduceMotion ? focusedScale : 1,
      duration: reduceMotion ? Duration.zero : TvConstants.focusDuration,
      curve: Curves.easeOutCubic,
      // 填充和描边在同一次绘制中完成，避免两层透明度动画和额外裁剪。
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : TvConstants.focusDuration,
        curve: Curves.easeOut,
        foregroundDecoration: BoxDecoration(
          color: focused
              ? visibleFlatFill
              : visibleFlatFill.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(
            color: showRing ? ringColor : ringColor.withValues(alpha: 0),
            width: strokeWidth,
          ),
        ),
        // 高亮与缩放变化时复用封面、文字和卡片底纹的绘制结果。
        child: RepaintBoundary(child: child),
      ),
    );
  }
}

/// Provides a top inset (e.g. a floating bar) that focused items should
/// be scrolled below when the traversal reveals them.
class TvScrollInset extends InheritedWidget {
  const TvScrollInset({super.key, required this.top, required super.child});

  final double top;

  static double of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TvScrollInset>()?.top ?? 0;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TvScrollInset>()?.top;

  @override
  bool updateShouldNotify(TvScrollInset oldWidget) => oldWidget.top != top;
}

/// Focus traversal policy that moves focus geometrically in the pressed
/// direction, which is what a TV remote's D-pad expects.
class TvFocusTraversalPolicy extends FocusTraversalPolicy
    with DirectionalFocusTraversalPolicyMixin {
  TvFocusTraversalPolicy() : super(requestFocusCallback: _revealAndFocus);

  /// Like the framework default, but when a floating bar (see [TvScrollInset])
  /// covers the top of the scrollable, items are revealed *below* it instead of
  /// at the very top, so the first row never hides behind the bar.
  static void _revealAndFocus(
    FocusNode node, {
    ScrollPositionAlignmentPolicy? alignmentPolicy,
    double? alignment,
    Duration? duration,
    Curve? curve,
  }) {
    node.requestFocus();
    final context = node.context;
    if (context == null) {
      return;
    }
    // Directional traversal supplies Duration.zero / Curves.ease by default.
    // Treat that as a TV reveal request rather than a visible jump. A new
    // animateTo supersedes the previous activity when the remote is repeated.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final revealDuration = reduceMotion
        ? Duration.zero
        : duration == null || duration == Duration.zero
        ? TvConstants.focusScrollDuration
        : duration;
    final revealCurve = curve == null || curve == Curves.ease
        ? TvConstants.focusScrollCurve
        : curve;
    final policy = alignmentPolicy ?? ScrollPositionAlignmentPolicy.explicit;
    final effectiveAlignment = switch (policy) {
      ScrollPositionAlignmentPolicy.keepVisibleAtStart => 0.0,
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd => 1.0,
      ScrollPositionAlignmentPolicy.explicit => alignment ?? 1.0,
    };
    final inset = TvScrollInset.of(context);

    if (_revealNested(
      context,
      alignment: effectiveAlignment,
      policy: policy,
      duration: revealDuration,
      curve: revealCurve,
    )) {
      return;
    }

    ScrollableState? vertical;
    RenderAbstractViewport? viewport;
    if (inset > 0 && effectiveAlignment == 0.0) {
      vertical = _verticalScrollableOf(context);
      final renderObject = context.findRenderObject();
      viewport = renderObject == null
          ? null
          : _verticalViewportOf(renderObject);
    }
    if (vertical != null && viewport != null) {
      // Reveal BELOW the floating bar ourselves. Doing it directly avoids the
      // framework aligning the item to the very top and then us pushing it back
      // down (which looked like a bounce-back and never completed the reset).
      var target =
          (viewport
                      .getOffsetToReveal(
                        context.findRenderObject()!,
                        0.0,
                      )
                      .offset -
                  inset)
              .clamp(
                vertical.position.minScrollExtent,
                vertical.position.maxScrollExtent,
              )
              .toDouble();
      if (policy == ScrollPositionAlignmentPolicy.keepVisibleAtStart) {
        target = min(target, vertical.position.pixels);
      }
      if ((target - vertical.position.pixels).abs() > 0.5) {
        final d = revealDuration;
        if (d == Duration.zero) {
          vertical.position.jumpTo(target);
        } else {
          vertical.position.animateTo(
            target,
            duration: d,
            curve: revealCurve,
          );
        }
      }
      return;
    }

    Scrollable.ensureVisible(
      context,
      alignment: alignment ?? 1,
      alignmentPolicy: policy,
      duration: revealDuration,
      curve: revealCurve,
    );
  }

  /// 嵌套列表的内外层共用协调器，只能发起一次滚动，避免互相取消动画。
  static bool _revealNested(
    BuildContext context, {
    required double alignment,
    required ScrollPositionAlignmentPolicy policy,
    required Duration duration,
    required Curve curve,
  }) {
    final nested = context
        .findAncestorStateOfType<ExtendedNestedScrollViewState>();
    if (nested == null || !nested.outerController.hasClients) return false;
    final vertical = _verticalScrollableOf(context);
    if (vertical == null) return false;
    final outer = nested.outerController.position;
    final position = vertical.position;
    final isInner = nested.innerController.positions.contains(position);
    if (position != outer && !isInner) return false;
    if (outer.axisDirection != AxisDirection.down ||
        position.axisDirection != AxisDirection.down) {
      return false;
    }
    if (!outer.hasContentDimensions || !position.hasContentDimensions) {
      return true;
    }
    final object = context.findRenderObject();
    if (object == null || !object.attached) return true;

    RenderViewport? outerViewport;
    RenderViewport? innerViewport;
    RenderObject? current = object;
    while (current != null) {
      if (current is RenderViewport) {
        if (identical(current.offset, outer)) outerViewport = current;
        if (identical(current.offset, position)) innerViewport = current;
      }
      current = current.parent;
    }
    if (outerViewport == null || (isInner && innerViewport == null)) {
      return false;
    }

    // 仅显现最近的横向列表，不滚动承载分类的祖先 PageView。
    final nearest = Scrollable.maybeOf(context);
    if (nearest != null && nearest.position.axis == Axis.horizontal) {
      nearest.position.ensureVisible(
        object,
        alignment: alignment,
        alignmentPolicy: policy,
        duration: duration,
        curve: curve,
      );
    }

    double target;
    ScrollPosition driver;
    if (isInner) {
      final rect = MatrixUtils.transformRect(
        object.getTransformTo(outerViewport),
        object.paintBounds,
      );
      final innerRect = MatrixUtils.transformRect(
        innerViewport!.getTransformTo(outerViewport),
        innerViewport.paintBounds,
      );
      final bounds = outerViewport.paintBounds;
      final pinned = nested.widget.pinnedHeaderSliverHeightBuilder?.call() ?? 0;
      final top = max(bounds.top + pinned, innerRect.top);
      final bottom = min(bounds.bottom, innerRect.bottom);
      if (bottom <= top) return true;

      // 已在屏内的卡片保持不动，只补足被遮挡的距离。
      final delta = switch (policy) {
        ScrollPositionAlignmentPolicy.keepVisibleAtEnd => max(
          0.0,
          rect.bottom - bottom,
        ),
        ScrollPositionAlignmentPolicy.keepVisibleAtStart => min(
          0.0,
          rect.top - top,
        ),
        ScrollPositionAlignmentPolicy.explicit =>
          rect.top - top - (bottom - top - rect.height) * alignment,
      };
      if (delta.abs() <= 0.5) return true;
      final currentOffset =
          outer.pixels + position.pixels - position.minScrollExtent;
      final combined = (currentOffset + delta)
          .clamp(
            outer.minScrollExtent,
            outer.maxScrollExtent +
                position.maxScrollExtent -
                position.minScrollExtent,
          )
          .toDouble();
      if ((combined - currentOffset).abs() <= 0.5) return true;
      if (combined > outer.maxScrollExtent) {
        driver = position;
        target = position.minScrollExtent + combined - outer.maxScrollExtent;
      } else {
        driver = outer;
        target = combined;
      }
    } else {
      driver = outer;
      target = outerViewport
          .getOffsetToReveal(object, alignment)
          .offset
          .clamp(
            outer.minScrollExtent,
            outer.maxScrollExtent,
          )
          .toDouble();
      target = switch (policy) {
        ScrollPositionAlignmentPolicy.keepVisibleAtEnd => max(
          target,
          outer.pixels,
        ),
        ScrollPositionAlignmentPolicy.keepVisibleAtStart => min(
          target,
          outer.pixels,
        ),
        ScrollPositionAlignmentPolicy.explicit => target,
      };
      if ((target - outer.pixels).abs() <= 0.5) return true;
    }
    if (duration == Duration.zero) {
      driver.jumpTo(target);
    } else {
      driver.animateTo(target, duration: duration, curve: curve);
    }
    return true;
  }

  static ScrollableState? _verticalScrollableOf(BuildContext context) {
    ScrollableState? result;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is Scrollable) {
        final axis = widget.axisDirection;
        if (axis == AxisDirection.down || axis == AxisDirection.up) {
          result = (element as StatefulElement).state as ScrollableState;
          return false;
        }
      }
      return true;
    });
    return result;
  }

  static RenderAbstractViewport? _verticalViewportOf(RenderObject object) {
    RenderObject? current = object;
    while (current != null) {
      if (current is RenderAbstractViewport) {
        final axis = current is RenderViewport
            ? current.axisDirection
            : AxisDirection.down;
        if (axis == AxisDirection.down || axis == AxisDirection.up) {
          return current;
        }
      }
      current = current.parent;
    }
    return null;
  }

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    return descendants;
  }

  /// Overrides [DirectionalFocusTraversalPolicyMixin.inDirection]
  /// to guard against [FocusNode]s whose [RenderObject] is no longer attached
  /// to the tree (e.g. after a tab switch or widget disposal). Without this
  /// guard, pressing a D-pad arrow on a TV throws:
  ///   'attached': is not true.
  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    try {
      return super.inDirection(currentNode, direction);
    } catch (_) {
      return false;
    }
  }
}
