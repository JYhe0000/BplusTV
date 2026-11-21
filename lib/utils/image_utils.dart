import 'dart:async' show FutureOr;
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:typed_data' show Uint8List;

import 'package:bplus_tv/common/constants.dart';
import 'package:bplus_tv/http/init.dart';
import 'package:bplus_tv/utils/cache_manager.dart';
import 'package:bplus_tv/utils/device_utils.dart';
import 'package:bplus_tv/utils/extension/string_ext.dart';
import 'package:bplus_tv/utils/global_data.dart';
import 'package:bplus_tv/utils/path_utils.dart';
import 'package:bplus_tv/utils/permission_handler.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';

abstract final class ImageUtils {
  static bool silentDownImg = Pref.silentDownImg;
  static const _albumPath = 'Pictures/${Constants.appName}';

  // 图片分享
  static Future<void> onShareImg(String url) async {
    try {
      SmartDialog.showLoading();
      final res = await CacheManager.manager.getSingleFile(
        url.http2https,
      );
      SmartDialog.dismiss();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(res.path)],
        ),
      );
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  // 获取存储权限
  static Future<bool> requestPer() async {
    final status = await Permission.storage.request();
    if (status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied) {
      final dialog = AlertDialog(
        title: const Text('提示'),
        content: const Text('存储权限未授权'),
        actions: [
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
              openAppSettings();
            },
            child: const Text('去授权'),
          ),
        ],
      );
      SmartDialog.show(
        builder: (context) => tvDialog(dialog),
      );
      return false;
    } else {
      return true;
    }
  }

  static FutureOr<bool> checkPermissionDependOnSdkInt() =>
      DeviceUtils.sdkInt < 29 ? requestPer() : true;

  static Future<bool> downloadLivePhoto({
    required String url,
    required String liveUrl,
    required int width,
    required int height,
  }) async {
    try {
      if (!await checkPermissionDependOnSdkInt()) {
        return false;
      }
      if (!silentDownImg) SmartDialog.showLoading(msg: '正在下载');

      String videoName = "video_${Utils.getFileName(liveUrl)}";
      String videoPath = '$tmpDirPath/$videoName';

      final res = await Request().downloadFile(liveUrl.http2https, videoPath);
      if (res.statusCode != 200) throw '${res.statusCode}';

      if (!silentDownImg) SmartDialog.showLoading(msg: '正在保存');
      await saveFileImg(
        filePath: videoPath,
        fileName: videoName,
        needToast: true,
      );
      return true;
    } catch (err) {
      SmartDialog.showToast(err.toString());
      return false;
    } finally {
      if (!silentDownImg) SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  static Future<bool> downloadImg(List<String> imgList) async {
    if (!await checkPermissionDependOnSdkInt()) {
      return false;
    }
    CancelToken? cancelToken;
    if (!silentDownImg) {
      cancelToken = CancelToken();
      SmartDialog.showLoading(
        msg: '正在下载原图',
        clickMaskDismiss: true,
        onDismiss: cancelToken.cancel,
      );
    }
    try {
      final futures = imgList.map((url) async {
        final name = Utils.getFileName(url);

        final file = await CacheManager.manager.getSingleFile(
          url.http2https,
        );
        return (filePath: file.path, name: name, statusCode: 200);
      });
      final result = await Future.wait(futures, eagerError: true);
      bool success = true;
      final saveList = <SaveFileData>[];
      for (final i in result) {
        if (i.statusCode == 200) {
          saveList.add(
            SaveFileData(
              filePath: i.filePath,
              fileName: i.name,
              albumPath: _albumPath,
            ),
          );
        } else {
          success = false;
        }
      }
      await SaverGallery.saveFiles(saveList, skipIfExists: false);
      if (cancelToken?.isCancelled == true) {
        SmartDialog.showToast('已取消下载');
        return false;
      } else {
        SmartDialog.showToast(success ? ' 已保存 ' : '保存失败');
      }
      return success;
    } catch (e) {
      if (cancelToken?.isCancelled == true) {
        SmartDialog.showToast('已取消下载');
      } else {
        SmartDialog.showToast(e.toString());
      }
      return false;
    } finally {
      if (!silentDownImg) SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  static final _suffixRegex = RegExp(
    r'\.(jpg|jpeg|png|webp|gif|avif)$',
    caseSensitive: false,
  );
  static String safeThumbnailUrl(String? src) {
    if (src != null && _suffixRegex.hasMatch(src)) {
      return thumbnailUrl(src);
    }
    return src.http2https;
  }

  static final _thumbRegex = RegExp(
    r'(@(\d+[a-z]_?)*)(\..*)?$',
    caseSensitive: false,
  );
  static String thumbnailUrl(String? src, [int maxQuality = 1]) {
    if (src != null && maxQuality != 100) {
      maxQuality = math.max(maxQuality, GlobalData().imgQuality);
      bool hasMatch = false;
      src = src.splitMapJoin(
        _thumbRegex,
        onMatch: (match) {
          hasMatch = true;
          String suffix = match.group(3) ?? '.webp';
          return '${match.group(1)}_${maxQuality}q$suffix';
        },
        onNonMatch: (String str) {
          return str;
        },
      );
      if (!hasMatch) {
        src += '@${maxQuality}q.webp';
      }
    }
    return src.http2https;
  }

  static Future<SaveResult?> saveByteImg({
    required Uint8List bytes,
    required String fileName,
    String ext = 'png',
  }) async {
    fileName += '.$ext';
    SmartDialog.showLoading(msg: '正在保存');
    final res = await SaverGallery.saveImage(
      bytes,
      fileName: fileName,
      albumPath: _albumPath,
      skipIfExists: false,
    );
    SmartDialog.dismiss();
    if (res.isSuccess) {
      SmartDialog.showToast(' 已保存 ');
    } else {
      SmartDialog.showToast('保存失败，${res.errorMessage}');
    }
    return res;
  }

  static Future<void> saveFileImg({
    required String filePath,
    required String fileName,
    bool needToast = false,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      SmartDialog.showToast("文件不存在");
      return;
    }
    final res = await SaverGallery.saveFile(
      filePath: filePath,
      fileName: fileName,
      albumPath: _albumPath,
      skipIfExists: false,
    );
    if (needToast) {
      if (res.isSuccess) {
        SmartDialog.showToast(' 已保存 ');
      } else {
        SmartDialog.showToast('保存失败，${res.errorMessage}');
      }
    }
  }
}
