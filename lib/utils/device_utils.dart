import 'package:bplus_tv/utils/android/bindings.g.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding, Size;

abstract final class DeviceUtils {
  static final int sdkInt = AndroidHelper.sdkInt();

  static const bool isTV = true;

  static const bool isTablet = false;

  static Size get size {
    // 无 view（极少数嵌入场景）时回落到 implicitView，仍无则返回零尺寸
    final view =
        WidgetsBinding.instance.platformDispatcher.views.firstOrNull ??
        WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) {
      return Size.zero;
    }
    return view.physicalSize / view.devicePixelRatio;
  }

  static String get platformName => 'tv';
}
