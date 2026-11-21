import 'dart:math' show pow;

import 'package:flutter/widgets.dart' show BuildContext, MediaQuery;

extension ImageExtension on num {
  int? cacheSize(BuildContext context) {
    if (!isFinite || this <= 0) {
      return null;
    }
    final pixels = (this * MediaQuery.devicePixelRatioOf(context)).ceil();
    if (pixels <= 0) return null;
    // 大图按 32 像素向上归档，相近卡片尺寸复用同一份解码缓存。
    return pixels <= 64 ? pixels : ((pixels + 31) ~/ 32) * 32;
  }
}

extension IntExt on int? {
  int? operator +(int other) => this == null ? null : this! + other;
  int? operator -(int other) => this == null ? null : this! - other;
}

extension DoubleExt on double {
  double toPrecision(int fractionDigits) {
    final mod = pow(10, fractionDigits).toDouble();
    return (this * mod).roundToDouble() / mod;
  }

  bool equals(double other, [double epsilon = 1e-10]) =>
      (this - other).abs() < epsilon;

  double lerp(double a, double b) {
    assert(
      a.isFinite,
      'Cannot interpolate between finite and non-finite values',
    );
    assert(
      b.isFinite,
      'Cannot interpolate between finite and non-finite values',
    );
    assert(isFinite, 't must be finite when interpolating between values');
    return a * (1.0 - this) + b * this;
  }
}
