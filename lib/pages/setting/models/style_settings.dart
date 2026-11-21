import 'dart:io';

import 'package:bplus_tv/common/widgets/custom_toast.dart';
import 'package:bplus_tv/common/widgets/dialog/dialog.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/scale_app.dart';
import 'package:bplus_tv/models/common/dynamic/dynamic_badge_mode.dart';
import 'package:bplus_tv/models/common/dynamic/up_panel_position.dart';
import 'package:bplus_tv/models/common/home_tab_type.dart';
import 'package:bplus_tv/models/common/nav_bar_config.dart';
import 'package:bplus_tv/models/common/theme/theme_type.dart';
import 'package:bplus_tv/pages/main/controller.dart';
import 'package:bplus_tv/pages/mine/controller.dart';
import 'package:bplus_tv/pages/setting/models/model.dart';
import 'package:bplus_tv/pages/setting/slide_color_picker.dart';
import 'package:bplus_tv/pages/setting/widgets/slider_dialog.dart';
import 'package:bplus_tv/utils/extension/get_ext.dart';
import 'package:bplus_tv/utils/global_data.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:bplus_tv/utils/theme_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide StatefulBuilder;

List<SettingsModel> get styleSettings => [
  NormalModel(
    title: 'App字体设置',
    subtitle: '点击设置',
    leading: const Icon(Icons.text_fields),
    onTap: (context, setState) => Get.toNamed('/fontSetting'),
  ),
  NormalModel(
    title: '界面缩放',
    getSubtitle: () => '当前缩放比例：${Pref.uiScalePreference.toStringAsFixed(2)}',
    leading: const Icon(Icons.zoom_in_outlined),
    onTap: _showUiScaleDialog,
  ),
  NormalModel(
    title: '界面风格',
    subtitle: '在默认与 Smartisan OS 之间切换',
    leading: const Icon(Icons.palette_outlined),
    getTrailing: (theme) => Text(
      Pref.uiStyle.label,
      style: theme.textTheme.titleSmall,
    ),
    onTap: (context, setState) => Get.toNamed('/styleSetting'),
  ),
  const SwitchModel(
    title: '视频播放页使用深色主题',
    leading: Icon(Icons.dark_mode_outlined),
    setKey: SettingBoxKey.darkVideoPage,
    defaultVal: false,
  ),
  SwitchModel(
    title: '动态页启用瀑布流',
    subtitle: '关闭会显示为单列',
    leading: const Icon(Icons.view_array_outlined),
    setKey: SettingBoxKey.dynamicsWaterfallFlow,
    defaultVal: Pref.horizontalScreen,
    needReboot: true,
  ),
  PopupModel(
    title: '动态页UP主显示位置',
    leading: const Icon(Icons.person_outlined),
    value: () => Pref.upPanelPosition,
    items: UpPanelPosition.values,
    onSelected: (value, setState) {
      GStorage.setting
          .put(SettingBoxKey.upPanelPosition, value.index)
          .whenComplete(setState);
      SmartDialog.showToast('重启生效');
    },
  ),
  const SwitchModel(
    title: '动态页显示所有已关注UP主',
    leading: Icon(Icons.people_alt_outlined),
    setKey: SettingBoxKey.dynamicsShowAllFollowedUp,
    defaultVal: false,
    needReboot: true,
  ),
  const SwitchModel(
    title: '动态页展开正在直播UP列表',
    leading: Icon(Icons.live_tv),
    setKey: SettingBoxKey.expandDynLivePanel,
    defaultVal: false,
    needReboot: true,
  ),
  PopupModel(
    title: '动态未读标记',
    leading: const Icon(Icons.motion_photos_on_outlined),
    value: () => Pref.dynamicBadgeType,
    items: DynamicBadgeMode.values,
    onSelected: _setDynBadge,
  ),
  NormalModel(
    onTap: (context, setState) => _showQualityDialog(
      context: context,
      title: const Text('图片质量'),
      initValue: Pref.picQuality,
      onChanged: (picQuality) async {
        GlobalData().imgQuality = picQuality;
        await GStorage.setting.put(SettingBoxKey.defaultPicQa, picQuality);
        setState();
      },
    ),
    title: '图片质量',
    subtitle: '选择合适的图片清晰度，上限100%',
    leading: const Icon(Icons.image_outlined),
    getTrailing: (theme) => Text(
      '${Pref.picQuality}%',
      style: theme.textTheme.titleSmall,
    ),
  ),
  NormalModel(
    onTap: (context, setState) => _showQualityDialog(
      context: context,
      title: const Text('查看大图质量'),
      initValue: Pref.previewQ,
      onChanged: (picQuality) async {
        await GStorage.setting.put(SettingBoxKey.previewQuality, picQuality);
        setState();
      },
    ),
    title: '查看大图质量',
    subtitle: '选择合适的图片清晰度，上限100%',
    leading: const Icon(Icons.image_outlined),
    getTrailing: (theme) => Text(
      '${Pref.previewQ}%',
      style: theme.textTheme.titleSmall,
    ),
  ),
  NormalModel(
    onTap: _showReduceColorDialog,
    title: '深色下图片颜色叠加',
    subtitle: '显示颜色=图片原色x所选颜色，大图查看不受影响',
    leading: const Icon(Icons.format_color_fill_outlined),
    getTrailing: (theme) => Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Pref.reduceLuxColor ?? Colors.white,
        shape: BoxShape.circle,
      ),
    ),
  ),
  NormalModel(
    leading: const Icon(Icons.opacity_outlined),
    title: '气泡提示不透明度',
    subtitle: '自定义气泡提示(Toast)不透明度',
    getTrailing: (theme) => Text(
      CustomToast.toastOpacity.toStringAsFixed(1),
      style: theme.textTheme.titleSmall,
    ),
    onTap: _showToastDialog,
  ),
  NormalModel(
    leading: const Icon(Icons.wallpaper_outlined),
    title: '最低层背景',
    getSubtitle: () => '当前：${Pref.backgroundScene.label}',
    getTrailing: _backgroundThumb,
    onTap: (context, setState) => Get.toNamed('/backgroundSetting'),
  ),
  PopupModel(
    leading: const Icon(Icons.flashlight_on_outlined),
    title: '主题模式',
    value: () => Pref.themeType,
    items: ThemeType.values,
    onSelected: _setThemeType,
  ),
  SwitchModel(
    leading: const Icon(Icons.invert_colors),
    title: '纯黑主题',
    setKey: SettingBoxKey.isPureBlackTheme,
    defaultVal: false,
    onChanged: (value) {
      if (ThemeUtils.isDarkMode || Pref.darkVideoPage) {
        Get.updateMyAppTheme();
      }
    },
  ),
  PopupModel(
    leading: const Icon(Icons.home_outlined),
    title: '默认启动页',
    value: () => Pref.defaultHomePage,
    items: NavigationBarType.values,
    onSelected: (value, setState) {
      GStorage.setting
          .put(SettingBoxKey.defaultHomePage, value.index)
          .whenComplete(setState);
      SmartDialog.showToast('重启生效');
    },
  ),
  NormalModel(
    onTap: (context, setState) => Get.toNamed(
      '/barSetting',
      arguments: {
        'key': SettingBoxKey.tabBarSort,
        'defaultBars': HomeTabType.values,
        'title': '首页标签页',
      },
    ),
    title: '首页标签页',
    subtitle: '删除或调换首页标签页',
    leading: const Icon(Icons.toc_outlined),
  ),
  NormalModel(
    onTap: (context, setState) => Get.toNamed(
      '/barSetting',
      arguments: {
        'key': SettingBoxKey.navBarSort,
        'defaultBars': NavigationBarType.values,
        'title': 'Navbar',
      },
    ),
    title: 'Navbar编辑',
    subtitle: '删除或调换Navbar',
    leading: const Icon(Icons.toc_outlined),
  ),
  SwitchModel(
    title: '返回时直接退出',
    subtitle: '开启后在主页任意tab按返回键都直接退出，关闭则先回到Navbar的第一个tab',
    leading: const Icon(Icons.exit_to_app_outlined),
    setKey: SettingBoxKey.directExitOnBack,
    defaultVal: false,
    onChanged: (value) => Get.find<MainController>().directExitOnBack = value,
  ),
  if (Platform.isAndroid)
    NormalModel(
      onTap: (context, setState) => Get.toNamed('/displayModeSetting'),
      title: '屏幕帧率',
      leading: const Icon(Icons.autofps_select_outlined),
    ),
];

void _showQualityDialog({
  required BuildContext context,
  required Widget title,
  required int initValue,
  required ValueChanged<int> onChanged,
}) {
  showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      value: initValue.toDouble(),
      title: title,
      min: 10,
      max: 100,
      divisions: 9,
      suffix: '%',
      precise: 0,
    ),
  ).then((result) {
    if (result != null) {
      SmartDialog.showToast('设置成功');
      onChanged(result.toInt());
    }
  });
}

void _showUiScaleDialog(
  BuildContext context,
  VoidCallback setState,
) {
  const minUiScale = 0.5;
  const maxUiScale = 2.0;

  double uiScale = Pref.uiScalePreference;

  {
    showDialog<double>(
      context: context,
      builder: (context) => SliderDialog(
        title: const Text('界面缩放'),
        min: minUiScale,
        max: maxUiScale,
        divisions: ((maxUiScale - minUiScale) * 20).toInt(),
        value: uiScale,
      ),
    ).then((res) {
      if (res == null) return;
      uiScale = res;
      GStorage.setting.put(SettingBoxKey.uiScale, uiScale).whenComplete(() {
        setState();
        Get.appUpdate();
        ScaledWidgetsFlutterBinding.instance.scaleFactor = Pref.uiScale;
      });
    });
    return;
  }
}

void _setDynBadge(DynamicBadgeMode value, VoidCallback setState) {
  final mainController = Get.find<MainController>()..dynamicBadgeMode = value;
  if (value != DynamicBadgeMode.hidden) mainController.getUnreadDynamic();
  GStorage.setting
      .put(SettingBoxKey.dynamicBadgeMode, value.index)
      .whenComplete(setState);
}

void _showReduceColorDialog(
  BuildContext context,
  VoidCallback setState,
) {
  final reduceLuxColor = Pref.reduceLuxColor;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      clipBehavior: Clip.hardEdge,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      title: const Text('Color Picker'),
      content: SlideColorPicker(
        color: reduceLuxColor ?? Colors.white,
        onChanged: (Color? color) {
          if (color != null && color != reduceLuxColor) {
            if (color == Colors.white) {
              NetworkImgLayer.reduceLuxColor = null;
              GStorage.setting.delete(SettingBoxKey.reduceLuxColor);
              SmartDialog.showToast('设置成功');
              setState();
            } else {
              void onConfirm() {
                NetworkImgLayer.reduceLuxColor = color;
                GStorage.setting.put(
                  SettingBoxKey.reduceLuxColor,
                  color.toARGB32(),
                );
                SmartDialog.showToast('设置成功');
                setState();
              }

              if (color.computeLuminance() < 0.2) {
                showConfirmDialog(
                  context: context,
                  title: Text(
                    '确认使用#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6)}？',
                  ),
                  content: const Text('所选颜色过于昏暗，可能会影响图片观看'),
                  onConfirm: onConfirm,
                );
              } else {
                onConfirm();
              }
            }
          }
        },
      ),
    ),
  );
}

Future<void> _showToastDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('Toast不透明度'),
      value: CustomToast.toastOpacity,
      min: 0.0,
      max: 1.0,
      divisions: 10,
    ),
  );
  if (res != null) {
    CustomToast.toastOpacity = res;
    await GStorage.setting.put(SettingBoxKey.defaultToastOp, res);
    SmartDialog.showToast('设置成功');
    setState();
  }
}

Widget _backgroundThumb(ThemeData theme) {
  final scene = Pref.backgroundScene;
  final gradient = scene.gradient(theme.colorScheme);
  return Container(
    width: 30,
    height: 42,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: gradient == null
          ? theme.colorScheme.surfaceContainerHighest
          : null,
      gradient: gradient,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
  );
}

void _setThemeType(ThemeType value, VoidCallback setState) {
  try {
    Get.find<MineController>().themeType.value = value;
  } catch (_) {}
  GStorage.setting.put(SettingBoxKey.themeMode, value.index);
  Get.changeThemeMode(ThemeUtils.themeMode = value.toThemeMode);
  setState();
}
