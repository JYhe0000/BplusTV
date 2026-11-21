import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// 直接使用列表获得的空间计算列数，避免导航栏和安全区改变后卡片过窄。
class LiveTvGridDelegate extends SliverGridDelegate {
  const LiveTvGridDelegate({required this.infoHeight});

  final double infoHeight;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const spacing = 16.0;
    final extent = constraints.crossAxisExtent;
    final preferredWidth = (extent * 0.08 + 180).clamp(240.0, 320.0).toDouble();
    final columns = ((extent + spacing) / (preferredWidth + spacing))
        .round()
        .clamp(1, 6)
        .toInt();
    final width = math.max(0.0, extent - spacing * (columns - 1)) / columns;
    final height = width / (16 / 9) + infoHeight;
    return SliverGridRegularTileLayout(
      crossAxisCount: columns,
      mainAxisStride: height + spacing,
      crossAxisStride: width + spacing,
      childMainAxisExtent: height,
      childCrossAxisExtent: width,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(LiveTvGridDelegate oldDelegate) =>
      oldDelegate.infoHeight != infoHeight;
}
