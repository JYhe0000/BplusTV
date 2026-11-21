import 'package:bplus_tv/utils/extension/num_ext.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('相近封面尺寸复用缓存，解码尺寸不低于实际像素', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 2),
        child: Builder(
          builder: (context) {
            expect(160.1.cacheSize(context), 352);
            expect(175.cacheSize(context), 352);
            expect(176.1.cacheSize(context), 384);
            expect(24.cacheSize(context), 48);
            expect(0.cacheSize(context), isNull);
            expect((-1).cacheSize(context), isNull);
            expect(double.infinity.cacheSize(context), isNull);
            expect(double.nan.cacheSize(context), isNull);
            return const SizedBox();
          },
        ),
      ),
    );
  });
}
