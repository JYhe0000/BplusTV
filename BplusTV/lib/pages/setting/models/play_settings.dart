import 'package:bplus_tv/common/widgets/custom_icon.dart';
import 'package:bplus_tv/models/common/super_chat_type.dart';
import 'package:bplus_tv/models/common/video/subtitle_pref_type.dart';
import 'package:bplus_tv/pages/setting/models/model.dart';
import 'package:bplus_tv/pages/setting/pages/fullscreen_sc_size.dart';
import 'package:bplus_tv/pages/setting/widgets/select_dialog.dart';
import 'package:bplus_tv/plugin/pl_player/models/bottom_progress_behavior.dart';
import 'package:bplus_tv/plugin/pl_player/models/play_repeat.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

List<SettingsModel> get playSettings => [
  const SwitchModel(
    title: '弹幕开关',
    subtitle: '是否展示弹幕',
    leading: Icon(CustomIcons.dm_settings),
    setKey: SettingBoxKey.enableShowDanmaku,
    defaultVal: true,
  ),
  NormalModel(
    onTap: (context, setState) => Get.toNamed('/playSpeedSet'),
    leading: const Icon(Icons.speed_outlined),
    title: '倍速设置',
    subtitle: '设置视频播放速度',
  ),
  const SwitchModel(
    title: '自动播放',
    subtitle: '进入详情页自动播放',
    leading: Icon(Icons.motion_photos_auto_outlined),
    setKey: SettingBoxKey.autoPlayEnable,
    defaultVal: false,
  ),
  NormalModel(
    title: '自动启用字幕',
    leading: const Icon(Icons.closed_caption_outlined),
    getSubtitle: () => '当前选择偏好：${Pref.subtitlePreferenceV2.desc}',
    onTap: _showSubtitleDialog,
  ),
  PopupModel(
    title: 'SuperChat (醒目留言) 显示类型',
    leading: const Icon(Icons.live_tv),
    value: () => Pref.superChatType,
    items: SuperChatType.values,
    onSelected: (value, setState) => GStorage.setting
        .put(SettingBoxKey.superChatType, value.index)
        .whenComplete(setState),
  ),
  NormalModel(
    title: '全屏 SC 大小',
    subtitle: 'SuperChat (醒目留言) 大小设置',
    leading: const Icon(Icons.open_in_full),
    onTap: (_, _) => Get.to(const FullScreenScSize()),
  ),
  const SwitchModel(
    title: '延长播放控件显示时间',
    subtitle: '开启后延长至30秒，便于屏幕阅读器滑动切换控件焦点',
    leading: Icon(Icons.timer_outlined),
    setKey: SettingBoxKey.enableLongShowControl,
    defaultVal: false,
  ),
  const SwitchModel(
    title: '全屏展示点赞/投币/收藏等操作按钮',
    leading: Icon(MdiIcons.dotsHorizontalCircleOutline),
    setKey: SettingBoxKey.showFSActionItem,
    defaultVal: true,
  ),
  const SwitchModel(
    title: '观看人数',
    subtitle: '展示同时在看人数',
    leading: Icon(Icons.people_outlined),
    setKey: SettingBoxKey.enableOnlineTotal,
    defaultVal: false,
  ),
  PopupModel(
    title: '底部进度条展示',
    leading: const Icon(Icons.border_bottom_outlined),
    value: () => Pref.btmProgressBehavior,
    items: BtmProgressBehavior.values,
    onSelected: (value, setState) => GStorage.setting
        .put(SettingBoxKey.btmProgressBehavior, value.index)
        .whenComplete(setState),
  ),
  PopupModel(
    title: '播放顺序',
    leading: const Icon(Icons.repeat),
    value: () => Pref.playRepeat,
    items: PlayRepeat.values,
    onSelected: (value, setState) => GStorage.video
        .put(VideoBoxKey.playRepeat, value.index)
        .whenComplete(setState),
  ),
  const SwitchModel(
    title: '播放器设置仅对当前生效',
    subtitle: '弹幕、字幕及部分设置中没有的设置除外',
    leading: Icon(Icons.video_settings_outlined),
    setKey: SettingBoxKey.tempPlayerConf,
    defaultVal: false,
  ),
];

Future<void> _showSubtitleDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<SubtitlePrefType>(
    context: context,
    builder: (context) => SelectDialog<SubtitlePrefType>(
      title: '字幕选择偏好',
      value: Pref.subtitlePreferenceV2,
      values: SubtitlePrefType.values.map((e) => (e, e.desc)).toList(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.subtitlePreferenceV2,
      res.index,
    );
    setState();
  }
}

const kMaxVolume = 300.0;
