import 'package:bplus_tv/utils/grid.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('预计算卡片宽度与网格实际布局一致', () {
    final delegate = SliverGridDelegateWithExtentAndRatio(
      maxCrossAxisExtent: 200,
      crossAxisSpacing: 10,
    );

    for (final (extent, columns) in [
      (6.0, 1),
      (220.0, 1),
      (221.0, 2),
      (600.0, 3),
    ]) {
      final layout = delegate.getLayout(
        SliverConstraints(
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          userScrollDirection: ScrollDirection.idle,
          scrollOffset: 0,
          precedingScrollExtent: 0,
          overlap: 0,
          remainingPaintExtent: 400,
          crossAxisExtent: extent,
          crossAxisDirection: AxisDirection.right,
          viewportMainAxisExtent: 400,
          remainingCacheExtent: 400,
          cacheOrigin: 0,
        ),
      ) as SliverGridRegularTileLayout;

      expect(layout.crossAxisCount, columns);
      expect(delegate.tileWidthFor(extent), layout.childCrossAxisExtent);
    }
  });
}
