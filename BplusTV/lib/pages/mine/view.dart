import 'dart:async';

import 'package:bplus_tv/common/assets.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/flutter/list_tile.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/player_bar.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/nav_bar_config.dart';
import 'package:bplus_tv/models_new/fav/fav_folder/list.dart';
import 'package:bplus_tv/pages/common/common_page.dart';
import 'package:bplus_tv/pages/login/controller.dart';
import 'package:bplus_tv/pages/main/controller.dart';
import 'package:bplus_tv/pages/mine/controller.dart';
import 'package:bplus_tv/pages/mine/widgets/item.dart';
import 'package:bplus_tv/utils/bili_utils.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:bplus_tv/utils/extension/get_ext.dart';
import 'package:bplus_tv/utils/extension/num_ext.dart';
import 'package:bplus_tv/utils/extension/theme_ext.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class MinePage extends StatefulWidget {
  const MinePage({super.key, this.showBackBtn = false});

  final bool showBackBtn;

  @override
  State<MinePage> createState() => _MediaPageState();
}

class _MediaPageState extends CommonPageState<MinePage>
    with AutomaticKeepAliveClientMixin {
  final MineController controller = Get.putOrFind(MineController.new);
  late final MainController _mainController = Get.find<MainController>();

  @override
  bool get wantKeepAlive => true;

  bool get checkPage =>
      _mainController.navigationBars[0] != NavigationBarType.mine &&
      _mainController.selectedIndex.value == 0;

  @override
  bool onNotificationType1(UserScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType1(notification);
  }

  @override
  bool onNotificationType2(ScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType2(notification);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    return Column(
      children: [
        Padding(
          padding: const .symmetric(vertical: 10),
          child: _buildHeaderActions,
        ),
        Expanded(
          child: Material(
            type: .transparency,
            child: refreshIndicator(
              onRefresh: controller.onRefresh,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: onBuild(
                    ListView(
                      padding: const .only(bottom: 100),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 1000) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildUserInfo(theme, secondary),
                                  ),
                                  Expanded(
                                    flex: 6,
                                    child: _buildActions(secondary),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildUserInfo(theme, secondary),
                                _buildActions(secondary),
                              ],
                            );
                          },
                        ),
                        Obx(
                          () => controller.loadingState.value is Loading
                              ? const SizedBox.shrink()
                              : _buildFav(theme, secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(Color primary) {
    final list = controller.list;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: netflixSurface(
        radius: 20,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: .stretch,
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i != 0) _cardDivider(),
                Expanded(
                  child: _buildActionTile(
                    icon: list[i].icon,
                    title: list[i].title,
                    onTap: list[i].onTap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardDivider() {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, hovered) {
        return TvFocusHighlight(
          focused: focused,
          radius: 20,
          borderWidth: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Column(
              spacing: 8,
              mainAxisSize: .min,
              mainAxisAlignment: .center,
              children: [
                Icon(icon, size: 30, color: colorScheme.primary),
                Text(
                  title,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget get _buildHeaderActions {
    const iconSize = 22.0;
    const padding = EdgeInsets.all(8);
    return PlayerBar(
      children: [
        if (widget.showBackBtn)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TvFocusButton(
              onTap: Get.back,
              radius: 16,
              // 内层按钮只负责视觉呈现，返回动作由外层统一处理，避免双响 pop 两次。
              child: BackButton(onPressed: () {}),
            ),
          )
        else
          const SizedBox.shrink(),
        Center(
          child: netflixNavSurface(
            child: Row(
              spacing: 5,
              mainAxisSize: .min,
              children: [
                if (!_mainController.hasHome)
                  TvFocusable(
                    onTap: () => Get.toNamed('/search'),
                    builder: (context, focused, hovered) => TvFocusHighlight(
                      focused: focused,
                      radius: 16,
                      borderWidth: 2,
                      child: Container(
                        width: iconSize + padding.horizontal + 10,
                        height: iconSize + padding.vertical + 10,
                        alignment: Alignment.center,
                        child: const Icon(Icons.search, size: iconSize),
                      ),
                    ),
                  ),
                Obx(
                  () {
                    final anonymity = MineController.anonymity.value;
                    final icon = anonymity
                        ? MdiIcons.incognito
                        : MdiIcons.incognitoOff;
                    return TvFocusable(
                      onTap: MineController.onChangeAnonymity,
                      builder: (context, focused, hovered) => TvFocusHighlight(
                        focused: focused,
                        radius: 16,
                        borderWidth: 2,
                        child: Container(
                          width: iconSize + padding.horizontal + 10,
                          height: iconSize + padding.vertical + 10,
                          alignment: Alignment.center,
                          child: Icon(icon, size: iconSize),
                        ),
                      ),
                    );
                  },
                ),
                TvFocusable(
                  onTap: () => LoginPageController.switchAccountDialog(context),
                  builder: (context, focused, hovered) => TvFocusHighlight(
                    focused: focused,
                    radius: 16,
                    borderWidth: 2,
                    child: Container(
                      width: iconSize + padding.horizontal + 10,
                      height: iconSize + padding.vertical + 10,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.switch_account_outlined,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
                Obx(
                  () {
                    final themeIcon = controller.themeType.value.icon;
                    return TvFocusable(
                      onTap: controller.onChangeTheme,
                      builder: (context, focused, hovered) => TvFocusHighlight(
                        focused: focused,
                        radius: 16,
                        borderWidth: 2,
                        child: Container(
                          width: iconSize + padding.horizontal + 10,
                          height: iconSize + padding.vertical + 10,
                          alignment: Alignment.center,
                          child: themeIcon,
                        ),
                      ),
                    );
                  },
                ),
                TvFocusable(
                  onTap: () =>
                      Get.toNamed('/setting', preventDuplicates: false),
                  builder: (context, focused, hovered) => TvFocusHighlight(
                    focused: focused,
                    radius: 16,
                    borderWidth: 2,
                    child: Container(
                      width: iconSize + padding.horizontal + 10,
                      height: iconSize + padding.vertical + 10,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.settings_outlined,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(ThemeData theme, Color secondary) {
    final style = TextStyle(
      fontSize: theme.textTheme.titleMedium!.fontSize,
      fontWeight: FontWeight.bold,
    );
    final labelStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    final coinLabelStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      color: theme.colorScheme.outline,
    );
    final coinValStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      fontWeight: FontWeight.bold,
      color: secondary,
    );
    return Obx(() {
      final userInfo = controller.userInfo.value;
      final levelInfo = userInfo.levelInfo;
      final hasLevel = levelInfo != null;
      final isVip = userInfo.vipStatus != null && userInfo.vipStatus! > 0;
      final userStat = controller.userStat.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: netflixSurface(
          radius: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 身份区：头像 + 昵称/等级 + 硬币/经验。焦点用光晕反馈。
              TvFocusable(
                onTap: controller.onLogin,
                onLongPress: () {
                  Feedback.forLongPress(context);
                  controller.onLogin(true);
                },
                builder: (context, focused, hovered) {
                  return TvFocusHighlight(
                    focused: focused,
                    radius: 20,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          userInfo.face != null
                              ? Stack(
                                  clipBehavior: .none,
                                  children: [
                                    NetworkImgLayer(
                                      src: userInfo.face,
                                      type: .avatar,
                                      width: 72,
                                      height: 72,
                                    ),
                                    if (isVip)
                                      Positioned(
                                        right: -1,
                                        bottom: -2,
                                        child: SvgPicture.asset(
                                          Assets.vipIcon,
                                          height: 19,
                                          semanticsLabel: "大会员",
                                        ),
                                      ),
                                  ],
                                )
                              : ClipOval(
                                  child: Image.asset(
                                    width: 72,
                                    height: 72,
                                    cacheHeight: 72.cacheSize(context),
                                    Assets.avatarPlaceHolder,
                                    semanticLabel: "默认头像",
                                  ),
                                ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: .min,
                              mainAxisAlignment: .center,
                              crossAxisAlignment: .start,
                              children: [
                                Row(
                                  spacing: 6,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        userInfo.uname ?? '点击登录',
                                        style: theme.textTheme.titleMedium!
                                            .copyWith(
                                              height: 1,
                                              color:
                                                  isVip && userInfo.vipType == 2
                                                  ? theme.colorScheme.vipColor
                                                  : null,
                                            ),
                                        maxLines: 1,
                                        overflow: .ellipsis,
                                      ),
                                    ),
                                    BiliUtils.levelPicture(
                                      levelInfo?.currentLevel ?? 0,
                                      isSeniorMember:
                                          userInfo.isSeniorMember == 1,
                                      height: 10,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '硬币 ',
                                        style: coinLabelStyle,
                                      ),
                                      TextSpan(
                                        text: userInfo.money?.toString() ?? '-',
                                        style: coinValStyle,
                                      ),
                                      TextSpan(
                                        text: "      经验 ",
                                        style: coinLabelStyle,
                                      ),
                                      TextSpan(
                                        text:
                                            levelInfo?.currentExp?.toString() ??
                                            '-',
                                        style: coinValStyle,
                                      ),
                                      TextSpan(
                                        text: "/${levelInfo?.nextExp ?? '-'}",
                                        style: coinLabelStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 225,
                                  ),
                                  child: LinearProgressIndicator(
                                    minHeight: 2.25,
                                    value: hasLevel
                                        ? levelInfo.currentExp! /
                                              levelInfo.nextExp!
                                        : 0,
                                    backgroundColor: theme.colorScheme.outline
                                        .withValues(alpha: 0.4),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      secondary,
                                    ),
                                    stopIndicatorColor: Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: theme.dividerColor.withValues(alpha: 0.08),
              ),
              // 固定高度细分隔线，与内容行居中对齐。
              Row(
                crossAxisAlignment: .center,
                children: [
                  _buildStatTile(
                    count: userStat.dynamicCount,
                    name: '动态',
                    countStyle: style,
                    labelStyle: labelStyle,
                    onTap: () => controller.push('memberDynamics'),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: theme.dividerColor.withValues(alpha: 0.08),
                  ),
                  _buildStatTile(
                    count: userStat.following,
                    name: '关注',
                    countStyle: style,
                    labelStyle: labelStyle,
                    onTap: () => controller.push('follow'),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: theme.dividerColor.withValues(alpha: 0.08),
                  ),
                  _buildStatTile(
                    count: userStat.follower,
                    name: '粉丝',
                    countStyle: style,
                    labelStyle: labelStyle,
                    onTap: () => controller.push('fan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatTile({
    required int? count,
    required String name,
    required TextStyle countStyle,
    required TextStyle? labelStyle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: TvFocusable(
        onTap: onTap,
        builder: (context, focused, hovered) {
          return TvFocusHighlight(
            focused: focused,
            radius: 20,
            borderWidth: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                spacing: 4,
                mainAxisSize: .min,
                mainAxisAlignment: .center,
                children: [
                  Text(count?.toString() ?? '-', style: countStyle),
                  Text(name, style: labelStyle),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _autoRefresh() => Future.delayed(
    const Duration(milliseconds: 150),
    () => controller.onRefresh(isManual: false),
  );

  Widget _buildFav(ThemeData theme, Color secondary) {
    return Column(
      children: [
        Divider(
          height: 20,
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 12),
          child: Row(
            children: [
              Expanded(
                child: TvFocusable(
                  onTap: () => Get.toNamed('/fav')?.whenComplete(_autoRefresh),
                  builder: (context, focused, hovered) => TvFocusHighlight(
                    focused: focused,
                    radius: 12,
                    borderWidth: 2,
                    child: ExcludeFocus(
                      child: ListTile(
                        dense: true,
                        title: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '我的收藏  ',
                                  style: TextStyle(
                                    fontSize:
                                        theme.textTheme.titleMedium!.fontSize,
                                    fontWeight: .bold,
                                  ),
                                ),
                                if (controller.favFolderCount != null)
                                  TextSpan(
                                    text: "${controller.favFolderCount}  ",
                                    style: TextStyle(
                                      fontSize:
                                          theme.textTheme.titleSmall!.fontSize,
                                      color: secondary,
                                    ),
                                  ),
                                WidgetSpan(
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              TvFocusButton(
                onTap: controller.onRefresh,
                radius: 12,
                child: IconButton(
                  tooltip: '刷新',
                  onPressed: controller.onRefresh,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ),
            ],
          ),
        ),
        _buildFavBody(theme, secondary, controller.loadingState.value),
      ],
    );
  }

  Widget _buildFavBody(
    ThemeData theme,
    Color secondary,
    LoadingState loadingState,
  ) {
    return switch (loadingState) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) => Builder(
        builder: (context) {
          List<FavFolderInfo>? favFolderList = response.list;
          if (favFolderList == null || favFolderList.isEmpty) {
            return const SizedBox.shrink();
          }
          bool flag = (controller.favFolderCount ?? 0) > favFolderList.length;
          return SizedBox(
            height: 224,
            child: ListView.separated(
              controller: controller.scrollController,
              padding: const .only(left: 20, top: 10, right: 20),
              itemCount: response.list.length + (flag ? 1 : 0),
              itemBuilder: (context, index) {
                if (flag && index == favFolderList.length) {
                  return Padding(
                    padding: const .only(bottom: 35),
                    child: Center(
                      child: TvFocusButton(
                        onTap: () =>
                            Get.toNamed('/fav')?.whenComplete(_autoRefresh),
                        radius: 20,
                        child: IconButton(
                          tooltip: '查看更多',
                          style: ButtonStyle(
                            padding: const WidgetStatePropertyAll(.zero),
                            backgroundColor: WidgetStatePropertyAll(
                              theme.colorScheme.secondaryContainer.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          onPressed: () =>
                              Get.toNamed('/fav')?.whenComplete(_autoRefresh),
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: secondary,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return FavFolderItem(
                    heroTag: 'mine-${response.list[index].id}',
                    item: response.list[index],
                    onPop: _autoRefresh,
                  );
                }
              },
              scrollDirection: .horizontal,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
            ),
          );
        },
      ),
      Error(:final errMsg) => SizedBox(
        height: 160,
        child: Center(
          child: Text(
            errMsg ?? '',
            textAlign: .center,
          ),
        ),
      ),
    };
  }
}
