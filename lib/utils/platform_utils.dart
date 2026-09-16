import 'dart:io' show Platform;

import 'package:PiliPlus/utils/android/bindings.g.dart';

abstract final class PlatformUtils {
  @pragma("vm:platform-const")
  static final bool isMobile = Platform.isAndroid || Platform.isIOS;

  @pragma("vm:platform-const")
  static final bool isDesktop =
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @pragma("vm:platform-const")
  static final bool isDarwin = Platform.isIOS || Platform.isMacOS;

  static final bool isTV = Platform.isAndroid && AndroidHelper.isTV;
}
