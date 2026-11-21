import 'package:flutter/widgets.dart';

/// Central tuning values for the Android TV (10-foot) UI.
abstract final class TvConstants {
  /// 紧凑界面的尺寸基准，用户缩放在此基础上继续生效。
  static const double compactUiScale = 0.75;

  /// 字号在紧凑布局基础上略微收小，仍保留用户的字号偏好。
  static const double compactTextScale = 0.9;

  /// 全局 TV 安全区，避免内容被电视的 overscan 裁切。
  static const overscan = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  /// How much a focused item scales up.
  static const double focusScale = 1.05;

  static const double focusHalo = 6;

  /// Reserve the peak of easeOutBack (less than 1.11), not just its endpoint.
  static double focusPaintOutset(double extent) {
    const peakScale = 1 + (focusScale - 1) * 1.11;
    return (extent * (peakScale - 1) / 2 + focusHalo * peakScale)
        .ceilToDouble();
  }

  /// Focus highlight animation duration.
  static const Duration focusDuration = Duration(milliseconds: 150);

  /// Smooth D-pad reveal, independent of the faster selection highlight.
  static const Duration focusScrollDuration = Duration(milliseconds: 280);
  static const Curve focusScrollCurve = Curves.easeOutCubic;

  /// Width of the focus ring.
  ///
  /// This is the app-wide value: [TvFocusHighlight] and [TvFocusRing] default to
  /// it, and every call site that passes an explicit `borderWidth` passes 2, so
  /// keep them in sync by changing this rather than overriding per site.
  static const double focusBorderWidth = 2;

  /// Default corner radius of the focus ring.
  static const double focusRadius = 12;

  /// Minimum interactive target size for 10-foot UI.
  static const double minTargetSize = 48;

  /// 设置项最小高度；较矮屏幕使用更紧凑的尺寸。
  static double settingRowMinHeight(double viewportHeight) =>
      viewportHeight < 600 ? 52 : 58;

  /// 根据可用宽度调整设置分类栏宽度。
  static double settingSidebarWidth(double viewportWidth) =>
      (viewportWidth * 0.2).clamp(224.0, 256.0).toDouble();

  /// Height reserved by the floating home top bar (tabs), including its
  /// vertical padding.
  static const double homeTopBarHeight = 60;
}
