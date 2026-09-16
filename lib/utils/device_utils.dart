import 'package:PiliPlus/utils/android/bindings.g.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding, Size;

abstract final class DeviceUtils {
  static final int sdkInt = AndroidHelper.sdkInt();

  static final bool isTV = AndroidHelper.isTV;

  static bool get isTablet {
    return size.shortestSide >= 600;
  }

  static Size get size {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }

  static String get platformName => isTV
      ? 'tv'
      : PlatformUtils.isDesktop
      ? 'desktop'
      : isTablet
      ? 'pad'
      : 'phone';
}
