import 'dart:io';

import 'package:bplus_tv/common/widgets/route_aware_mixin.dart';
import 'package:bplus_tv/models/common/ui_style.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = Directory.systemTemp.createTempSync('tv_root_smoke');
    Hive.init(hiveDir.path);
    GStorage.setting = await Hive.openBox<dynamic>('setting');
    await GStorage.setting.put(SettingBoxKey.uiStyle, UiStyle.netflix.index);
  });

  tearDownAll(() async {
    await Hive.close();
    hiveDir.deleteSync(recursive: true);
  });

  testWidgets('TV 返回栏支持方向键、确认键和返回后的焦点恢复', (tester) async {
    final launchFocus = FocusNode(debugLabel: 'launch');
    final actionFocus = FocusNode(debugLabel: 'action');
    var activations = 0;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      launchFocus.dispose();
      actionFocus.dispose();
      Get.reset();
    });

    Widget detailsPage() => TvPageFocus(
      child: Scaffold(
        appBar: tvBackBar(
          actions: [
            SizedBox(
              width: 60,
              child: TvFocusable(
                focusNode: actionFocus,
                onTap: () => activations++,
                builder: (_, focused, hovered) => TvFocusHighlight(
                  focused: focused,
                  child: const Center(child: Icon(Icons.refresh)),
                ),
              ),
            ),
          ],
        ),
        body: const Center(child: Text('详情页面')),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        navigatorObservers: [routeObserver],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            navigationMode: NavigationMode.directional,
          ),
          child: child!,
        ),
        home: TvPageFocus(
          child: Scaffold(
            body: Center(
              child: TvFocusable(
                focusNode: launchFocus,
                onTap: () => Get.to<void>(detailsPage),
                builder: (_, focused, hovered) => TvFocusHighlight(
                  focused: focused,
                  child: const SizedBox(
                    width: 160,
                    height: 56,
                    child: Center(child: Text('打开详情')),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(launchFocus.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('详情页面'), findsOneWidget);
    final backHighlight = find.descendant(
      of: find.byType(TvBackButton),
      matching: find.byType(TvFocusHighlight),
    );
    expect(tester.widget<TvFocusHighlight>(backHighlight).focused, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(actionFocus.hasPrimaryFocus, isTrue);
    expect(tester.widget<TvFocusHighlight>(backHighlight).focused, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(activations, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(tester.widget<TvFocusHighlight>(backHighlight).focused, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('详情页面'), findsNothing);
    expect(find.text('打开详情'), findsOneWidget);
    expect(launchFocus.hasPrimaryFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}
