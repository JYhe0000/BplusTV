import 'dart:io';

import 'package:bplus_tv/common/widgets/flutter/pop_scope.dart' as app_pop;
import 'package:bplus_tv/common/widgets/route_aware_mixin.dart';
import 'package:bplus_tv/pages/setting/view.dart';
import 'package:bplus_tv/utils/accounts.dart';
import 'package:bplus_tv/utils/accounts/account.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = Directory.systemTemp.createTempSync('setting_back_focus');
    Hive.init(hiveDir.path);
    GStorage.setting = await Hive.openBox<dynamic>('setting');
    GStorage.video = await Hive.openBox<dynamic>('video');
    GStorage.localCache = await Hive.openBox<dynamic>('localCache');
    Accounts.account = await Hive.openBox<LoginAccount>('account');
  });

  tearDownAll(() async {
    await Hive.close();
    hiveDir.deleteSync(recursive: true);
  });

  for (final width in [800.0, 1280.0]) {
    testWidgets('设置详情返回先恢复所选类别焦点，再次返回退出设置（宽 $width）', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final hostFocus = FocusNode(debugLabel: 'settings-host');
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        Get.reset();
        hostFocus.dispose();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          navigatorObservers: [routeObserver],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              navigationMode: NavigationMode.directional,
            ),
            child: child!,
          ),
          home: _SettingsHost(focusNode: hostFocus),
        ),
      );
      await tester.pumpAndSettle();
      expect(hostFocus.hasPrimaryFocus, isTrue);

      Get.to<void>(() => const SettingPage());
      await tester.pumpAndSettle();

      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'recommendSetting',
      );

      await tester.sendKeyEvent(
        width >= 1050
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.select,
      );
      await tester.pumpAndSettle();
      expect(find.text('首页使用app端推荐'), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('recommendSetting'),
      );
      expect(
        tester.widget<app_pop.PopScope>(find.byType(app_pop.PopScope)).canPop,
        isFalse,
      );
      expect(
        ModalRoute.of(tester.element(find.byType(SettingPage)))?.popDisposition,
        RoutePopDisposition.doNotPop,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('原页面'), findsNothing);
      expect(find.text('推荐流设置'), findsNWidgets(2));
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'recommendSetting',
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('原页面'), findsOneWidget);
      expect(find.text('推荐流设置'), findsNothing);
      expect(hostFocus.hasPrimaryFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}

class _SettingsHost extends StatelessWidget {
  const _SettingsHost({required this.focusNode});

  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Focus(
        focusNode: focusNode,
        autofocus: true,
        child: const Text('原页面'),
      ),
    ),
  );
}
