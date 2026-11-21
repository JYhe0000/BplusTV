import 'dart:io' show File;

import 'package:bplus_tv/common/constants.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/http/constants.dart';
import 'package:bplus_tv/http/init.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/member/profile_type.dart';
import 'package:bplus_tv/models/user/info.dart';
import 'package:bplus_tv/models_new/account_myinfo/data.dart';
import 'package:bplus_tv/pages/mine/controller.dart';
import 'package:bplus_tv/services/account_service.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:bplus_tv/tv/tv_text_input.dart';
import 'package:bplus_tv/utils/accounts.dart';
import 'package:bplus_tv/utils/app_sign.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/extension/file_ext.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mime/mime.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  LoadingState<AccountMyInfoData> _loadingState =
      LoadingState<AccountMyInfoData>.loading();
  late final TextEditingController _textController;
  late final _imagePicker = ImagePicker();
  AccountService accountService = Get.find<AccountService>();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _getInfo();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SimpleScaffold(
      appBar: AppBar(title: const Text('账号资料')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _buildBody(theme, _loadingState),
        ),
      ),
    );
  }

  Future<void> _getInfo() async {
    Map<String, String> data = {
      'build': '2001100',
      'c_locale': 'zh_CN',
      'channel': 'master',
      'mobi_app': 'android_hd',
      'platform': 'android',
      's_locale': 'zh_CN',
      'statistics': Constants.statistics,
    };
    Request()
        .get(
          '${HttpString.appBaseUrl}/x/v2/account/myinfo',
          queryParameters: data,
        )
        .then((res) {
          if (mounted) {
            setState(() {
              if (res.data['code'] == 0) {
                AccountMyInfoData data = AccountMyInfoData.fromJson(
                  res.data['data'],
                );
                _loadingState = Success(data);
                accountService.face.value = data.face!;
                try {
                  UserInfoData userInfo = Pref.userInfoCache!
                    ..uname = data.name
                    ..face = data.face;
                  GStorage.userInfo.put('userInfoCache', userInfo);
                } catch (_) {}
                try {
                  Get.find<MineController>().userInfo
                    ..value.uname = data.name
                    ..value.face = data.face
                    ..refresh();
                } catch (_) {}
              } else {
                _loadingState = Error(res.data['message']);
              }
            });
          }
        });
  }

  Widget _buildBody(
    ThemeData theme,
    LoadingState<AccountMyInfoData> loadingState,
  ) {
    late final divider = Divider(
      height: 1,
      color: theme.dividerColor.withValues(alpha: 0.1),
    );

    late final divider1 = Divider(
      thickness: 16,
      color: theme.dividerColor.withValues(alpha: 0.1),
    );

    return switch (loadingState) {
      Loading() => m3eLoading,
      Success(:final response) => ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 25,
        ),
        children: [
          divider1,
          _item(
            theme: theme,
            title: '头像',
            widget: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: NetworkImgLayer(
                width: 55,
                height: 55,
                type: .avatar,
                src: response.face,
              ),
            ),
            onTap: () => EasyThrottle.throttle(
              'imagePicker',
              const Duration(milliseconds: 500),
              () {
                _pickImg(theme);
              },
            ),
          ),
          divider,
          _item(
            theme: theme,
            title: '昵称',
            text: response.name,
            onTap: () {
              if (response.coins! < 6) {
                SmartDialog.showToast('硬币不足');
              } else {
                _editDialog(
                  type: ProfileType.uname,
                  title: '昵称',
                  text: response.name!,
                );
              }
            },
          ),
          divider,
          _item(
            theme: theme,
            title: '性别',
            text: _sex(response.sex!),
            onTap: () => showDialog(
              context: context,
              builder: (context_) => _sexDialog(response.sex!),
            ),
          ),
          divider,
          _item(
            theme: theme,
            title: '出生年月',
            text: response.birthday,
            onTap: () =>
                showDatePicker(
                  context: context,
                  initialDate: DateTime.parse(response.birthday!),
                  firstDate: DateTime(0001, 1, 1),
                  lastDate: DateTime.now(),
                ).then((res) {
                  if (res != null) {
                    _update(
                      type: ProfileType.birthday,
                      datum: DateFormatUtils.longFormat.format(res),
                    );
                  }
                }),
          ),
          divider,
          _item(
            theme: theme,
            title: '个性签名',
            text: response.sign,
            onTap: () => _editDialog(
              type: ProfileType.sign,
              title: '个性签名',
              text: response.sign ?? '',
            ),
          ),
          divider1,
          _item(
            theme: theme,
            title: '头像挂件',
            onTap: () => PageUtils.inAppWebview(
              'https://www.bilibili.com/h5/mall/pendant/home',
            ),
          ),
          divider1,
          _item(
            theme: theme,
            title: 'UID',
            needIcon: false,
            text: response.mid.toString(),
            onTap: () => Utils.copyText(response.mid.toString()),
          ),
          divider1,
          _item(
            theme: theme,
            title: '哔哩哔哩认证',
            onTap: () => PageUtils.inAppWebview(
              'https://account.bilibili.com/official/mobile/home',
            ),
          ),
          divider1,
        ],
      ),
      Error(:final errMsg) => scrollErrorWidget(
        errMsg: errMsg,
        onReload: _getInfo,
      ),
    };
  }

  Widget _sexDialog(int current) {
    return SimpleDialog(
      clipBehavior: Clip.hardEdge,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _sexDialogItem(1, current, '男'),
        _sexDialogItem(0, current, '保密'),
        _sexDialogItem(2, current, '女'),
      ],
    );
  }

  Widget _sexDialogItem(
    int sex,
    int current,
    String text,
  ) {
    return TvFocusCard(
      radius: 8,
      onTap: () {
        Get.back();
        _update(type: ProfileType.sex, datum: sex);
      },
      child: ExcludeFocus(
        child: ListTile(
          dense: true,
          enabled: current != sex,
          title: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          trailing: current == sex ? const Icon(size: 22, Icons.check) : null,
          onTap: () {
            Get.back();
            _update(type: ProfileType.sex, datum: sex);
          },
        ),
      ),
    );
  }

  void _editDialog({
    required ProfileType type,
    required String title,
    required String text,
  }) {
    _textController.text = text;
    {
      showTvTextInput(
        context,
        title: '修改$title',
        initialValue: text,
        maxLength: type == ProfileType.uname ? 16 : 70,
      ).then((value) {
        if (value == null || !context.mounted) return;
        _textController.text = value;
        if (_textController.text == text) {
          SmartDialog.showToast('与原$title相同');
        } else {
          _update(type: type);
        }
      });
      return;
    }
  }

  Future<void> _update({
    required ProfileType type,
    dynamic datum,
  }) async {
    final accessKey = Accounts.main.accessKey;
    if (accessKey == null || accessKey.isEmpty) {
      SmartDialog.showToast('请退出账号后重新登录');
      return;
    }
    final data = <String, String>{
      'access_key': accessKey,
      'build': '2001100',
      'c_locale': 'zh_CN',
      'channel': 'master',
      'mobi_app': 'android_hd',
      'platform': 'android',
      's_locale': 'zh_CN',
      'statistics': Constants.statistics,
      if (type == ProfileType.uname)
        'uname': _textController.text
      else if (type == ProfileType.sign)
        'user_sign': _textController.text
      else if (type == ProfileType.birthday)
        'birthday': datum
      else if (type == ProfileType.sex)
        'sex': datum.toString(),
    };
    AppSign.appSign(data);
    Request()
        .post(
          '/x/member/app/${type.name}/update',
          data: data,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
          ),
        )
        .then((res) {
          if (res.data['code'] == 0) {
            AccountMyInfoData data = _loadingState.data;
            if (type == ProfileType.uname) {
              data
                ..name = _textController.text
                ..coins = data.coins! - 6;
              try {
                UserInfoData userInfo = Pref.userInfoCache!
                  ..uname = _textController.text;
                GStorage.userInfo.put('userInfoCache', userInfo);
              } catch (_) {}
              try {
                Get.find<MineController>().userInfo
                  ..value.uname = _textController.text
                  ..refresh();
              } catch (_) {}
            } else if (type == ProfileType.sign) {
              data.sign = _textController.text;
            } else if (type == ProfileType.birthday) {
              data.birthday = datum;
            } else if (type == ProfileType.sex) {
              data.sex = datum;
            }
            SmartDialog.showToast('修改成功');
            if (mounted) {
              setState(() {});
            }
            if (type == ProfileType.uname || type == ProfileType.sign) {
              Get.back();
            }
          } else {
            SmartDialog.showToast(res.data['message']);
          }
        });
  }

  String _sex(int sex) {
    return switch (sex) {
      0 => '保密',
      1 => '男',
      2 => '女',
      _ => '未知',
    };
  }

  Widget _item({
    required ThemeData theme,
    required String title,
    Widget? widget,
    String? text,
    GestureTapCallback? onTap,
    bool needIcon = true,
  }) {
    final tile = ListTile(
      onTap: onTap,
      dense: false,
      minVerticalPadding: 14,
      leading: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (text != null)
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          else
            ?widget,
          if (needIcon)
            Icon(
              Icons.keyboard_arrow_right,
              color: theme.colorScheme.outline,
            )
          else
            const SizedBox(width: 24),
        ],
      ),
    );

    if (onTap == null) {
      return ExcludeFocus(child: tile);
    }
    return TvFocusButton(
      radius: 8,
      onTap: onTap,
      child: tile,
    );
  }

  Future<void> _pickImg(ThemeData theme) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        requestFullMetadata: false,
      );
      if (pickedFile != null && mounted) {
        final String imagePath = pickedFile.path;
        String? mimeType = (pickedFile.mimeType ?? lookupMimeType(imagePath))
            ?.split('/')
            .elementAtOrNull(1);
        if (mimeType == 'gif') {
          SmartDialog.showToast('不能选GIF');
          return;
        }
        if (imagePath.isNotEmpty) {
          Request()
              .post(
                '/x/member/web/face/update',
                queryParameters: {
                  'csrf': Accounts.main.csrf,
                },
                data: FormData.fromMap({
                  'dopost': 'save',
                  'DisplayRank': 10000,
                  'face': await MultipartFile.fromFile(imagePath),
                }),
              )
              .then((res) {
                if (res.data['code'] == 0) {
                  SmartDialog.showToast('修改成功');
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      _getInfo();
                    }
                  });
                } else {
                  SmartDialog.showToast(res.data['message']);
                }
                File(imagePath).tryDel();
              });
        }
      }
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }
}
