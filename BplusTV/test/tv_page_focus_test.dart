import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('page restores focus when the focused control is removed', (
    tester,
  ) async {
    const firstKey = ValueKey('first-control');
    const secondKey = ValueKey('second-control');
    var showFirst = true;
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: TvPageFocus(
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Column(
                children: [
                  if (showFirst)
                    Focus(
                      autofocus: true,
                      child: const SizedBox(
                        key: firstKey,
                        width: 48,
                        height: 48,
                      ),
                    ),
                  Focus(
                    child: const SizedBox(
                      key: secondKey,
                      width: 48,
                      height: 48,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(Focus.of(tester.element(find.byKey(firstKey))).hasFocus, isTrue);

    update(() => showFirst = false);
    await tester.pumpAndSettle();

    expect(Focus.of(tester.element(find.byKey(secondKey))).hasFocus, isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}
