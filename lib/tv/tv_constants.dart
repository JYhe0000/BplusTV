import 'package:flutter/widgets.dart';

/// Central tuning values for the Android TV (10-foot) UI.
abstract final class TvConstants {
  /// Overscan-safe insets so content is not clipped on TVs.
  static const EdgeInsets overscan = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );

  /// How much a focused item scales up.
  static const double focusScale = 1.04;

  /// Focus highlight animation duration.
  static const Duration focusDuration = Duration(milliseconds: 150);

  /// Width of the focus ring.
  static const double focusBorderWidth = 3;

  /// Default corner radius of the focus ring.
  static const double focusRadius = 12;

  /// Minimum interactive target size for 10-foot UI.
  static const double minTargetSize = 48;
}
