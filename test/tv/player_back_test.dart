import 'package:bplus_tv/common/widgets/flutter/pop_scope.dart' as app_pop;
import 'package:bplus_tv/tv/player/tv_header_control.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final remote in [false, true]) {
    testWidgets('播放器左上返回按钮直接退出，${remote ? '遥控器确认' : '点击'}不只收起控制条', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      final popResults = <bool>[];
      var controlsVisible = true;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('视频详情')),
        ),
      );
      navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => app_pop.PopScope(
              canPop: !controlsVisible,
              onPopInvokedWithResult: (didPop, _) {
                popResults.add(didPop);
                if (!didPop) setState(() => controlsVisible = false);
              },
              child: Scaffold(
                body: Column(
                  children: [
                    if (controlsVisible) const TvHeaderControl(title: '测试视频'),
                    const Expanded(child: Center(child: Text('播放器'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final back = find.descendant(
        of: find.byType(TvHeaderControl),
        matching: find.byType(TvFocusable),
      );
      expect(back, findsOneWidget);
      if (remote) {
        final gesture = find.descendant(
          of: back,
          matching: find.byType(GestureDetector),
        );
        Focus.of(tester.element(gesture)).requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
      } else {
        await tester.tap(back);
      }
      await tester.pumpAndSettle();

      expect(find.text('视频详情'), findsOneWidget);
      expect(find.text('播放器'), findsNothing);
      expect(popResults, [true]);
      expect(controlsVisible, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
