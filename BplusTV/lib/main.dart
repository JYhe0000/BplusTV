import 'dart:io';

import 'package:bplus_tv/build_config.dart';
import 'package:bplus_tv/common/constants.dart';
import 'package:bplus_tv/common/widgets/custom_toast.dart';
import 'package:bplus_tv/common/widgets/netflix_style.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/common/widgets/route_aware_mixin.dart';
import 'package:bplus_tv/common/widgets/scale_app.dart';
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:bplus_tv/http/init.dart';
import 'package:bplus_tv/plugin/pl_player/utils/fullscreen.dart';
import 'package:bplus_tv/router/app_pages.dart';
import 'package:bplus_tv/services/account_service.dart';
import 'package:bplus_tv/services/download/download_service.dart';
import 'package:bplus_tv/services/logger.dart';
import 'package:bplus_tv/services/service_locator.dart';
import 'package:bplus_tv/smartisan/smartisan_motion.dart'
    show AdaptiveTvScrollBehavior;
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/cache_manager.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/extension/core_palettes_ext.dart';
import 'package:bplus_tv/utils/font_utils.dart';
import 'package:bplus_tv/utils/json_file_handler.dart';
import 'package:bplus_tv/utils/path_utils.dart';
import 'package:bplus_tv/utils/request_utils.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:bplus_tv/utils/theme_utils.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:catcher_2/catcher_2.dart';
import 'package:collection/collection.dart';
import 'package:dynamic_color/dynamic_color.dart' show DynamicColorPlugin;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

EdgeInsets? tmpPadding;

Future<void> _initDownPath() async {
  if (Platform.isAndroid) {
    final externalStorageDirPath = (await getExternalStorageDirectory())?.path;
    downloadPath = externalStorageDirPath != null
        ? path.join(externalStorageDirPath, PathUtils.downloadDir)
        : defDownloadPath;
  } else {
    downloadPath = defDownloadPath;
  }
}

Future<void> _initTmpPath() async {
  tmpDirPath = (await getTemporaryDirectory()).path;
}

Future<void> _initAppPath() async {
  appSupportDirPath = (await getApplicationSupportDirectory()).path;
}

void main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  PaintingBinding.instance.imageCache
    ..maximumSize = 300
    ..maximumSizeBytes = 64 << 20;
  await _initAppPath();
  try {
    await GStorage.init();
  } catch (e) {
    await Utils.copyText(e.toString());
    if (kDebugMode) debugPrint('GStorage init error: $e');
    exit(0);
  }
  ScaledWidgetsFlutterBinding.instance.scaleFactor = Pref.uiScale;
  final fontInit = FontUtils.init();
  await Future.wait([
    _initDownPath(),
    _initTmpPath(),
    CacheManager.ensureInitialized(),
    ?fontInit,
  ]);
  Get
    ..lazyPut(AccountService.new)
    ..lazyPut(DownloadService.new);
  HttpOverrides.global = _CustomHttpOverrides();

  if (Platform.isAndroid) {
    await Future.wait([
      ?fullMode(),
      setupServiceLocator(),
    ]);
  }

  Request();
  Request.setCookie();
  RequestUtils.syncHistoryStatus();

  SmartDialog.config.toast = SmartConfigToast(displayType: .onlyRefresh);

  if (Platform.isAndroid) {
    await hideSystemBar();
    FlutterDisplayMode.supported.then((mode) {
      final String? storageDisplay = GStorage.setting.get(
        SettingBoxKey.displayMode,
      );
      DisplayMode? displayMode;
      if (storageDisplay != null) {
        displayMode = mode.firstWhereOrNull(
          (e) => e.toString() == storageDisplay,
        );
      }
      FlutterDisplayMode.setPreferredMode(displayMode ?? DisplayMode.auto);
    });
  }

  if (Pref.dynamicColor) {
    await MyApp.initPlatformState();
  }

  if (Pref.enableLog) {
    // 异常捕获 logo记录
    final customParameters = {
      'Build Time': DateFormatUtils.format(
        BuildConfig.buildTime,
        format: DateFormatUtils.longFormatDs,
      ),
      'Commit Hash': BuildConfig.commitHash,
      'MPV Api Version':
          '${NativePlayer.apiVersion >> 16}.${NativePlayer.apiVersion & 0xFFFF}',
    };
    final fileHandler = await JsonFileHandler.init();

    Catcher2(
      [?fileHandler, const ConsoleHandler()],
      const MyApp(),
      logger: logger,
      customParameters: customParameters,
    );
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static ColorScheme? _light, _dark;

  static (ThemeData, ThemeData) getAllTheme() {
    if (Pref.uiStyle.isSmartisan) {
      return (
        ThemeUtils.lightTheme = SmartisanStyle.themeData(isDark: false),
        ThemeUtils.darkTheme = SmartisanStyle.themeData(isDark: true),
      );
    }
    // 默认主题固定使用黑灰底、白字与红色强调，保持影院界面一致。
    final theme = NetflixStyle.themeData();
    return (
      ThemeUtils.lightTheme = theme,
      ThemeUtils.darkTheme = theme,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (light, dark) = getAllTheme();
    return GetMaterialApp(
      title: Constants.appName,
      theme: light,
      darkTheme: dark,
      themeMode: ThemeUtils.themeMode = Pref.themeMode,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      locale: const Locale("zh", "CN"),
      fallbackLocale: const Locale("zh", "CN"),
      supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
      initialRoute: '/',
      getPages: Routes.getPages,
      defaultTransition: Pref.pageTransition,
      builder: FlutterSmartDialog.init(
        toastBuilder: CustomToast.new,
        loadingBuilder: LoadingWidget.new,
        notifyStyle: const FlutterSmartNotifyStyle(
          warningBuilder: NotifyWarning.new,
        ),
        builder: _builder,
      ),
      navigatorObservers: [
        routeObserver,
        FlutterSmartDialog.observer,
      ],
      scrollBehavior: const AdaptiveTvScrollBehavior(),
    );
  }

  static Widget _builder(BuildContext context, Widget? child) {
    // 在缩放后的 MediaQuery 内消费安全区，让后代外壳复用已应用的边距。
    child = ViewSafeArea(
      top: true,
      bottom: true,
      minimum: TvConstants.overscan,
      child: child!,
    );
    final uiScale = Pref.uiScale;
    final mediaQuery = MediaQuery.of(context).copyWith(
      navigationMode: NavigationMode.directional,
    );
    // 在用户字号偏好上应用紧凑基准，子页面与首页使用相同的文字比例。
    final textScaler = TextScaler.linear(
      Pref.defaultTextScale.clamp(0.85, 1.6) * TvConstants.compactTextScale,
    );
    // `tmpPadding` is only set while the gallery viewer is open (it suppresses
    // the app padding). Outside that window it is null and must not blank the
    // real insets.
    final overridePadding = tmpPadding;
    if (uiScale != 1.0) {
      child = MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: textScaler,
          size: mediaQuery.size / uiScale,
          padding: overridePadding ?? mediaQuery.padding / uiScale,
          viewInsets: mediaQuery.viewInsets / uiScale,
          viewPadding: overridePadding ?? mediaQuery.viewPadding / uiScale,
          devicePixelRatio: mediaQuery.devicePixelRatio * uiScale,
        ),
        child: child,
      );
    } else {
      child = MediaQuery(
        data: overridePadding == null
            ? mediaQuery.copyWith(textScaler: textScaler)
            : mediaQuery.copyWith(
                textScaler: textScaler,
                padding: overridePadding,
                viewPadding: overridePadding,
              ),
        child: child,
      );
    }
    child = FocusTraversalGroup(
      policy: TvFocusTraversalPolicy(),
      child: child,
    );
    return child;
  }

  /// from [DynamicColorBuilderState.initPlatformState]
  static Future<bool> initPlatformState() async {
    if (!Platform.isAndroid) return false;
    if (_light != null || _dark != null) return true;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      final colors = await DynamicColorPlugin.channel.invokeMethod(
        DynamicColorPlugin.methodName,
      );

      if (colors != null) {
        final corePalettes = CorePalettesExt.fromList(colors.toList());
        if (kDebugMode) {
          debugPrint('dynamic_color: Core palette detected.');
        }
        _light = corePalettes.toColorScheme();
        _dark = corePalettes.toColorScheme(brightness: Brightness.dark);
        return true;
      }
    } on PlatformException {
      if (kDebugMode) {
        debugPrint('dynamic_color: Failed to obtain core palette.');
      }
    }

    if (kDebugMode) {
      debugPrint('dynamic_color: Dynamic color not detected on this device.');
    }
    GStorage.setting.put(SettingBoxKey.dynamicColor, false);
    return false;
  }
}

class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    // ..maxConnectionsPerHost = 32
    /// The default value is 15 seconds.
    //   ..idleTimeout = const Duration(seconds: 15);
    if (kDebugMode || Pref.badCertificateCallback) {
      client.badCertificateCallback = (cert, host, port) => true;
    }
    return client;
  }
}
