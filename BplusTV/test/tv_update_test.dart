import 'package:bplus_tv/build_config.dart';
import 'package:bplus_tv/http/api.dart';
import 'package:bplus_tv/utils/tv_update.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> asset(String name) => {
  'name': name,
  'browser_download_url':
      'https://github.com/example/tv/releases/download/$name',
};

Map<String, dynamic> release(
  String tag,
  String createdAt,
  List<Object?> assets, {
  bool draft = false,
}) => {
  'tag_name': tag,
  'created_at': createdAt,
  'assets': assets,
  'draft': draft,
};

void main() {
  test('更新地址只使用构建配置的 TV 仓库，未配置时为空', () {
    const repository = BuildConfig.releaseRepository;
    expect(
      Api.latestApp,
      repository.isEmpty
          ? ''
          : 'https://api.github.com/repos/$repository/releases',
    );
    expect(
      Api.appReleases,
      repository.isEmpty ? '' : 'https://github.com/$repository/releases',
    );
  });

  group('TV 发布筛选', () {
    test('忽略更新的上游手机版，在无序列表中选择最新 TV 发布', () {
      final oldTv = release('tv-old', '2026-11-01T00:00:00Z', [
        asset('BPlus_TV_1.0_arm64-v8a.apk'),
      ]);
      final phone = release('phone', '2026-11-20T00:00:00Z', [
        asset('PiliPlus_2.0_arm64-v8a.apk'),
      ]);
      final newestTv = release('tv-new', '2026-11-18T00:00:00Z', [
        asset('BPlus_TV_1.1_arm64-v8a.apk'),
      ]);

      expect(
        TvUpdate.latestRelease([oldTv, phone, newestTv]),
        same(newestTv),
      );
    });

    test('没有 TV APK 的历史发布和接口错误响应不产生更新', () {
      final phone = release('phone', '2026-11-20T00:00:00Z', [
        asset('PiliPlus_arm64-v8a.apk'),
        asset('BPlus_TV_1.0.zip'),
      ]);
      expect(TvUpdate.latestRelease([phone]), isNull);
      expect(TvUpdate.latestRelease([]), isNull);
      expect(TvUpdate.latestRelease({'message': 'Not Found'}), isNull);
      expect(TvUpdate.latestRelease(null), isNull);
    });

    test('忽略草稿、日期异常和资源数据不完整的发布', () {
      final tvAsset = asset('BPlus_TV_1.0_arm64-v8a.apk');
      expect(
        TvUpdate.latestRelease([
          null,
          'invalid',
          release('draft', '2026-11-20T00:00:00Z', [tvAsset], draft: true),
          release('bad-date', 'invalid', [tvAsset]),
          release('no-url', '2026-11-20T00:00:00Z', [
            {'name': 'BPlus_TV_1.0_arm64-v8a.apk'},
          ]),
          {'assets': null},
        ]),
        isNull,
      );
    });

    test('允许 TV 预发布，并沿用创建时间与本地构建时间比较', () {
      final tv =
          release('nightly', '2026-11-18T00:00:00Z', [
              asset('BPlus_TV_1.0_arm64-v8a.apk'),
            ])
            ..['prerelease'] = true
            ..['published_at'] = '2026-11-20T00:00:00Z';
      expect(TvUpdate.latestRelease([tv]), same(tv));
      expect(TvUpdate.releaseTime(tv), DateTime.utc(2026, 11, 18));
    });
  });

  group('TV 安装包匹配', () {
    test('按设备 ABI 优先级选择 TV APK，不受资源排列顺序影响', () {
      final arm32 = asset('BPlus_TV_1.0_armeabi-v7a.apk');
      final arm64 = asset('BPlus_TV_1.0_arm64-v8a.apk');
      final tv = release('tv', '2026-11-20T00:00:00Z', [arm32, arm64]);
      expect(
        TvUpdate.apkDownloadUrl(tv, ['arm64-v8a', 'armeabi-v7a']),
        arm64['browser_download_url'],
      );
      expect(
        TvUpdate.apkDownloadUrl(tv, ['x86_64', 'armeabi-v7a']),
        arm32['browser_download_url'],
      );
    });

    test('拒绝手机版、ABI 子串、额外文件后缀和没有版本的包名', () {
      final tv = release('tv', '2026-11-20T00:00:00Z', [
        asset('PiliPlus_1.0_arm64-v8a.apk'),
        asset('BPlus_TV_arm64-v8a_1.0_x86_64.apk'),
        asset('BPlus_TV_1.0_not-arm64-v8a.apk'),
        asset('BPlus_TV_1.0_arm64-v8a.apk.zip'),
        asset('BPlus_TV_arm64-v8a.apk'),
      ]);
      expect(TvUpdate.apkDownloadUrl(tv, ['arm64-v8a']), isNull);
    });

    test('无兼容 ABI、空 ABI 列表或错误资源数据时不返回通用 APK', () {
      final tv = release('tv', '2026-11-20T00:00:00Z', [
        asset('BPlus_TV_1.0_arm64-v8a.apk'),
        asset('BPlus_TV_1.0_android.apk'),
        null,
      ]);
      expect(TvUpdate.apkDownloadUrl(tv, ['x86_64']), isNull);
      expect(TvUpdate.apkDownloadUrl(tv, []), isNull);
      expect(TvUpdate.apkDownloadUrl(tv, ['']), isNull);
      expect(TvUpdate.apkDownloadUrl({'assets': null}, ['arm64-v8a']), isNull);
    });
  });
}
