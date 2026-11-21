import 'dart:io' show Directory, File;

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

abstract final class AssetUtils {
  // Android 资源打包在 APK 中，先复制到文件目录供 mpv 读取。
  static Future<String> getOrCopy(
    String src,
    Iterable<String> files,
    String dst,
  ) async {
    final dstDir = Directory(dst);
    if (!dstDir.existsSync()) {
      await dstDir.create(recursive: true);
    }

    for (final file in files) {
      final targetFile = File(path.join(dst, file));
      if (targetFile.existsSync()) {
        continue;
      }

      try {
        final data = await rootBundle.load(path.posix.join(src, file));
        await targetFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } catch (_) {}
    }
    return dst;
  }
}
