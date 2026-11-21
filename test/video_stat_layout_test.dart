import 'package:bplus_tv/common/widgets/stat/stat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('video stats fit 107px at text scale $scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const Center(
              child: SizedBox(
                width: 107,
                child: Row(
                  spacing: 8,
                  children: [
                    Flexible(child: StatWidget(type: .play, value: 12345678)),
                    Flexible(child: StatWidget(type: .danmaku, value: 987654)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(StatWidget), findsNWidgets(2));
    });
  }
}
