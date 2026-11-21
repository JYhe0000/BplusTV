import 'package:bplus_tv/common/widgets/flutter/pop_scope.dart' as app_pop;
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:bplus_tv/http/login.dart';
import 'package:bplus_tv/models/common/setting_type.dart';
import 'package:bplus_tv/pages/about/view.dart';
import 'package:bplus_tv/pages/login/controller.dart';
import 'package:bplus_tv/pages/setting/common_setting.dart';
import 'package:bplus_tv/pages/setting/pages/style_page.dart';
import 'package:bplus_tv/pages/setting/widgets/multi_select_dialog.dart';
import 'package:bplus_tv/pages/webdav/view.dart';
import 'package:bplus_tv/smartisan/smartisan_palette.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_dialog.dart' show TvDialogScopes;
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/accounts.dart';
import 'package:bplus_tv/utils/accounts/account.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

/// 紧凑横屏使用顶部分类导航，电视宽屏使用分类侧栏。
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late SettingType _type = SettingType.recommendSetting;
  final RxBool _noAccount = Accounts.account.isEmpty.obs;
  final Map<SettingType, Widget> _panes = {};
  final Map<SettingType, FocusNode> _rowNodes = {};
  final FocusNode _switchAccountFocus = FocusNode(
    debugLabel: 'settings-switch-account',
  );
  final FocusNode _logoutFocus = FocusNode(debugLabel: 'settings-logout');
  bool _inDetailRegion = false;
  final FocusNode _detailFocus = FocusNode(
    debugLabel: 'settings-detail',
    skipTraversal: true,
    canRequestFocus: false,
  );
  int _detailFocusRequest = 0;
  bool _popAfterFocusSyncScheduled = false;
  late ThemeData theme;

  static const List<(String, List<SettingType>)> _sections = [
    (
      '偏好',
      [
        SettingType.privacySetting,
        SettingType.recommendSetting,
        SettingType.videoSetting,
        SettingType.playSetting,
      ],
    ),
    (
      '外观',
      [
        SettingType.uiStyleSetting,
        SettingType.styleSetting,
      ],
    ),
    (
      '更多',
      [
        SettingType.extraSetting,
        SettingType.webdavSetting,
        SettingType.about,
      ],
    ),
  ];

  static const Map<SettingType, IconData> _icons = {
    SettingType.privacySetting: Icons.privacy_tip_outlined,
    SettingType.recommendSetting: Icons.explore_outlined,
    SettingType.videoSetting: Icons.video_settings_outlined,
    SettingType.playSetting: Icons.touch_app_outlined,
    SettingType.uiStyleSetting: Icons.palette_outlined,
    SettingType.styleSetting: Icons.style_outlined,
    SettingType.extraSetting: Icons.extension_outlined,
    SettingType.webdavSetting: MdiIcons.databaseCogOutline,
    SettingType.about: Icons.info_outline,
  };

  static String _labelOf(SettingType type) =>
      type == SettingType.uiStyleSetting ? '界面风格' : type.title;

  FocusNode _rowNode(SettingType type) => _rowNodes.putIfAbsent(type, () {
    return FocusNode(debugLabel: type.name)..addListener(_syncCanPop);
  });

  @override
  void initState() {
    super.initState();
    _detailFocus.addListener(_syncCanPop);
    _switchAccountFocus.addListener(_syncCanPop);
    _logoutFocus.addListener(_syncCanPop);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _rowNode(SettingType.recommendSetting).requestFocus();
    });
  }

  void _syncCanPop() {
    if (_hasSidebarFocus) {
      _inDetailRegion = false;
    } else if (_detailFocus.hasFocus) {
      _inDetailRegion = true;
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void dispose() {
    _detailFocus.removeListener(_syncCanPop);
    _switchAccountFocus
      ..removeListener(_syncCanPop)
      ..dispose();
    _logoutFocus
      ..removeListener(_syncCanPop)
      ..dispose();
    _noAccount.close();
    for (final node in _rowNodes.values) {
      node.dispose();
    }
    _detailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = SimpleScaffold(
      body: ViewSafeArea(
        top: true,
        child: app_pop.PopScope(
          canPop: !_inDetailRegion,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (!_backToSidebar()) _scheduleRoutePop();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1050) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: _header(theme),
                    ),
                    const SizedBox(height: 8),
                    _compactNavigation(theme),
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    Expanded(child: _detail()),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sidebar(theme, availableWidth: constraints.maxWidth),
                  VerticalDivider(
                    width: 1,
                    thickness: 0.8,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                  Expanded(child: _detail()),
                ],
              );
            },
          ),
        ),
      ),
    );
    return TvPageFocus(child: content);
  }

  Widget _sidebar(ThemeData theme, {required double availableWidth}) {
    return SizedBox(
      width: TvConstants.settingSidebarWidth(availableWidth),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(theme),
            const SizedBox(height: 16),
            for (var i = 0; i < _sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 18),
              _sectionLabel(theme, _sections[i].$1),
              const SizedBox(height: 6),
              _group([
                for (var j = 0; j < _sections[i].$2.length; j++)
                  _categoryRow(
                    theme,
                    _sections[i].$2[j],
                    last: j == _sections[i].$2.length - 1,
                  ),
              ]),
            ],
            const SizedBox(height: 18),
            _sectionLabel(theme, '账号'),
            const SizedBox(height: 6),
            Obx(
              () => _group([
                _actionRow(
                  theme,
                  icon: Icons.switch_account_outlined,
                  title: '切换账号',
                  last: _noAccount.value,
                  focusNode: _switchAccountFocus,
                  onTap: () => LoginPageController.switchAccountDialog(context),
                ),
                if (!_noAccount.value)
                  _actionRow(
                    theme,
                    icon: Icons.logout_outlined,
                    title: '退出登录',
                    last: true,
                    focusNode: _logoutFocus,
                    onTap: () => _logoutDialog(context),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactNavigation(ThemeData theme) {
    final types = _sections.expand((section) => section.$2).toList();
    final sectionBreaks = <int>{};
    var sectionEnd = 0;
    for (final section in _sections.take(_sections.length - 1)) {
      sectionEnd += section.$2.length;
      sectionBreaks.add(sectionEnd - 1);
    }
    return SizedBox(
      height: 56,
      child: Obx(() {
        final accountCount = _noAccount.value ? 1 : 2;
        Widget separator(int index) {
          if (sectionBreaks.contains(index) || index == types.length - 1) {
            return SizedBox(
              width: 18,
              height: 36,
              child: VerticalDivider(
                width: 1,
                thickness: 0.8,
                color: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.45,
                ),
              ),
            );
          }
          return const SizedBox(width: 8);
        }

        Widget target(int index) {
          if (index < types.length) {
            return _compactCategoryTarget(theme, types[index]);
          }
          if (index == types.length) {
            return _compactActionTarget(
              theme,
              icon: Icons.switch_account_outlined,
              title: '切换账号',
              focusNode: _switchAccountFocus,
              onTap: () => LoginPageController.switchAccountDialog(context),
            );
          }
          return _compactActionTarget(
            theme,
            icon: Icons.logout_outlined,
            title: '退出登录',
            focusNode: _logoutFocus,
            onTap: () => _logoutDialog(context),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              for (
                var index = 0;
                index < types.length + accountCount;
                index++
              ) ...[
                if (index > 0) separator(index - 1),
                target(index),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _compactCategoryTarget(ThemeData theme, SettingType type) {
    final smartisan = SmartisanStyle.of(context);
    final accent = smartisan
        ? SmartisanStyle.accentOf(theme.brightness)
        : theme.colorScheme.primary;
    final selected = type == _type;
    return TvFocusable(
      focusNode: _rowNode(type),
      onTap: () => _select(type),
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: smartisan
                ? (selected
                      ? accent.withValues(alpha: 0.08)
                      : SmartisanStyle.cardOf(theme.brightness))
                : selected
                ? theme.colorScheme.primary.withValues(alpha: 0.10)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focused
                  ? accent
                  : smartisan
                  ? SmartisanStyle.strokeOf(theme.brightness)
                  : theme.colorScheme.outlineVariant,
              width: focused ? 1.5 : 0.8,
            ),
            boxShadow: smartisan && !focused ? SmartisanStyle.cardShadow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icons[type],
                size: 20,
                color: selected ? accent : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                _labelOf(type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : null,
                  color: smartisan && selected ? accent : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactActionTarget(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required FocusNode focusNode,
    required VoidCallback onTap,
  }) {
    final smartisan = SmartisanStyle.of(context);
    return TvFocusable(
      focusNode: focusNode,
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 12,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: smartisan
                ? SmartisanStyle.cardOf(theme.brightness)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focused
                  ? (smartisan
                        ? SmartisanStyle.accentOf(theme.brightness)
                        : theme.colorScheme.primary)
                  : smartisan
                  ? SmartisanStyle.strokeOf(theme.brightness)
                  : theme.colorScheme.outlineVariant,
              width: focused ? 1.5 : 0.8,
            ),
            boxShadow: smartisan && !focused ? SmartisanStyle.cardShadow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Row(
      children: [
        TvBackButton(onTap: _onHeaderBack),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '设置',
            maxLines: 1,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) {
    final smartisan = SmartisanStyle.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: smartisan
            ? TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SmartisanStyle.secondaryOf(theme.brightness),
              )
            : theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
      ),
    );
  }

  Widget _group(List<Widget> children) {
    final radius = SmartisanStyle.of(context) ? 10.0 : 12.0;
    return netflixSurface(
      radius: radius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _categoryRow(ThemeData theme, SettingType type, {required bool last}) {
    return _row(
      theme,
      icon: _icons[type]!,
      title: _labelOf(type),
      selected: type == _type,
      last: last,
      focusNode: _rowNode(type),
      onTap: () => _select(type),
      onRight: () => _select(type),
    );
  }

  Widget _actionRow(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required bool last,
    required FocusNode focusNode,
    required VoidCallback onTap,
  }) {
    return _row(
      theme,
      icon: icon,
      title: title,
      last: last,
      focusNode: focusNode,
      onTap: onTap,
    );
  }

  Widget _row(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required bool last,
    required VoidCallback onTap,
    String? value,
    FocusNode? focusNode,
    bool autofocus = false,
    bool selected = false,
    VoidCallback? onRight,
  }) {
    final smartisan = SmartisanStyle.of(context);
    final p = smartisan ? SPalette.of(context) : null;
    final scheme = theme.colorScheme;
    final accent = smartisan
        ? SmartisanStyle.accentOf(theme.brightness)
        : scheme.primary;
    final content = Container(
      // Not a fixed height: at a large text scale a 60px row clips its own
      // label. Let the content decide, with a comfortable minimum.
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.symmetric(horizontal: smartisan ? 12 : 10),
      decoration: smartisan
          ? BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.08) : null,
              borderRadius: BorderRadius.circular(10),
            )
          : BoxDecoration(
              color: selected ? scheme.primary.withValues(alpha: 0.10) : null,
              borderRadius: BorderRadius.circular(10),
            ),
      child: Row(
        children: [
          _leadingIcon(icon, selected: selected, accent: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                color: smartisan && selected ? accent : null,
              ),
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 8),
            // Flex + ellipsis: a long value used to push the row past its width.
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(
            Icons.chevron_right,
            size: 18,
            color: p?.chevron ?? scheme.outline,
          ),
        ],
      ),
    );
    Widget focusable = TvFocusable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 10,
        child: content,
      ),
    );
    if (onRight != null) {
      focusable = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            onRight();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: focusable,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: smartisan ? 0 : 8),
          child: focusable,
        ),
        if (!last)
          smartisan
              ? Divider(
                  height: 0.8,
                  thickness: 0.8,
                  color: p!.divider,
                )
              : Padding(
                  padding: const EdgeInsets.only(left: 56, right: 8),
                  child: Divider(
                    height: 0.8,
                    thickness: 0.8,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
      ],
    );
  }

  Widget _leadingIcon(
    IconData icon, {
    required bool selected,
    required Color accent,
  }) {
    if (SmartisanStyle.of(context)) {
      return SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: selected ? accent : SmartisanStyle.iconGrey,
          ),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 18, color: accent),
    );
  }

  Widget _detail() {
    _panes.putIfAbsent(_type, () => _buildSettingContent(_type));
    return Focus(
      focusNode: _detailFocus,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final entry in _panes.entries)
            Offstage(
              offstage: entry.key != _type,
              child: ExcludeFocus(
                excluding: entry.key != _type,
                child: entry.value,
              ),
            ),
        ],
      ),
    );
  }

  void _select(SettingType type) {
    if (_type != type) {
      setState(() {
        // 详情焦点需等布局后请求，因此先同步更新区域，避免返回键直接退出。
        _inDetailRegion = true;
        _type = type;
        _panes.putIfAbsent(type, () => _buildSettingContent(type));
        // 有界缓存：超过 4 个分页时，移除除当前页外最早插入的 2 个
        if (_panes.length > 4) {
          final staleKeys = _panes.keys
              .where((key) => key != _type)
              .take(2)
              .toList();
          for (final key in staleKeys) {
            _panes.remove(key);
          }
        }
      });
    } else if (!_inDetailRegion) {
      setState(() => _inDetailRegion = true);
    }
    _enterDetail();
  }

  void _enterDetail() {
    final request = ++_detailFocusRequest;
    final type = _type;
    final previousFocus = FocusManager.instance.primaryFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || request != _detailFocusRequest || type != _type) return;
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (!identical(FocusManager.instance.primaryFocus, previousFocus) ||
          TvDialogScopes.hasOpenDialog) {
        return;
      }
      final scope = _detailFocus.nearestScope;
      if (scope == null) return;
      for (final node in scope.traversalDescendants) {
        if (!node.canRequestFocus || node.skipTraversal) continue;
        if (!node.ancestors.contains(_detailFocus)) continue;
        node.requestFocus();
        _reveal(node);
        return;
      }
    });
  }

  /// Moves focus back to the rail. Returns false when it was already there,
  /// so the caller (back button / hardware back) can pop the settings route.
  bool _backToSidebar() {
    if (ModalRoute.of(context)?.isCurrent != true || _hasTransientFocus) {
      return false;
    }
    if (!_inDetailRegion && !_detailFocus.hasFocus) return false;
    // 取消尚未执行的详情焦点请求，再将焦点交还给分类栏。
    _detailFocusRequest++;
    setState(() => _inDetailRegion = false);
    final row = _rowNode(_type)..requestFocus();
    _reveal(row);
    return true;
  }

  bool get _hasTransientFocus {
    final primary = FocusManager.instance.primaryFocus;
    return TvDialogScopes.hasOpenDialog ||
        TvDialogScopes.contains(primary) ||
        primary?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool get _hasSidebarFocus =>
      _rowNodes.values.any((node) => node.hasFocus) ||
      _switchAccountFocus.hasFocus ||
      _logoutFocus.hasFocus;

  void _scheduleRoutePop() {
    if (_popAfterFocusSyncScheduled) return;
    _popAfterFocusSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _popAfterFocusSyncScheduled = false;
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (_inDetailRegion || _detailFocus.hasFocus || _hasTransientFocus) {
        return;
      }
      Get.back();
    });
  }

  void _reveal(FocusNode node) {
    final nodeContext = node.context;
    if (nodeContext == null) return;
    Scrollable.ensureVisible(
      nodeContext,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _onHeaderBack() {
    if (_backToSidebar()) return;
    if (ModalRoute.of(context)?.isCurrent != true || _hasTransientFocus) return;
    Get.back();
  }

  Widget _buildSettingContent(SettingType type) {
    if (type == SettingType.privacySetting ||
        type == SettingType.recommendSetting ||
        type == SettingType.videoSetting ||
        type == SettingType.playSetting ||
        type == SettingType.styleSetting ||
        type == SettingType.extraSetting) {
      return CommonSetting(
        settingType: type,
        showAppBar: false,
        embedded: true,
      );
    } else if (type == SettingType.uiStyleSetting) {
      return const StyleSettingsPage(showAppBar: false, embedded: true);
    } else if (type == SettingType.webdavSetting) {
      return const WebDavSettingPage(showAppBar: false, embedded: true);
    } else if (type == SettingType.about) {
      return const AboutPage(showAppBar: false, embedded: true);
    }
    return const SizedBox.shrink();
  }

  Future<void> _removeAccounts(Set<LoginAccount> accounts) async {
    await Accounts.deleteAll(accounts);
    if (mounted) _noAccount.value = Accounts.account.isEmpty;
  }

  static Future<LoginAccount?> _logoutWrapper(LoginAccount account) async {
    try {
      final res = await LoginHttp.logout(account);
      return res.isSuccess ? account : null;
    } catch (e, s) {
      Utils.reportError(e, s);
      return null;
    }
  }

  Future<void> _logoutDialog(BuildContext context) async {
    final result = await showDialog<Set<LoginAccount>>(
      context: context,
      builder: (context) => MultiSelectDialog<LoginAccount>(
        title: '选择要登出的账号uid',
        initValues: const Iterable.empty(),
        values: {
          for (final i in Accounts.account.values) i: i.mid.toString(),
        },
      ),
    );
    if (!context.mounted || result == null || result.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(
            "确认要退出以下账号登录吗\n\n${result.map((i) => i.mid).join('\n')}",
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: Text(
                '点错了',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _removeAccounts(result);
              },
              child: Text(
                '仅登出',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            TextButton(
              onPressed: () async {
                SmartDialog.showLoading();
                final res = await Future.wait(result.map(_logoutWrapper));
                SmartDialog.dismiss();
                final logoutAccounts = res.nonNulls.toSet();
                if (logoutAccounts.isEmpty) {
                  SmartDialog.showToast('所选账号均退出登录失败');
                } else {
                  Get.back();
                  _removeAccounts(logoutAccounts);
                  if (logoutAccounts.length != result.length) {
                    result.removeWhere(logoutAccounts.contains);
                    SmartDialog.showToast(
                      '账号 ${result.map((i) => i.mid).join(",")} 退出登录失败',
                    );
                  }
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }
}
