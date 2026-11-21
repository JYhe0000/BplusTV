import 'dart:async';

import 'package:bplus_tv/common/dial_prefix.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/login.dart';
import 'package:bplus_tv/models/common/account_type.dart';
import 'package:bplus_tv/models/login/model.dart';
import 'package:bplus_tv/pages/login/geetest/geetest_webview_dialog.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/accounts.dart';
import 'package:bplus_tv/utils/accounts/account.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class LoginPageController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final TextEditingController telTextController = TextEditingController();
  final TextEditingController smsCodeTextController = TextEditingController();

  late final codeInfo =
      LoadingState<({String authCode, String url})>.loading().obs;

  late final TabController tabController;

  late final CaptchaDataModel captchaData = CaptchaDataModel();
  late final RxInt qrCodeLeftTime = 180.obs;
  late final RxString statusQRCode = ''.obs;

  late var selectedCountryCodeId = Login.dialPrefix.first;
  late String captchaKey = '';
  late final RxInt smsSendCooldown = 0.obs;
  late int smsSendTimestamp = 0;

  // 定时器
  Timer? qrCodeTimer;
  Timer? smsSendCooldownTimer;

  bool _isReq = false;
  bool _isRefreshing = false;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChange);
    refreshQRCode();
  }

  @override
  void onClose() {
    qrCodeTimer?.cancel();
    qrCodeTimer = null;
    smsSendCooldownTimer?.cancel();
    smsSendCooldownTimer = null;
    tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    telTextController.dispose();
    smsCodeTextController.dispose();
    super.onClose();
  }

  Future<void> refreshQRCode() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    final res = await LoginHttp.getHDcode();
    _isRefreshing = false;
    if (isClosed || res is! Success) return;
    final response = (res as Success).response;
    qrCodeTimer?.cancel();
    codeInfo.value = res;
    qrCodeTimer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
      if (isClosed) {
        t.cancel();
        return;
      }
      final left = 180 - t.tick;
      if (left <= 0) {
        t.cancel();
        statusQRCode.value = '二维码已过期，请刷新';
        qrCodeLeftTime.value = 0;
        return;
      }
      qrCodeLeftTime.value = left;
      if (_isReq || tabController.index != 0) return;

      _isReq = true;
      LoginHttp.codePoll(response.authCode).then((value) async {
        if (isClosed) return;
        _isReq = false;
        if (value['status']) {
          t.cancel();
          statusQRCode.value = '扫码成功';
          await setAccount(
            value['data'],
            value['data']['cookie_info']['cookies'],
          );
          if (!isClosed) Get.back();
        } else if (value['code'] == 86038) {
          t.cancel();
          qrCodeLeftTime.value = 0;
        } else {
          statusQRCode.value = value['msg'];
        }
      });
    });
  }

  void _handleTabChange() {
    if (tabController.index == 0 && !_isRefreshing) {
      if (qrCodeTimer == null || !qrCodeTimer!.isActive) {
        refreshQRCode();
      }
    }
  }

  // 申请极验验证码
  void getCaptcha(
    String geeGt,
    String geeChallenge,
    VoidCallback onSuccess,
  ) {
    GeetestWebviewDialog.geetest(geeGt, geeChallenge).then((res) {
      if (res != null) {
        captchaData
          ..validate = res['geetest_validate']
          ..seccode = res['geetest_seccode']
          ..geetest = GeetestData(
            challenge: res['geetest_challenge'],
            gt: geeGt,
          );
        SmartDialog.showToast('验证成功');
        onSuccess();
      }
    });
  }

  // 短信验证码登录
  Future<void> loginBySmsCode() async {
    if (telTextController.text.isEmpty) {
      SmartDialog.showToast('手机号不能为空');
      return;
    }
    if (captchaKey.isEmpty) {
      SmartDialog.showToast('请先点击获取验证码');
      return;
    }
    if (smsCodeTextController.text.isEmpty) {
      SmartDialog.showToast('验证码不能为空');
      return;
    }
    if (DateTime.now().millisecondsSinceEpoch - smsSendTimestamp >
        1000 * 60 * 5) {
      SmartDialog.showToast('验证码已过期，请重新获取');
      return;
    }
    final webKeyRes = await LoginHttp.getWebKey();
    if (!webKeyRes['status']) {
      SmartDialog.showToast(webKeyRes['msg']);
      return;
    }
    String key = webKeyRes['data']['key'];
    final res = await LoginHttp.loginBySms(
      tel: telTextController.text,
      code: smsCodeTextController.text,
      captchaKey: captchaKey,
      cid: selectedCountryCodeId.countryId,
      key: key,
    );
    if (res['status']) {
      SmartDialog.showToast('登录成功');
      final data = res['data'];
      await setAccount(data['token_info'], data['cookie_info']['cookies']);
      Get.back();
    } else {
      SmartDialog.showToast(res['msg']);
    }
  }

  // app端验证码
  Future<void> sendSmsCode() async {
    if (telTextController.text.isEmpty) {
      SmartDialog.showToast('手机号不能为空');
      return;
    }
    // String? guestId;
    // final webKeyRes = await LoginHttp.getWebKey();
    // if (!webKeyRes['status']) {
    //   SmartDialog.showToast(webKeyRes['msg']);
    // } else {
    //   String key = webKeyRes['data']['key'];
    //   final guestIdRes = await LoginHttp.getGuestId(key);
    //   if (!guestIdRes['status']) {
    //     SmartDialog.showToast(guestIdRes['msg']);
    //   } else {
    //     guestId = guestIdRes['data']['guest_id'];
    //   }
    // }
    // final preCaptureRes = await LoginHttp.preCapture();
    // if (!preCaptureRes['status']) {
    //   SmartDialog.showToast("获取验证码失败，请尝试其它登录方式\n"
    //       "(${preCaptureRes['code']}) ${preCaptureRes['msg']}");
    //   return;
    // }
    // String geeGt = preCaptureRes['data']['gee_gt']!;
    // String geeChallenge = preCaptureRes['data']['gee_challenge'];
    // captchaData.token = preCaptureRes['data']['recaptcha_token']!;

    // getCaptcha(geeGt, geeChallenge, () async {

    // final safeCenterSendSmsCodeRes =
    // await LoginHttp.safeCenterSmsCode(
    //   tmpCode: currentUri.queryParameters['tmp_token']!,
    //   geeChallenge: geeChallenge,
    //   geeSeccode: captchaData.seccode!,
    //   geeValidate: captchaData.validate!,
    //   recaptchaToken: captchaData.token!,
    //   refererUrl: url,
    // );
    // if (!safeCenterSendSmsCodeRes['status']) {
    //   SmartDialog.showToast("发送短信验证码失败，请尝试其它登录方式\n"
    //       "(${safeCenterSendSmsCodeRes['code']}) ${safeCenterSendSmsCodeRes['msg']}");
    //   return;
    // }
    // SmartDialog.showToast("短信验证码已发送，请查收");
    // captchaKey = safeCenterSendSmsCodeRes['data']['captcha_key'];

    final res = await LoginHttp.sendSmsCode(
      tel: telTextController.text,
      cid: selectedCountryCodeId.countryId,
      // deviceTouristId: guestId,
      geeValidate: captchaData.validate,
      geeSeccode: captchaData.seccode,
      geeChallenge: captchaData.geetest?.challenge,
      recaptchaToken: captchaData.token,
    );
    if (res['status']) {
      SmartDialog.showToast('发送成功');
      smsSendTimestamp = DateTime.now().millisecondsSinceEpoch;
      smsSendCooldown.value = 60;
      captchaKey = res['data']['captcha_key'];
      smsSendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (
        timer,
      ) {
        final left = 60 - timer.tick - 1;
        if (left <= 0) {
          timer.cancel();
          smsSendCooldownTimer = null;
          smsSendCooldown.value = 0;
        } else {
          smsSendCooldown.value = left;
        }
      });
    } else {
      // handle login result
      switch (res['code']) {
        case 0:
        case -105:
          String? captureUrl = res['data']?['recaptcha_url'];
          String? geeGt;
          String? geeChallenge;
          if (captureUrl != null && captureUrl.isNotEmpty) {
            Uri captureUri = Uri.parse(captureUrl);
            captchaData.token = captureUri.queryParameters['recaptcha_token'];
            geeGt = captureUri.queryParameters['gee_gt'];
            geeChallenge = captureUri.queryParameters['gee_challenge'];
          }

          if (!isGeeArgumentValid(geeGt, geeChallenge)) {
            if (kDebugMode) {
              debugPrint(
                '验证信息错误：${res["msg"]}\n返回内容：${res["data"]}，尝试另一个验证码接口',
              );
            }
            final preCaptureRes = await LoginHttp.preCapture();
            if (!preCaptureRes['status'] || preCaptureRes['data'] == null) {
              SmartDialog.showToast(
                "获取验证码失败，请尝试其它登录方式\n"
                "(${preCaptureRes['code']}) ${preCaptureRes['msg']} ${preCaptureRes['data']}",
              );
              return;
            }
            geeGt = preCaptureRes['data']['gee_gt'];
            geeChallenge = preCaptureRes['data']['gee_challenge'];
            captchaData.token = preCaptureRes['data']['recaptcha_token'];
          }

          if (!isGeeArgumentValid(geeGt, geeChallenge)) {
            SmartDialog.showToast("获取验证码失败，请尝试其它登录方式\n");
            return;
          }

          getCaptcha(geeGt!, geeChallenge!, sendSmsCode);
          break;
        default:
          SmartDialog.showToast(res['msg']);
          break;
      }
    }
  }

  bool isGeeArgumentValid(String? geeGt, String? geeChallenge) {
    return geeGt?.isNotEmpty == true &&
        geeChallenge?.isNotEmpty == true &&
        captchaData.token?.isNotEmpty == true;
  }

  Future<void> setAccount(Map tokenInfo, List cookieInfo) async {
    final account = LoginAccount(
      BiliCookieJar.fromList(cookieInfo),
      tokenInfo['access_token'],
      tokenInfo['refresh_token'],
    );
    await Future.wait([?account.onChange(), AnonymousAccount().delete()]);
    for (int i = 0; i < AccountType.values.length; i++) {
      if (Accounts.accountMode[i].mid == account.mid) {
        Accounts.accountMode[i] = account;
      }
    }
    if (Accounts.main.isLogin) {
      SmartDialog.showToast('登录成功');
    } else {
      SmartDialog.showToast('登录成功, 请先设置账号模式');
      await switchAccountDialog(Get.context!);
    }
  }

  static Future<void>? switchAccountDialog(BuildContext context) {
    if (Accounts.account.isEmpty) {
      SmartDialog.showToast('请先登录');
      return Get.toNamed('/loginPage');
    }
    final selectAccount = List.of(Accounts.accountMode);
    final options = {
      AnonymousAccount(): '0',
      ...Accounts.account.toMap().map(
        (k, v) => MapEntry(v, k as String),
      ),
    };
    final quickSelect = selectAccount.every((e) => e == selectAccount.first);
    return showDialog<void>(
      context: context,
      builder: (_) => _TvSwitchAccountDialog(
        options: options,
        initial: selectAccount,
        quickSelectStart: quickSelect,
      ),
    );
  }
}

class _TvSwitchAccountDialog extends StatefulWidget {
  const _TvSwitchAccountDialog({
    required this.options,
    required this.initial,
    required this.quickSelectStart,
  });

  final Map<Account, String> options;
  final List<Account> initial;
  final bool quickSelectStart;

  @override
  State<_TvSwitchAccountDialog> createState() => _TvSwitchAccountDialogState();
}

class _TvSwitchAccountDialogState extends State<_TvSwitchAccountDialog> {
  late bool _quickSelect = widget.quickSelectStart;
  late final List<Account> _select = List.of(widget.initial);

  void _apply() {
    Get.back();
    for (final type in AccountType.values) {
      final index = type.index;
      final account = _quickSelect ? _select.first : _select[index];
      if (account != Accounts.accountMode[index]) {
        Accounts.set(type, account);
      }
    }
  }

  Widget _optionTile(Account value, String title, int? typeIndex) {
    return TvFocusable(
      onTap: () {
        if (_quickSelect) {
          _select.fillRange(0, _select.length, value);
        } else if (typeIndex != null) {
          _select[typeIndex] = value;
        }
        setState(() {});
      },
      builder: (context, focused, hovered) {
        final selected = _quickSelect
            ? _select.every((e) => e == value)
            : typeIndex != null && _select[typeIndex] == value;
        final tile = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: focused
                ? Colors.transparent
                : (selected ? Colors.white.withValues(alpha: 0.10) : null),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected || focused
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: focused ? netflixSurface(radius: 12, child: tile) : tile,
        );
      },
    );
  }

  List<Widget> _sections() {
    if (_quickSelect) {
      return [
        for (final e in widget.options.entries)
          _optionTile(e.key, e.value, null),
      ];
    }
    return [
      for (final type in AccountType.values) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            type.title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
        for (final e in widget.options.entries)
          _optionTile(e.key, e.value, type.index),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(50),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: tvDialog(
        netflixSurface(
          radius: 24,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 360,
              maxWidth: 460,
              maxHeight: 560,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '账号切换',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TvFocusable(
                        autofocus: _quickSelect,
                        onTap: () =>
                            setState(() => _quickSelect = !_quickSelect),
                        builder: (context, focused, hovered) =>
                            TvFocusHighlight(
                              radius: 8,
                              focused: focused,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text(
                                  _quickSelect ? '详细' : '快速',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _sections(),
                  ),
                ),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TvFocusable(
                        onTap: Navigator.of(context).maybePop,
                        builder: (context, focused, hovered) =>
                            TvFocusHighlight(
                              radius: 12,
                              focused: focused,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 9,
                                ),
                                child: Text(
                                  '取消',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                      ),
                      const SizedBox(width: 12),
                      TvFocusable(
                        autofocus: !_quickSelect,
                        onTap: _apply,
                        builder: (context, focused, hovered) =>
                            TvFocusHighlight(
                              focused: focused,
                              radius: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                                child: const Text(
                                  '确定',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
