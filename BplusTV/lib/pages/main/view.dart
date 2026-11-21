import 'dart:io';

import 'package:bplus_tv/common/widgets/app_background.dart';
import 'package:bplus_tv/common/widgets/flutter/pop_scope.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/main_layout.dart';
import 'package:bplus_tv/common/widgets/route_aware_mixin.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:bplus_tv/smartisan/smartisan_palette.dart';
import 'package:bplus_tv/models/common/nav_bar_config.dart';
import 'package:bplus_tv/pages/main/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/utils/app_scheme.dart';
import 'package:bplus_tv/utils/extension/theme_ext.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends PopScopeState<MainApp>
    with RouteAware, RouteAwareMixin, WidgetsBindingObserver {
  final _mainController = Get.put(MainController());
  late EdgeInsets _padding;
  late ColorScheme _colorScheme;
  bool _tvFocusInitialized = false;
  bool _focusRecoveryScheduled = false;
  FocusNode? _lastTvFocus;

  bool _hasActiveFocus(FocusNode? node) =>
      TvFocusUtils.isFocusable(node, within: FocusScope.of(context));

  @override
  bool get initCanPop => false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onPrimaryFocusChanged);
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      PiliScheme.init();
    }
  }

  void _onPrimaryFocusChanged() {
    if (!mounted) return;
    final primary = FocusManager.instance.primaryFocus;
    if (_hasActiveFocus(primary) && !TvDialogScopes.contains(primary)) {
      _lastTvFocus = primary;
    }
    if (_focusRecoveryScheduled) return;
    _focusRecoveryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusRecoveryScheduled = false;
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      final primary = FocusManager.instance.primaryFocus;
      if (_hasActiveFocus(primary)) return;
      _tvFocusTries = 0;
      _ensureTvFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _padding = MediaQuery.viewPaddingOf(context);
    _colorScheme = ColorScheme.of(context);
    final brightness = _colorScheme.brightness;
    NetworkImgLayer.reduce =
        NetworkImgLayer.reduceLuxColor != null && brightness.isDark;
    if (!_tvFocusInitialized) {
      _tvFocusInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTvFocus());
    }
  }

  int _tvFocusTries = 0;

  void _ensureTvFocus() {
    // 延迟重试也必须复查路由和弹窗，不能在离开主页后继续抢焦点。
    if (!mounted ||
        _tvFocusTries > 20 ||
        ModalRoute.of(context)?.isCurrent == false ||
        TvDialogScopes.hasOpenDialog) {
      return;
    }
    if (_hasActiveFocus(FocusManager.instance.primaryFocus)) return;
    if (_hasActiveFocus(_lastTvFocus)) {
      _lastTvFocus!.requestFocus();
      return;
    }
    final ok = FocusScope.of(context).nextFocus();
    if (!ok) {
      _tvFocusTries++;
      Future.delayed(const Duration(milliseconds: 500), _ensureTvFocus);
    }
  }

  @override
  void didPopNext() {
    _mainController
      ..checkUnreadDynamic()
      ..checkDefaultSearch(true)
      ..checkUnread();
    // 返回主页后恢复遥控器焦点，避免方向键失效。
    _tvFocusTries = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTvFocus());
    super.didPopNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mainController
        ..checkUnreadDynamic()
        ..checkDefaultSearch(true)
        ..checkUnread();
      _tvFocusTries = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTvFocus());
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onPrimaryFocusChanged);
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isAndroid) {
      PiliScheme.listener?.cancel();
    }
    super.dispose();
  }

  @pragma('vm:prefer-inline')
  static void _onBack() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    }
  }

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) return;
    if (_mainController.directExitOnBack) {
      _onBack();
    } else {
      if (_mainController.selectedIndex.value != 0) {
        _mainController
          ..setIndex(0)
          ..setSearchBar();
      } else {
        _onBack();
      }
    }
  }

  Widget _sideBar(double availableWidth) {
    if (_mainController.navigationBars.length > 1) {
      return _navBar(
        availableWidth: availableWidth,
        child: _sideBarContent,
      );
    }
    return Container(
      width: (availableWidth * TvShellMetrics.railWidthFactor)
          .clamp(
            TvShellMetrics.minimumRailWidth,
            TvShellMetrics.maximumRailWidth,
          )
          .toDouble(),
      margin: .only(top: 12 + _padding.top, left: _padding.left),
      child: userAndSearchVertical(),
    );
  }

  Widget _sideBarContent({required bool compact}) {
    return Obx(() {
      final selectedIndex = _mainController.selectedIndex.value;
      final destinations = _mainController.navigationBars;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: compact ? 6 : 12),
          userAndSearchVertical(),
          SizedBox(height: compact ? 6 : 12),
          Divider(
            height: 1,
            indent: 18,
            endIndent: 18,
            color: _colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          SizedBox(height: compact ? 4 : 10),
          for (var i = 0; i < destinations.length; i++)
            _sideBarTile(
              type: destinations[i],
              selected: selectedIndex == i,
              compact: compact,
              onTap: () => _mainController.setIndex(i),
            ),
          SizedBox(height: compact ? 6 : 12),
        ],
      );
    });
  }

  Widget _sideBarTile({
    required NavigationBarType type,
    required bool selected,
    required bool compact,
    required VoidCallback onTap,
  }) {
    final smartisan = SmartisanStyle.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: compact ? 2 : 4),
      child: TvFocusable(
        onTap: onTap,
        builder: (context, focused, hovered) {
          final p = smartisan ? SPalette.of(context) : null;
          return TvFocusHighlight(
            focused: focused,
            radius: 10,
            borderWidth: 2,
            child: Tooltip(
              message: type.label,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: selected
                      ? _colorScheme.onSurface.withValues(alpha: 0.10)
                      : Colors.transparent,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: 24,
                    color: smartisan
                        ? selected
                              ? p!.brandSelected
                              : p!.iconDisabled
                        : selected
                        ? _colorScheme.primary
                        : _colorScheme.onSurfaceVariant,
                  ),
                  child: _buildIcon(type: type, selected: selected),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _navBar({
    required double availableWidth,
    required Widget Function({required bool compact}) child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 660;
        final railWidth = (availableWidth * TvShellMetrics.railWidthFactor)
            .clamp(
              TvShellMetrics.minimumRailWidth,
              TvShellMetrics.maximumRailWidth,
            )
            .toDouble();
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TvShellMetrics.railOuterPadding / 2,
              vertical: 6,
            ),
            child: netflixNavSurface(
              child: SizedBox(
                width: railWidth,
                child: SingleChildScrollView(
                  primary: false,
                  child: child(compact: compact),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_mainController.mainTabBarView) {
      child = TabBarView(
        controller: _mainController.controller,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: .vertical,
        children: _mainController.navigationBars.map((i) => i.page).toList(),
      );
    } else {
      child = PageView(
        controller: _mainController.controller,
        physics: const NeverScrollableScrollPhysics(),
        children: _mainController.navigationBars.map((i) => i.page).toList(),
      );
    }

    final pages = child;
    child = Material(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ignore: prefer_const_constructors
          AppBackground(),
          LayoutBuilder(
            builder: (context, constraints) => BackdropGroup(
              child: MainLayout(
                sideBar: _sideBar(constraints.maxWidth),
                bottomNav: null,
                body: Padding(
                  padding: .only(top: _padding.top, right: _padding.right),
                  child: pages,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return child;
  }

  Widget _buildIcon({required NavigationBarType type, bool selected = false}) {
    final icon = selected ? type.selectIcon : type.icon;
    return type == .dynamics
        ? Obx(
            () {
              final dynCount = _mainController.dynCount.value;
              return Badge(
                isLabelVisible: dynCount > 0,
                label: _mainController.dynamicBadgeMode == .number
                    ? Text(dynCount.toString())
                    : null,
                padding: const .symmetric(horizontal: 6),
                child: icon,
              );
            },
          )
        : icon;
  }

  Widget userAndSearchVertical() {
    return Column(
      children: [
        const SizedBox(height: 8),
        TvFocusable(
          onTap: () => Get.toNamed('/search'),
          builder: (context, focused, hovered) => TvFocusHighlight(
            focused: focused,
            radius: 16,
            child: const SizedBox.square(
              dimension: 48,
              child: Icon(
                Icons.search_outlined,
                size: 24,
                semanticLabel: '搜索',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
