import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:share_plus/share_plus.dart';

abstract final class ShareUtils {
  static Future<void> shareText(String text) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: text),
      );
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }
}
