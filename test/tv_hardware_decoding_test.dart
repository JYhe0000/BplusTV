import 'dart:io';

import 'package:bplus_tv/plugin/pl_player/models/hwdec_type.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'tv_hardware_decoding_',
    );
    Hive.init(hiveDirectory.path);
    GStorage.setting = await Hive.openBox<dynamic>('setting');
  });

  setUp(() async {
    await GStorage.setting.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  group('Pref.hardwareDecoding 兼容旧配置', () {
    test('有效 Android 解码器及逗号组合保留原顺序', () async {
      final configurations = [
        for (final type in HwDecType.values) type.hwdec,
        'mediacodec-copy,auto-copy,auto-safe',
        'auto-safe,mediacodec,auto',
        'no,auto,auto-safe,auto-copy,mediacodec,mediacodec-copy',
      ];

      for (final configuration in configurations) {
        await GStorage.setting.put(
          SettingBoxKey.hardwareDecoding,
          configuration,
        );

        expect(Pref.hardwareDecoding, configuration, reason: configuration);
      }
    });

    test('混合桌面项时过滤不支持的解码器并保留有效项顺序', () async {
      const configurations = [
        (
          'd3d11va,mediacodec-copy,videotoolbox,auto-copy,vaapi',
          'mediacodec-copy,auto-copy',
        ),
        (
          ' nvdec, auto-safe , videotoolbox-copy, mediacodec , ',
          'auto-safe,mediacodec',
        ),
      ];

      for (final (configuration, expected) in configurations) {
        await GStorage.setting.put(
          SettingBoxKey.hardwareDecoding,
          configuration,
        );

        expect(Pref.hardwareDecoding, expected, reason: configuration);
      }
    });

    test('缺失、空白或全部无效的配置回退到 Android 默认组合', () async {
      expect(Pref.hardwareDecoding, HwDecType.androidDefault);

      const configurations = [
        '',
        ' ,  , ',
        'd3d11va,videotoolbox,vaapi,nvdec',
        'unknown',
      ];

      for (final configuration in configurations) {
        await GStorage.setting.put(
          SettingBoxKey.hardwareDecoding,
          configuration,
        );

        expect(
          Pref.hardwareDecoding,
          HwDecType.androidDefault,
          reason: configuration,
        );
      }
    });

    test('旧备份中的非字符串配置读取不崩溃并回退', () async {
      const configurations = <Object?>[
        null,
        42,
        true,
        ['mediacodec', 'videotoolbox'],
        {'hwdec': 'd3d11va'},
      ];

      for (final configuration in configurations) {
        await GStorage.setting.put(
          SettingBoxKey.hardwareDecoding,
          configuration,
        );

        expect(
          () => Pref.hardwareDecoding,
          returnsNormally,
          reason: '$configuration',
        );
        expect(
          Pref.hardwareDecoding,
          HwDecType.androidDefault,
          reason: '$configuration',
        );
      }
    });
  });
}
