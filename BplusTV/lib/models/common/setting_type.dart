import 'package:bplus_tv/pages/setting/models/extra_settings.dart';
import 'package:bplus_tv/pages/setting/models/model.dart';
import 'package:bplus_tv/pages/setting/models/play_settings.dart';
import 'package:bplus_tv/pages/setting/models/privacy_settings.dart';
import 'package:bplus_tv/pages/setting/models/recommend_settings.dart';
import 'package:bplus_tv/pages/setting/models/style_settings.dart';
import 'package:bplus_tv/pages/setting/models/ui_style_settings.dart';
import 'package:bplus_tv/pages/setting/models/video_settings.dart';

enum SettingType {
  privacySetting('隐私设置'),
  recommendSetting('推荐流设置'),
  videoSetting('音视频设置'),
  playSetting('播放器设置'),
  uiStyleSetting('风格'),
  styleSetting('外观设置'),
  extraSetting('其它设置'),
  webdavSetting('WebDAV 设置'),
  about('关于'),
  ;

  final String title;
  const SettingType(this.title);

  List<SettingsModel> get settings => switch (this) {
    .privacySetting => privacySettings,
    .recommendSetting => recommendSettings,
    .videoSetting => videoSettings,
    .playSetting => playSettings,
    .uiStyleSetting => uiStyleSettings,
    .styleSetting => styleSettings,
    .extraSetting => extraSettings,
    _ => throw UnimplementedError(),
  };
}
