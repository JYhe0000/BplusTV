import 'dart:io';

import 'package:bplus_tv/common/widgets/main_layout.dart';
import 'package:bplus_tv/tv/tv_card.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_focus_viewport.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  // TvFocusHighlight reads the glass-style preference, which lives in Hive.
  // The widget tests never run the app bootstrap, so open a throwaway box.
  final hiveDir = Directory.systemTemp.createTempSync('pili_tv_test');
  setUpAll(() async {
    Hive.init(hiveDir.path);
    GStorage.setting = await Hive.openBox<dynamic>('setting');
  });
  tearDownAll(() async {
    await Hive.close();
    hiveDir.deleteSync(recursive: true);
  });

  testWidgets(
    'D-pad reveal keeps the animated halo inside the paint viewport',
    (
      tester,
    ) async {
      final nodes = List.generate(24, (_) => FocusNode());
      final scroll = ScrollController();
      var activations = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 600,
              height: 360,
              child: FocusTraversalGroup(
                policy: TvFocusTraversalPolicy(),
                child: TvFocusViewport(
                  maxCardSize: const Size(300, 100),
                  child: GridView.count(
                    controller: scroll,
                    clipBehavior: Clip.none,
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 100,
                    children: List.generate(
                      nodes.length,
                      (index) => TvCard(
                        focusNode: nodes[index],
                        autofocus: index == 0,
                        onTap: () => activations++,
                        child: const ColoredBox(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      void expectHaloVisible(int index) {
        expect(nodes[index].hasFocus, isTrue);
        final card = find.byWidgetPredicate(
          (widget) => widget is TvCard && widget.focusNode == nodes[index],
        );
        final highlight = find.descendant(
          of: card,
          matching: find.byType(TvFocusHighlight),
        );
        final box = tester.renderObject<RenderBox>(highlight);
        // Check the painted halo, including the actual animated transform.
        final halo = MatrixUtils.transformRect(
          box.getTransformTo(null),
          (Offset.zero & box.size).inflate(6),
        );
        final viewport = tester.getRect(find.byType(TvFocusViewport));
        expect(halo.left, greaterThanOrEqualTo(viewport.left));
        expect(halo.top, greaterThanOrEqualTo(viewport.top));
        expect(halo.right, lessThanOrEqualTo(viewport.right));
        expect(halo.bottom, lessThanOrEqualTo(viewport.bottom));
      }

      Future<void> move(LogicalKeyboardKey key, int index) async {
        await tester.sendKeyEvent(key);
        await tester.pump();
        // The reveal itself takes TvConstants.focusScrollDuration; let it settle
        // before watching the faster halo animation.
        for (var frame = 0; frame < 32; frame++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        for (var frame = 0; frame < 16; frame++) {
          await tester.pump(const Duration(milliseconds: 10));
          expectHaloVisible(index);
        }
      }

      expectHaloVisible(0);
      await move(LogicalKeyboardKey.arrowRight, 1);
      await move(LogicalKeyboardKey.arrowLeft, 0);
      for (var index = 2; index <= 22; index += 2) {
        await move(LogicalKeyboardKey.arrowDown, index);
      }
      expect(scroll.offset, greaterThan(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activations, 1);
      for (var index = 20; index >= 0; index -= 2) {
        await move(LogicalKeyboardKey.arrowUp, index);
      }
      expect(scroll.offset, closeTo(0, 0.01));
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
      for (final node in nodes) {
        node.dispose();
      }
    },
  );

  testWidgets('TV body reserves the measured bottom bar and relayouts', (
    tester,
  ) async {
    const bodyKey = ValueKey('body');
    const navKey = ValueKey('nav');
    Future<void> build(bool reserve, double height) => tester.pumpWidget(
      MaterialApp(
        home: MainLayout(
          reserveBottomNav: reserve,
          sideBar: null,
          bottomNav: SizedBox(key: navKey, height: height, width: 300),
          body: const SizedBox.expand(key: bodyKey),
        ),
      ),
    );
    await build(true, 80);
    expect(
      tester.getRect(find.byKey(bodyKey)).bottom,
      tester.getRect(find.byKey(navKey)).top,
    );
    await build(true, 120);
    expect(
      tester.getRect(find.byKey(bodyKey)).bottom,
      tester.getRect(find.byKey(navKey)).top,
    );
    await build(false, 120);
    expect(
      tester.getRect(find.byKey(bodyKey)).bottom,
      tester.getRect(find.byKey(navKey)).bottom,
    );
  });
}
