import 'package:bplus_tv/models/common/ui_style.dart';
import 'package:bplus_tv/pages/setting/models/model.dart';
import 'package:bplus_tv/utils/extension/get_ext.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 界面风格入口，同时供设置搜索建立索引。
List<SettingsModel> get uiStyleSettings => [
  NormalModel(
    title: '界面风格',
    subtitle: '默认与 Smartisan OS 两种全局界面，点击切换',
    leading: const Icon(Icons.palette_outlined),
    getTrailing: (theme) => Text(
      Pref.uiStyle.label,
      style: theme.textTheme.titleSmall,
    ),
    onTap: (context, setState) => Get.toNamed('/styleSetting'),
  ),
];

/// 保存界面风格并即时刷新全局主题。
Future<void> applyUiStyle(UiStyle style) async {
  if (Pref.uiStyle == style) return;
  await GStorage.setting.put(SettingBoxKey.uiStyle, style.index);
  Get.updateMyAppTheme();
  SmartDialog.showToast('已切换到${style.label}');
}
