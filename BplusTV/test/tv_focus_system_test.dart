import 'dart:io';

import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_option_picker.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = Directory.systemTemp.createTempSync('tv_focus_system');
    Hive.init(hiveDir.path);
    GStorage.setting = await Hive.openBox<dynamic>('setting');
  });

  tearDownAll(() async {
    await Hive.close();
    hiveDir.deleteSync(recursive: true);
  });

  testWidgets('无激活回调的焦点容器不吞上层确认键', (tester) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
          },
          child: Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  activations++;
                  return null;
                },
              ),
            },
            child: TvFocusable(
              autofocus: true,
              builder: (_, focused, hovered) => const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(activations, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('确认键不连发且支持手柄 A', (tester) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TvFocusable(
          autofocus: true,
          onTap: () => activations++,
          builder: (_, focused, hovered) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    expect(activations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
    expect(activations, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('禁用控件不接受指针激活', (tester) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TvFocusable(
          canRequestFocus: false,
          onTap: () => activations++,
          builder: (_, focused, hovered) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.tap(find.byType(TvFocusable), warnIfMissed: false);
    expect(activations, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('方向导航模式跳过禁用项', (tester) async {
    final disabled = FocusNode();
    final enabled = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            navigationMode: NavigationMode.directional,
          ),
          child: TvDialogScope(
            child: Column(
              children: [
                TvFocusable(
                  focusNode: disabled,
                  canRequestFocus: false,
                  builder: (_, focused, hovered) => const Text('禁用项'),
                ),
                TvFocusable(
                  focusNode: enabled,
                  onTap: () {},
                  builder: (_, focused, hovered) => const Text('可用项'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(disabled.canRequestFocus, isFalse);
    expect(enabled.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    disabled.dispose();
    enabled.dispose();
  });

  testWidgets('嵌套弹窗只由顶层接管并在关闭后恢复原项', (tester) async {
    final first = FocusNode();
    final second = FocusNode();
    final inner = FocusNode();
    var showInner = false;
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Stack(
              children: [
                TvDialogScope(
                  child: Column(
                    children: [
                      Focus(focusNode: first, child: const Text('第一项')),
                      Focus(focusNode: second, child: const Text('第二项')),
                    ],
                  ),
                ),
                if (showInner)
                  TvDialogScope(
                    child: Focus(focusNode: inner, child: const Text('顶层弹窗')),
                  ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    second.requestFocus();
    await tester.pumpAndSettle();
    update(() => showInner = true);
    await tester.pumpAndSettle();
    expect(inner.hasPrimaryFocus, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(inner.hasPrimaryFocus, isTrue);

    update(() => showInner = false);
    await tester.pumpAndSettle();
    expect(second.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(TvDialogScopes.hasOpenDialog, isFalse);
    first.dispose();
    second.dispose();
    inner.dispose();
  });

  testWidgets('对话框显式指定的默认按钮不与第一项竞争', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: tvDialogShell(
          title: '选择操作',
          content: const Text('测试内容'),
          actions: [
            TvDialogAction(label: '取消', onTap: () {}),
            TvDialogAction(label: '继续', autofocus: true, onTap: () {}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final buttons = tester.widgetList<TvFocusable>(find.byType(TvFocusable));
    expect(buttons.where((button) => button.autofocus), hasLength(1));
    expect(Focus.of(tester.element(find.text('继续'))).hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('长选项列表初始定位到屏外当前项', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTvOptionPicker<int>(
              context: context,
              title: '长列表',
              current: 80,
              options: List.generate(
                100,
                (index) => TvOption(value: index, label: '选项 $index'),
              ),
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('选项 80'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('选项 80'))).hasFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('当前选项禁用时默认聚焦第一项可用选项', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTvOptionPicker<int>(
              context: context,
              title: '可用选项',
              current: 0,
              options: const [
                TvOption(value: 0, label: '不可用', enabled: false),
                TvOption(value: 1, label: '可用'),
              ],
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('可用'))).hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('页面被路由覆盖时不抢焦点，返回后保留原项', (tester) async {
    final first = FocusNode();
    final second = FocusNode();
    final next = FocusNode();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: TvPageFocus(
          child: Column(
            children: [
              Focus(focusNode: first, child: const Text('原页第一项')),
              Focus(focusNode: second, child: const Text('原页第二项')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    second.requestFocus();
    await tester.pumpAndSettle();
    navigator.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Focus(
          focusNode: next,
          autofocus: true,
          child: const Text('下一页'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(next.hasPrimaryFocus, isTrue);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(second.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    first.dispose();
    second.dispose();
    next.dispose();
  });
}
