import 'package:bplus_tv/common/widgets/dialog/report_member.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/scroll_behavior.dart'
    show NoOverscrollIndicator;
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/user.dart';
import 'package:bplus_tv/models_new/space/space/data.dart';
import 'package:bplus_tv/models_new/space/space/reservation_card_list.dart';
import 'package:bplus_tv/models_new/space/space/tab2.dart';
import 'package:bplus_tv/pages/coin_log/controller.dart';
import 'package:bplus_tv/pages/exp_log/controller.dart';
import 'package:bplus_tv/pages/log_table/view.dart';
import 'package:bplus_tv/pages/login_devices/view.dart';
import 'package:bplus_tv/pages/login_log/controller.dart';
import 'package:bplus_tv/pages/member/controller.dart';
import 'package:bplus_tv/pages/member/widget/reserve_button.dart';

import 'package:bplus_tv/pages/member_cheese/view.dart';
import 'package:bplus_tv/pages/member_contribute/controller.dart';
import 'package:bplus_tv/pages/member_contribute/view.dart';
import 'package:bplus_tv/pages/member_dynamics/view.dart';
import 'package:bplus_tv/pages/member_favorite/view.dart';
import 'package:bplus_tv/pages/member_home/view.dart';
import 'package:bplus_tv/pages/member_pgc/view.dart';
import 'package:bplus_tv/pages/member_shop/view.dart';
import 'package:bplus_tv/pages/member_video_web/archive/view.dart';
import 'package:bplus_tv/pages/member_video_web/season_series/view.dart';
import 'package:bplus_tv/pages/common/common_page.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart' show TvBackButton;
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends CommonPageState<MemberPage>
    with AutomaticKeepAliveClientMixin {
  late final int _mid;
  late final String _heroTag;
  late final MemberController _userController;
  late final PageController _headerPageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _mid = int.tryParse(Get.parameters['mid']!) ?? -1;
    _heroTag = Utils.makeHeroTag(_mid);
    _userController = Get.put(
      MemberController(mid: _mid),
      tag: _heroTag,
    );
    _headerPageController = PageController();
  }

  @override
  void dispose() {
    _headerPageController.dispose();
    _cacheFollowTime = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context).colorScheme;
    final content = Material(
      color: theme.surface,
      child: Obx(
        () => switch (_userController.loadingState.value) {
          Loading() => m3eLoading,
          Success(:final response) => _buildTvBody(
            context,
            theme,
            response,
          ),
          Error(:final errMsg) => scrollErrorWidget(
            errMsg: errMsg,
            onReload: _userController.onReload,
          ),
        },
      ),
    );
    // 进入主页及返回主页时恢复本页焦点。
    return TvPageFocus(child: content);
  }

  Widget _buildTvBody(
    BuildContext context,
    ColorScheme theme,
    SpaceData? response,
  ) {
    final padding = MediaQuery.viewPaddingOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1600),
        child: ExtendedNestedScrollView(
          onlyOneScrollInBody: true,
          key: _userController.scrollKey,
          scrollBehavior: const NoOverscrollIndicator(),
          pinnedHeaderSliverHeightBuilder: () =>
              kToolbarHeight + MediaQuery.viewPaddingOf(context).top,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            if (response != null) {
              return [
                SliverAppBar(
                  pinned: true,
                  actions: _actions(theme),
                  automaticallyImplyLeading: false,
                  leading: const TvBackButton(autofocus: true),
                  title: Text(_userController.username ?? ''),
                ),
                if (response.card != null)
                  SliverToBoxAdapter(
                    child: _buildProfileSummary(response, theme),
                  ),
              ];
            }
            return [
              SliverAppBar(
                pinned: true,
                actions: _actions(theme),
                automaticallyImplyLeading: false,
                leading: const TvBackButton(autofocus: true),
                title: GestureDetector(
                  onTap: _userController.onReload,
                  behavior: HitTestBehavior.opaque,
                  child: Text(_userController.username ?? ''),
                ),
              ),
            ];
          },
          body: _userController.tab2?.isNotEmpty == true
              ? Padding(
                  padding: .only(left: padding.left, right: padding.right),
                  child: Column(
                    children: [
                      if ((_userController.tab2?.length ?? 0) > 1)
                        _buildTabBar(theme),
                      Expanded(child: _buildBody),
                    ],
                  ),
                )
              : scrollableError,
        ),
      ),
    );
  }

  Widget _buildProfileSummary(SpaceData response, ColorScheme colorScheme) {
    final card = response.card!;
    final isOwner = _userController.mid == _userController.account.mid;

    Widget stat(String label, String value, VoidCallback? onTap) {
      return TvFocusable(
        onTap: onTap,
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 12,
          borderWidth: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
          child: netflixSurface(
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      NetworkImgLayer(
                        src: card.face,
                        type: .avatar,
                        width: 72,
                        height: 72,
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              card.name ?? _userController.username ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (card.officialVerify?.desc?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 5),
                              Text(
                                card.officialVerify!.desc!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: colorScheme.primary),
                              ),
                            ],
                            if (card.sign?.isNotEmpty == true) ...[
                              const SizedBox(height: 7),
                              Text(
                                card.sign!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      stat('关注', '${card.attention ?? 0}', () {
                        Get.toNamed(
                          '/follow',
                          arguments: {
                            'mid': _userController.mid,
                            'name': card.name,
                          },
                        );
                      }),
                      stat('粉丝', '${card.fans ?? 0}', () {
                        Get.toNamed(
                          '/fan',
                          arguments: {
                            'mid': _userController.mid,
                            'name': card.name,
                          },
                        );
                      }),
                      Obx(() {
                        final relation = _userController.relation.value;
                        final actionLabel = isOwner
                            ? '编辑资料'
                            : relation == 128
                            ? '移除黑名单'
                            : _userController.isFollow
                            ? '已关注'
                            : '关注';
                        return TvFocusButton(
                          onTap: () => _userController.onFollow(context),
                          radius: 14,
                          child: SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _userController.onFollow(context),
                              icon: Icon(
                                isOwner
                                    ? Icons.edit_outlined
                                    : Icons.person_add_alt_1,
                              ),
                              label: Text(actionLabel),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shared nav surface used by the fixed top chrome, matching the main
  /// shell's `_navBar` (rounded superellipse + rim) so the header and tab
  /// strip read as one material.
  Widget _navBar({required Widget child, double radius = 26}) {
    return netflixSurface(radius: radius, child: child);
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    final tabController = _userController.tabController;
    final tabs = _userController.tabs;
    if (tabController == null) return const SizedBox.shrink();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _navBar(
            child: AnimatedBuilder(
              animation: tabController,
              builder: (context, _) => Row(
                children: tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  final selected = tabController.index == index;
                  return Expanded(
                    child: TvFocusable(
                      onTap: () {
                        feedBack();
                        _userController.onTapTab(index);
                        if (!tabController.indexIsChanging) {
                          tabController.animateTo(index);
                        }
                      },
                      builder: (context, focused, hovered) => TvFocusHighlight(
                        focused: focused,
                        radius: 16,
                        borderWidth: 2,
                        child: Container(
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(
                            minHeight: 52,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Text(
                            tab.text ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reserveBtn(List<ReservationCardItem> list, ColorScheme theme) {
    {
      return TvFocusable(
        onTap: () => _showReserveList(list),
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 16,
          borderWidth: 2,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: ReserveButton(
                count: list.length,
                color: theme.onSurfaceVariant,
                child: const Icon(Icons.notifications_none),
              ),
            ),
          ),
        ),
      );
    }
  }

  void _showReserveList(List<ReservationCardItem> list) {
    {
      _showReserveListTV(list);
      return;
    }
  }

  void _showReserveListTV(List<ReservationCardItem> list) {
    showDialog(
      context: context,
      builder: (_) => tvDialogShell(
        title: '预约列表',
        minWidth: 420,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: list.map((e) {
              Future<void> onToggle() async {
                final isFollow = e.isFollow;
                final res = await UserHttp.spaceReserve(
                  sid: e.sid!,
                  isFollow: isFollow,
                );
                if (res.isSuccess) {
                  e
                    ..total += isFollow ? -1 : 1
                    ..isFollow = !isFollow;
                } else {
                  res.toast();
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.name!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TvFocusButton(
                      onTap: onToggle,
                      child: FilledButton.tonal(
                        onPressed: onToggle,
                        style: FilledButton.styleFrom(
                          tapTargetSize: .shrinkWrap,
                          minimumSize: const Size(84, 48),
                          padding: const .symmetric(horizontal: 10),
                          shape: const RoundedRectangleBorder(
                            borderRadius: .all(.circular(6)),
                          ),
                        ),
                        child: Text('${e.isFollow ? '已' : ''}预约'),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TvDialogAction(
            label: '关闭',
            autofocus: true,
            onTap: Get.back,
          ),
        ],
      ),
    );
  }

  List<Widget> _actions(ColorScheme theme) {
    {
      return [
        if (_userController.reserves?.isNotEmpty ?? false)
          _reserveBtn(_userController.reserves!, theme),
        if (_userController.mid == _userController.account.mid)
          TvFocusable(
            onTap: () => Get.toNamed(
              '/memberSearch?mid=$_mid&uname=${_userController.username}',
            ),
            builder: (context, focused, hovered) => TvFocusHighlight(
              focused: focused,
              radius: 16,
              borderWidth: 2,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(Icons.search_outlined, size: 24),
              ),
            ),
          ),
        TvFocusable(
          onTap: _showMoreMenu,
          builder: (context, focused, hovered) => TvFocusHighlight(
            focused: focused,
            radius: 16,
            borderWidth: 2,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: const Icon(Icons.more_vert, size: 24),
            ),
          ),
        ),
      ];
    }
  }

  void _showMoreMenu() {
    final items = <Widget>[];
    final ctrl = _userController;

    if (ctrl.account.isLogin && ctrl.account.mid != _mid) {
      items.add(
        _menuItem(
          icon: Icons.block,
          label: ctrl.relation.value != 128 ? '加入黑名单' : '移除黑名单',
          onTap: () {
            Get.back();
            ctrl.blockUser(context);
          },
        ),
      );
      if (ctrl.isFollowed == 1) {
        items.add(
          _menuItem(
            icon: Icons.remove_circle_outline_outlined,
            label: '移除粉丝',
            onTap: () {
              Get.back();
              ctrl.onRemoveFan();
            },
          ),
        );
      }
    }

    items.add(
      _menuItem(
        icon: Icons.share_outlined,
        label: ctrl.account.mid != _mid ? '分享UP主' : '分享我的主页',
        onTap: () {
          Get.back();
          ctrl.shareUser();
        },
      ),
    );

    if (Get.isRegistered<MemberContributeCtr>(tag: _heroTag)) {
      items.add(
        _menuItem(
          icon: Icons.extension_outlined,
          label: '网页投稿',
          onTap: () {
            Get.back();
            _toWebArchive();
          },
        ),
      );
    }

    if (ctrl.account.isLogin && ctrl.mid == ctrl.account.mid) {
      if ((ctrl.loadingState.value.dataOrNull?.card?.vip?.status ?? 0) > 0) {
        items.add(
          _menuItem(
            icon: Icons.upcoming_outlined,
            label: '大会员经验',
            onTap: () {
              Get.back();
              ctrl.vipExpAdd();
            },
          ),
        );
      }
      items.add(
        _menuItem(
          icon: Icons.devices,
          label: '登录设备',
          onTap: () {
            Get.back();
            Get.to(const LoginDevicesPage());
          },
        ),
      );
      items.add(
        _menuItem(
          icon: Icons.login,
          label: '登录记录',
          onTap: () {
            Get.back();
            Get.to(const LogPage(), arguments: LoginLogController());
          },
        ),
      );
      items.add(
        _menuItem(
          icon: FontAwesomeIcons.b,
          label: '硬币记录',
          onTap: () {
            Get.back();
            Get.to(const LogPage(), arguments: CoinLogController());
          },
        ),
      );
      items.add(
        _menuItem(
          icon: Icons.linear_scale,
          label: '经验记录',
          onTap: () {
            Get.back();
            Get.to(const LogPage(), arguments: ExpLogController());
          },
        ),
      );
      items.add(
        _menuItem(
          icon: Icons.settings_outlined,
          label: '空间设置',
          onTap: () {
            Get.back();
            Get.toNamed('/spaceSetting');
          },
        ),
      );
    } else {
      if (ctrl.isFollow) {
        items.add(
          _menuItem(
            icon: Icons.more_time_outlined,
            label: '关注时间',
            onTap: () {
              Get.back();
              _showFollowTime();
            },
          ),
        );
      }
      items.add(
        _menuItem(
          icon: Icons.error_outline,
          label: '举报',
          onTap: () {
            Get.back();
            showMemberReportDialog(context, name: ctrl.username, mid: _mid);
          },
        ),
      );
    }

    showDialog(
      context: context,
      builder: (_) => tvDialogShell(
        title: '更多',
        minWidth: 420,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items,
          ),
        ),
        actions: [
          TvDialogAction(
            label: '关闭',
            autofocus: true,
            onTap: Get.back,
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 12,
        borderWidth: 2,
        // ListTile 默认 enabled 时即使没有 onTap 也会抢占焦点，TV 下必须排除，
        // 否则焦点会落到无回调的 tile 上（按确认无反应、且外圈高亮消失）。
        child: ExcludeFocus(
          child: ListTile(
            dense: true,
            leading: Icon(icon, size: 19),
            title: Text(label),
          ),
        ),
      ),
    );
  }

  Widget get _buildBody => tabBarView(
    hitTestBehavior: .translucent,
    controller: _userController.tabController,
    children: _userController.tab2!.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return AnimatedBuilder(
        animation: _userController.tabController!,
        child: _buildTabPage(item),
        builder: (context, child) => ExcludeFocus(
          excluding: _userController.tabController!.index != index,
          child: child!,
        ),
      );
    }).toList(),
  );

  Widget _buildTabPage(SpaceTab2 item) {
    return switch (item.param) {
      'home' => MemberHome(heroTag: _heroTag),
      'dynamic' => MemberDynamicsPage(mid: _mid),
      'contribute' => Obx(
        () => MemberContribute(
          heroTag: _heroTag,
          initialIndex: _userController.contributeInitialIndex.value,
          mid: _mid,
        ),
      ),
      'bangumi' => MemberBangumi(
        heroTag: _heroTag,
        mid: _mid,
      ),
      'favorite' => MemberFavorite(
        heroTag: _heroTag,
        mid: _mid,
      ),
      'cheese' => MemberCheese(
        heroTag: _heroTag,
        mid: _mid,
      ),
      'shop' => MemberShop(
        heroTag: _heroTag,
        mid: _mid,
      ),
      _ => Center(child: Text(item.title ?? '')),
    };
  }

  String? _cacheFollowTime;
  Future<void> _showFollowTime() async {
    void onShow() {
      if (!mounted) return;
      {
        showDialog(
          context: context,
          builder: (_) => tvDialogShell(
            title: _userController.username ?? '',
            minWidth: 420,
            content: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                _cacheFollowTime!,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            actions: [
              TvDialogAction(
                label: '关闭',
                autofocus: true,
                onTap: Get.back,
              ),
            ],
          ),
        );
        return;
      }
    }

    if (_cacheFollowTime != null) {
      onShow();
      return;
    }
    final res = await UserHttp.userRelation(_mid);
    if (res case Success(:final response)) {
      if (response.mtime == null) return;
      _cacheFollowTime =
          '关注时间: ${DateFormatUtils.longFormatDs.format(
            DateTime.fromMillisecondsSinceEpoch(response.mtime! * 1000),
          )}';
      onShow();
    } else {
      res.toast();
    }
  }

  void _toWebArchive() {
    try {
      final ctr = Get.find<MemberContributeCtr>(tag: _heroTag);
      final item = ctr.items?[ctr.tabController?.index ?? 0];
      if (item != null) {
        final id = item.seasonId ?? item.seriesId;
        if (id != null) {
          MemberSSWeb.toMemberSSWeb(
            type: item.seasonId != null ? .season : .series,
            id: id,
            mid: _mid,
            name: _userController.username ?? '',
          );
          return;
        }
      }
      MemberVideoWeb.toMemberVideoWeb(
        mid: _mid,
        name: _userController.username ?? '',
      );
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }
}
