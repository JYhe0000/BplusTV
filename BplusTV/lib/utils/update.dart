import 'package:bplus_tv/build_config.dart';
import 'package:bplus_tv/http/api.dart';
import 'package:bplus_tv/http/browser_ua.dart';
import 'package:bplus_tv/http/init.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/utils/accounts/account.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/tv_update.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';

abstract final class Update {
  // 检查更新
  static Future<void> checkUpdate([bool isAuto = true]) async {
    if (Api.latestApp.isEmpty) {
      if (!isAuto) SmartDialog.showToast('未配置 TV 更新源');
      return;
    }
    if (kDebugMode && isAuto) return;
    SmartDialog.dismiss();
    try {
      Map<String, dynamic>? data;
      for (int page = 1; data == null; page++) {
        final res = await Request().get(
          Api.latestApp,
          queryParameters: {'per_page': 100, 'page': page},
          options: Options(
            headers: {'user-agent': BrowserUa.mob},
            extra: {'account': const NoAccount()},
          ),
        );
        final releases = res.data;
        if (releases is! List) {
          if (!isAuto) {
            SmartDialog.showToast('检查更新失败，GitHub接口未返回数据，请检查网络');
          }
          return;
        }
        data = TvUpdate.latestRelease(releases);
        if (data == null && releases.length < 100) {
          if (!isAuto) SmartDialog.showToast('当前更新源暂无 TV 安装包');
          return;
        }
      }
      final latest = TvUpdate.releaseTime(data)!.millisecondsSinceEpoch ~/ 1000;
      if (BuildConfig.buildTime >= latest) {
        if (!isAuto) SmartDialog.showToast('已是最新版本');
        return;
      }
      final release = data;
      SmartDialog.show(
        animationType: SmartAnimationType.centerFade_otherSlide,
        builder: (context) {
          final colorScheme = ColorScheme.of(context);
          return tvDialog(
            AlertDialog(
              title: const Text('🎉 发现新版本 '),
              content: SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${release['tag_name']}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text('${release['body']}'),
                      TextButton(
                        onPressed: () => PageUtils.launchURL(
                          Api.appReleases,
                        ),
                        child: Text(
                          '查看 TV 发布记录',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (isAuto)
                  TextButton(
                    onPressed: () {
                      SmartDialog.dismiss();
                      GStorage.setting.put(SettingBoxKey.autoUpdate, false);
                    },
                    child: Text(
                      '不再提醒',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  ),
                TextButton(
                  onPressed: SmartDialog.dismiss,
                  child: Text(
                    '取消',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ),
                TextButton(
                  onPressed: () => onDownload(release),
                  child: const Text('下载安装包'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('failed to check update: $e');
      if (!isAuto) SmartDialog.showToast('检查 TV 更新失败，请稍后重试');
    }
  }

  // 下载适用于当前 Android TV 设备的 APK
  static Future<void> onDownload(Map<String, dynamic> data) async {
    SmartDialog.dismiss();
    if (Api.appReleases.isEmpty) {
      SmartDialog.showToast('未配置 TV 更新源');
      return;
    }
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final url = TvUpdate.apkDownloadUrl(data, androidInfo.supportedAbis);
      if (url != null) {
        PageUtils.launchURL(url);
        return;
      }
      SmartDialog.showToast('未找到适用于此设备的 TV 安装包');
    } catch (e) {
      if (kDebugMode) debugPrint('download error: $e');
    }
    PageUtils.launchURL(Api.appReleases);
  }
}
