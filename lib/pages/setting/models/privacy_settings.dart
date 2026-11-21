import 'package:bplus_tv/models/common/account_type.dart';
import 'package:bplus_tv/pages/setting/models/model.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/utils/accounts.dart';
import 'package:bplus_tv/utils/accounts/api_type.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

List<SettingsModel> get privacySettings => [
  NormalModel(
    onTap: (context, setState) {
      if (!Accounts.main.isLogin) {
        SmartDialog.showToast('登录后查看');
        return;
      }
      Get.toNamed('/blackListPage');
    },
    title: '黑名单管理',
    subtitle: '已拉黑用户',
    leading: const Icon(Icons.block),
  ),
  NormalModel(
    onTap: (context, setState) {
      {
        showDialog(
          context: context,
          builder: (_) => tvDialogShell(
            title: '账号模式详情',
            minWidth: 480,
            content: SingleChildScrollView(
              child: SelectionArea(child: _getAccountDetail(context)),
            ),
            actions: [
              TvDialogAction(
                label: '确认',
                autofocus: true,
                onTap: Get.back,
              ),
            ],
          ),
        );
        return;
      }
    },
    leading: const Icon(Icons.flag_outlined),
    title: '了解账号模式',
    subtitle: '查看各个账号模式作用的API列表',
  ),
];

Widget _getAccountDetail(BuildContext context) {
  final children = <Widget>[];
  final theme = TextTheme.of(context);
  for (final i in AccountType.values) {
    final url = ApiType.apiTypeSet[i];
    if (url == null) continue;

    children
      ..add(Center(child: Text(i.title, style: theme.titleMedium)))
      ..add(Text(url.join('\n')));
  }
  return Column(
    spacing: 8,
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: children,
  );
}
