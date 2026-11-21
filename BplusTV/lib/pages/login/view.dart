import 'package:bplus_tv/common/constants.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/common/widgets/view_insets_safe_area.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/pages/login/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_numpad.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/extension/widget_ext.dart';
import 'package:bplus_tv/utils/image_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginPageController _loginPageCtr = Get.put(LoginPageController());
  // 二维码生成时间
  final GlobalKey globalKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loginPageCtr.didChangeDependencies(context);
  }

  Widget loginByQRCode(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text('使用 bilibili 官方 App 扫码登录'),
        const SizedBox(height: 20),
        Obx(
          () => Text(
            '剩余有效时间: ${_loginPageCtr.qrCodeLeftTime} 秒',
            style: TextStyle(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: theme.colorScheme.primaryFixedDim,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _tvButton(
              icon: Icons.refresh,
              label: '刷新二维码',
              autofocus: true,
              onTap: _loginPageCtr.refreshQRCode,
            ),
            _tvButton(
              icon: Icons.save,
              label: '保存至相册',
              onTap: () async {
                SmartDialog.showLoading(msg: '正在生成截图');
                try {
                  final ctx = globalKey.currentContext;
                  if (ctx == null) return;
                  final boundary =
                      ctx.findRenderObject() as RenderRepaintBoundary;
                  final image = await boundary.toImage(pixelRatio: 3);
                  final byteData = await image.toByteData(format: .png);
                  final pngBytes = byteData?.buffer.asUint8List();
                  image.dispose();
                  if (pngBytes == null) return;
                  final codeData = _loginPageCtr.codeInfo.value.dataOrNull;
                  if (codeData == null) return;
                  final picName =
                      "${Constants.appName}_loginQRCode_${codeData.authCode.hashCode.toUnsigned(32).toRadixString(16)}";
                  ImageUtils.saveByteImg(bytes: pngBytes, fileName: picName);
                } catch (e) {
                  SmartDialog.showToast(e.toString());
                } finally {
                  SmartDialog.dismiss();
                }
              },
            ),
            _tvButton(
              icon: Icons.open_in_browser_outlined,
              label: '其他应用打开',
              onTap: () {
                final url = _loginPageCtr.codeInfo.value.dataOrNull?.url;
                if (url == null) return;
                PageUtils.launchURL(
                  'bilibili://browser?url=${Uri.encodeComponent(url)}',
                  mode: LaunchMode.externalNonBrowserApplication,
                );
              },
            ),
          ],
        ),
        RepaintBoundary(
          key: globalKey,
          child: Obx(
            () => switch (_loginPageCtr.codeInfo.value) {
              Loading() => const SizedBox(
                height: 200,
                width: 200,
                child: m3eLoading,
              ),
              Success(:final response) => Container(
                width: 200,
                height: 200,
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: PrettyQrView.data(
                  data: response.url,
                  decoration: const PrettyQrDecoration(
                    shape: PrettyQrSquaresSymbol(
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Error(:final errMsg) => HttpError(
                isSliver: false,
                errMsg: errMsg,
                onReload: _loginPageCtr.refreshQRCode,
              ),
            },
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Text(
            _loginPageCtr.statusQRCode.value,
            style: TextStyle(color: theme.colorScheme.secondaryFixedDim),
          ),
        ),
        Obx(
          () {
            final url = _loginPageCtr.codeInfo.value.dataOrNull?.url ?? '';
            return TvFocusable(
              onTap: () => Utils.copyText(
                url,
                toastText: '已复制到剪贴板，可粘贴至已登录的app私信处发送，然后点击已发送的链接打开',
              ),
              builder: (context, focused, hovered) => TvFocusHighlight(
                radius: 10,
                focused: focused,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Text(
                    url,
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: focused ? 0.8 : 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '请务必在 ${Constants.appName} 开源仓库等可信渠道下载安装。',
            style: theme.textTheme.labelSmall!.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tvButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool autofocus = false,
  }) {
    return TvFocusable(
      autofocus: autofocus,
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        radius: 14,
        focused: focused,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editPhone() async {
    final res = await showTvNumpad(
      context,
      title: '输入手机号',
      initialValue: _loginPageCtr.telTextController.text,
      maxLength: 11,
    );
    if (!mounted) return;
    if (res != null) {
      _loginPageCtr.telTextController.text = res;
      setState(() {});
    }
  }

  Future<void> _editSmsCode() async {
    final res = await showTvNumpad(
      context,
      title: '输入验证码',
      initialValue: _loginPageCtr.smsCodeTextController.text,
      maxLength: 6,
    );
    if (!mounted) return;
    if (res != null) {
      _loginPageCtr.smsCodeTextController.text = res;
      setState(() {});
    }
  }

  Widget _tvTextField({
    required String hint,
    required String value,
    required VoidCallback onEdit,
    required IconData icon,
    bool autofocus = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      autofocus: autofocus,
      onTap: onEdit,
      builder: (context, focused, hovered) => TvFocusHighlight(
        radius: 14,
        focused: focused,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: focused
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? hint : value,
                  style: TextStyle(
                    fontSize: 20,
                    letterSpacing: 1.2,
                    color: value.isEmpty
                        ? colorScheme.outline
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard,
                size: 20,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget loginBySms(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const Text('使用手机短信验证码登录'),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _tvTextField(
            hint: '+${_loginPageCtr.selectedCountryCodeId.countryId} 输入手机号',
            value: _loginPageCtr.telTextController.text,
            icon: Icons.phone,
            autofocus: true,
            onEdit: _editPhone,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _tvTextField(
            hint: '输入验证码',
            value: _loginPageCtr.smsCodeTextController.text,
            icon: Icons.sms_outlined,
            onEdit: _editSmsCode,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(
              () => TvFocusable(
                onTap: _loginPageCtr.smsSendCooldown.value > 0
                    ? null
                    : _loginPageCtr.sendSmsCode,
                canRequestFocus: _loginPageCtr.smsSendCooldown.value == 0,
                builder: (context, focused, hovered) => TvFocusHighlight(
                  radius: 14,
                  focused: focused,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: focused
                          ? colorScheme.primary.withValues(alpha: 0.15)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.send,
                          size: 18,
                          color: _loginPageCtr.smsSendCooldown.value > 0
                              ? colorScheme.outline
                              : colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _loginPageCtr.smsSendCooldown.value > 0
                              ? '等待${_loginPageCtr.smsSendCooldown.value}秒'
                              : '获取验证码',
                          style: TextStyle(
                            color: _loginPageCtr.smsSendCooldown.value > 0
                                ? colorScheme.outline
                                : colorScheme.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            TvFocusable(
              onTap: _loginPageCtr.loginBySmsCode,
              builder: (context, focused, hovered) => TvFocusHighlight(
                radius: 14,
                focused: focused,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: focused
                        ? colorScheme.primary
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.login,
                        size: 18,
                        color: focused
                            ? colorScheme.onPrimary
                            : colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '登录',
                        style: TextStyle(
                          color: focused
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimaryContainer,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  late EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    padding =
        MediaQuery.viewPaddingOf(context).copyWith(top: 0) +
        const EdgeInsets.only(bottom: 25);
    final body = ViewInsetsSafeArea(
      child: tabBarView(
        controller: _loginPageCtr.tabController,
        children: [
          tabViewOuter(loginByQRCode(theme)),
          tabViewOuter(loginBySms(theme)),
        ],
      ),
    );
    return SimpleScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '关闭',
          icon: const Icon(Icons.close_outlined),
          onPressed: Get.back,
        ),
        title: Row(
          children: [
            const Text('登录'),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TabBar(
                  isScrollable: true,
                  dividerHeight: 0,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(Icons.qr_code), Text(' 扫码')],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(Icons.sms_outlined), Text(' 短信')],
                      ),
                    ),
                  ],
                  controller: _loginPageCtr.tabController,
                ),
              ),
            ),
          ],
        ),
      ),
      body: TvPageFocus(
        child: netflixSurface(
          radius: 24,
          child: body,
        ),
      ),
    );
  }

  Widget tabViewOuter(Widget child) {
    return SingleChildScrollView(
      padding: padding,
      child: child.constraintWidth(),
    );
  }
}
