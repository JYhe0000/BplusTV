import 'dart:math' as math;

import 'package:bplus_tv/common/widgets/slotted_layout_helper.dart';
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:flutter/rendering.dart' show ChildLayoutHelper;
import 'package:material_ui/material_ui.dart';

enum MainType { sideBar, bottomNav, body }

class MainLayout
    extends SlottedMultiChildRenderObjectWidget<MainType, RenderBox> {
  const MainLayout({
    super.key,
    required this.sideBar,
    required this.bottomNav,
    required this.body,
    this.reserveBottomNav = false,
  });

  final Widget? sideBar;
  final Widget? bottomNav;
  final Widget body;
  final bool reserveBottomNav;

  @override
  Iterable<MainType> get slots => MainType.values;

  @override
  Widget? childForSlot(slot) => switch (slot) {
    .sideBar => sideBar,
    .bottomNav => bottomNav,
    // MainApp 已将顶部与右侧安全边距应用在 body 外层 Padding 中。
    // 同步清除 MediaQuery 标记，避免页面内的 ViewSafeArea 重复留白。
    .body => _MainBodyViewport(child: body),
  };

  @override
  SlottedContainerRenderObjectMixin<MainType, RenderBox> createRenderObject(
    BuildContext context,
  ) {
    return _RenderMainLayout(reserveBottomNav);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant SlottedContainerRenderObjectMixin<MainType, RenderBox>
    renderObject,
  ) {
    (renderObject as _RenderMainLayout).reserveBottomNav = reserveBottomNav;
  }
}

class _MainBodyViewport extends StatelessWidget {
  const _MainBodyViewport({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.removeViewPadding(
    context: context,
    removeTop: true,
    removeRight: true,
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: TvShellMetrics.contentMaxWidth,
        ),
        child: child,
      ),
    ),
  );
}

class _RenderMainLayout extends RenderBox
    with
        SlottedContainerRenderObjectMixin<MainType, RenderBox>,
        SlottedLayoutMixin {
  _RenderMainLayout(this._reserveBottomNav);

  bool _reserveBottomNav;
  set reserveBottomNav(bool value) {
    if (_reserveBottomNav == value) return;
    _reserveBottomNav = value;
    markNeedsLayout();
  }

  RenderBox? get sideBar => childForSlot(.sideBar);
  RenderBox? get bottomNav => childForSlot(.bottomNav);
  RenderBox get body => childForSlot(.body)!;

  @override
  Iterable<MainType> get slots => MainType.values;

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
  }

  /// dry 时不产生副作用（不写 offset），仅用 [ChildLayoutHelper.dryLayoutChild]
  /// 估算子节点尺寸；[computeDryLayout] 复用同一套约束计算逻辑。
  Size _layout(BoxConstraints constraints, {bool dry = true}) {
    // 无界时避免产生无限尺寸；有界时与 constraints.biggest 等价。
    final size = constraints.constrain(constraints.biggest);

    final Offset bodyOffset;
    final BoxConstraints bodyConstraints;

    final sideBar = this.sideBar;
    if (sideBar != null) {
      final sideBarConstraints = BoxConstraints(
        maxWidth: math
            .min(
              constraints.maxWidth,
              (constraints.maxWidth * TvShellMetrics.railWidthFactor).clamp(
                    TvShellMetrics.minimumRailWidth,
                    TvShellMetrics.maximumRailWidth,
                  ) +
                  TvShellMetrics.railOuterPadding,
            )
            .toDouble(),
        minHeight: constraints.maxHeight,
        maxHeight: constraints.maxHeight,
      );
      // The rail may be wider than the screen in extreme cases; clamp so the
      // body never gets a negative width.
      final sideBarWidth =
          (dry
                  ? ChildLayoutHelper.dryLayoutChild(
                      sideBar,
                      sideBarConstraints,
                    )
                  : ChildLayoutHelper.layoutChild(sideBar, sideBarConstraints))
              .width
              .clamp(0.0, constraints.maxWidth);
      if (!dry) setOffset(sideBar, .zero);

      bodyOffset = Offset(sideBarWidth, 0);
      bodyConstraints = BoxConstraints.tightFor(
        width: (constraints.maxWidth - sideBarWidth).clamp(
          0.0,
          constraints.maxWidth,
        ),
        height: constraints.maxHeight,
      );
    } else {
      final bottomNav = this.bottomNav;
      var bottomNavHeight = 0.0;
      if (bottomNav != null) {
        final bottomNavSize = dry
            ? ChildLayoutHelper.dryLayoutChild(bottomNav, constraints.loosen())
            : ChildLayoutHelper.layoutChild(bottomNav, constraints.loosen());
        if (_reserveBottomNav) {
          bottomNavHeight = bottomNavSize.height.clamp(
            0.0,
            constraints.maxHeight,
          );
        }
        if (!dry) {
          setOffset(
            bottomNav,
            Offset(
              (constraints.maxWidth - bottomNavSize.width) / 2,
              constraints.maxHeight - bottomNavSize.height,
            ),
          );
        }
      }

      bodyOffset = .zero;
      bodyConstraints = BoxConstraints.tightFor(
        width: constraints.maxWidth,
        height: (constraints.maxHeight - bottomNavHeight).clamp(
          0.0,
          constraints.maxHeight,
        ),
      );
    }

    final body = this.body;
    if (dry) {
      ChildLayoutHelper.dryLayoutChild(body, bodyConstraints);
    } else {
      body.layout(bodyConstraints);
      setOffset(body, bodyOffset);
    }
    return size;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layout(constraints);

  @override
  void paint(PaintingContext context, Offset offset) {
    void doPaint(RenderBox? child) {
      if (child != null) {
        context.paintChild(child, getOffset(child) + offset);
      }
    }

    doPaint(sideBar);
    doPaint(body);
    doPaint(bottomNav);
  }
}
