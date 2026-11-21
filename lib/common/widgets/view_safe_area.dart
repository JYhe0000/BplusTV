import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

abstract final class TvShellMetrics {
  static const double contentMaxWidth = 1728;
  static const double horizontalSafeMargin = 32;
  static const double verticalSafeMargin = 16;
  static const double minimumFocusTarget = 48;
  static const double minimumRailWidth = 56;
  static const double maximumRailWidth = 64;
  static const double railWidthFactor = 0.045;
  static const double railOuterPadding = 8;
}

class ViewSafeArea extends StatelessWidget {
  const ViewSafeArea({
    super.key,
    this.top = false,
    this.left = true,
    this.right = true,
    this.bottom = false,
    this.minimum = EdgeInsets.zero,
    required this.child,
  });

  final bool top;
  final bool left;
  final bool right;
  final bool bottom;
  final EdgeInsetsGeometry minimum;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final viewPadding = mediaQuery.viewPadding;
    final minimumPadding = minimum.resolve(Directionality.of(context));
    final applied =
        context
            .dependOnInheritedWidgetOfExactType<_ViewSafeAreaInsets>()
            ?.padding ??
        EdgeInsets.zero;
    final consumed = EdgeInsets.only(
      top: top
          ? math
                .max(viewPadding.top, minimumPadding.top - applied.top)
                .clamp(0.0, double.infinity)
                .toDouble()
          : 0,
      left: left
          ? math
                .max(viewPadding.left, minimumPadding.left - applied.left)
                .clamp(0.0, double.infinity)
                .toDouble()
          : 0,
      right: right
          ? math
                .max(viewPadding.right, minimumPadding.right - applied.right)
                .clamp(0.0, double.infinity)
                .toDouble()
          : 0,
      bottom: bottom
          ? math
                .max(viewPadding.bottom, minimumPadding.bottom - applied.bottom)
                .clamp(0.0, double.infinity)
                .toDouble()
          : 0,
    );
    if (consumed == EdgeInsets.zero) return child;

    // 同步消费系统边距与外壳最小边距，嵌套页面不会重复添加 overscan。
    final remainingPadding = EdgeInsets.only(
      top: top ? 0 : mediaQuery.padding.top,
      left: left ? 0 : mediaQuery.padding.left,
      right: right ? 0 : mediaQuery.padding.right,
      bottom: bottom ? 0 : mediaQuery.padding.bottom,
    );
    final remainingViewPadding = EdgeInsets.only(
      top: top ? 0 : viewPadding.top,
      left: left ? 0 : viewPadding.left,
      right: right ? 0 : viewPadding.right,
      bottom: bottom ? 0 : viewPadding.bottom,
    );

    return Padding(
      padding: consumed,
      child: MediaQuery(
        data: mediaQuery.copyWith(
          padding: remainingPadding,
          viewPadding: remainingViewPadding,
        ),
        child: _ViewSafeAreaInsets(
          padding: applied + consumed,
          child: child,
        ),
      ),
    );
  }
}

class _ViewSafeAreaInsets extends InheritedWidget {
  const _ViewSafeAreaInsets({required this.padding, required super.child});

  final EdgeInsets padding;

  @override
  bool updateShouldNotify(_ViewSafeAreaInsets oldWidget) =>
      padding != oldWidget.padding;
}
