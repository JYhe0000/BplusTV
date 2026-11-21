import 'dart:math';

import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/button/more_btn.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/fav_type.dart';
import 'package:bplus_tv/models/common/home_tab_type.dart';
import 'package:bplus_tv/models_new/fav/fav_pgc/list.dart';
import 'package:bplus_tv/models_new/pgc/pgc_index_result/list.dart';
import 'package:bplus_tv/models_new/pgc/pgc_timeline/result.dart';
import 'package:bplus_tv/pages/pgc/controller.dart';
import 'package:bplus_tv/pages/pgc/widgets/pgc_card_v.dart';
import 'package:bplus_tv/pages/pgc/widgets/pgc_card_v_timeline.dart';
import 'package:bplus_tv/pages/pgc_index/controller.dart';
import 'package:bplus_tv/pages/pgc_index/view.dart';
import 'package:bplus_tv/pages/pgc_index/widgets/pgc_card_v_pgc_index.dart';
import 'package:bplus_tv/utils/extension/iterable_ext.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class PgcPage extends StatefulWidget {
  const PgcPage({
    super.key,
    required this.tabType,
  });

  final HomeTabType tabType;

  @override
  State<PgcPage> createState() => _PgcPageState();
}

class _PgcPageState extends State<PgcPage> with AutomaticKeepAliveClientMixin {
  late final PgcController controller;
  int _selectedTimelineIndex = -1;

  @override
  void initState() {
    controller = Get.put(
      PgcController(tabType: widget.tabType),
      tag: widget.tabType.name,
    );
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);
    final homeTopInset = TvScrollInset.maybeOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: refreshIndicator(
        onRefresh: controller.onRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(top: homeTopInset ?? 66),
              sliver: SliverMainAxisGroup(
                slivers: [
                  _buildFollow(theme),
                  if (controller.showPgcTimeline)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height:
                            Grid.smallCardWidth / 2 / 0.75 +
                            MediaQuery.textScalerOf(context).scale(96),
                        child: Obx(
                          () => _buildTimeline(
                            theme,
                            controller.timelineState.value,
                          ),
                        ),
                      ),
                    ),
                  ..._buildRcmd(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(
    ThemeData theme,
    LoadingState<List<TimelineResult>?> loadingState,
  ) => switch (loadingState) {
    Loading() => m3eLoading,
    Success(:final response) =>
      response != null && response.isNotEmpty
          ? Builder(
              builder: (context) {
                if (_selectedTimelineIndex < 0 ||
                    _selectedTimelineIndex >= response.length) {
                  _selectedTimelineIndex = max(
                    0,
                    response.indexWhere((item) => item.isToday == 1),
                  );
                }
                final selectedIndex = _selectedTimelineIndex;
                final selectedItem = response[selectedIndex];
                return Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        Text(
                          '追番时间表',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: response.length,
                              padding: const EdgeInsets.only(right: 10),
                              itemBuilder: (context, index) {
                                final item = response[index];
                                final isSelected = index == selectedIndex;
                                final label =
                                    '${item.date} ${item.isToday == 1 ? '今天' : '周${const ['一', '二', '三', '四', '五', '六', '日'][(item.dayOfWeek ?? 1).clamp(1, 7) - 1]}'}';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: TvFocusable(
                                    autofocus: index == selectedIndex,
                                    onTap: () {
                                      setState(() {
                                        _selectedTimelineIndex = index;
                                      });
                                    },
                                    builder: (context, focused, hovered) {
                                      return TvFocusHighlight(
                                        radius: 20,
                                        focused: focused,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? theme
                                                      .colorScheme
                                                      .secondaryContainer
                                                : null,
                                            borderRadius:
                                                const BorderRadius.all(
                                                  Radius.circular(20),
                                                ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isSelected
                                                  ? theme
                                                        .colorScheme
                                                        .onSecondaryContainer
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: selectedItem.episodes.isNullOrEmpty
                          ? const SizedBox.shrink()
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedItem.episodes!.length,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: Grid.smallCardWidth / 2,
                                  margin: EdgeInsets.only(
                                    left: Style.safeSpace,
                                    right:
                                        index ==
                                            selectedItem.episodes!.length - 1
                                        ? Style.safeSpace
                                        : 0,
                                  ),
                                  child: PgcCardVTimeline(
                                    item: selectedItem.episodes![index],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            )
          : const SizedBox.shrink(),
    Error(:final errMsg) => TvFocusable(
      onTap: controller.queryPgcTimeline,
      builder: (context, focused, hovered) => TvFocusHighlight(
        radius: 8,
        focused: focused,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            errMsg ?? '',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  };

  List<Widget> _buildRcmd(ThemeData theme) => [
    _buildRcmdTitle(theme),
    SliverPadding(
      padding: const EdgeInsets.only(
        left: Style.safeSpace,
        right: Style.safeSpace,
        bottom: 100,
      ),
      sliver: Obx(
        () => _buildRcmdBody(controller.loadingState.value),
      ),
    ),
  ];

  Widget _buildRcmdTitle(ThemeData theme) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 10,
        left: 16,
        right: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '推荐',
            style: theme.textTheme.titleMedium,
          ),
          moreTextButton(
            padding: const EdgeInsets.symmetric(vertical: 2),
            onTap: () {
              if (widget.tabType == HomeTabType.bangumi) {
                Get.to(const PgcIndexPage());
              } else {
                List<String> titles = const [
                  '全部',
                  '电影',
                  '电视剧',
                  '纪录片',
                  '综艺',
                ];
                List<int> types = const [102, 2, 5, 3, 7];
                Get.to(
                  SimpleScaffold(
                    appBar: AppBar(title: const Text('索引')),
                    body: DefaultTabController(
                      length: types.length,
                      child: Builder(
                        builder: (context) {
                          return Column(
                            children: [
                              ViewSafeArea(
                                child: TabBar(
                                  tabs: titles
                                      .map((title) => Tab(text: title))
                                      .toList(),
                                  onTap: (index) {
                                    try {
                                      if (!DefaultTabController.of(
                                        context,
                                      ).indexIsChanging) {
                                        Get.find<PgcIndexController>(
                                          tag: types[index].toString(),
                                        ).animateToTop();
                                      }
                                    } catch (_) {}
                                  },
                                ),
                              ),
                              Expanded(
                                child: tabBarView(
                                  children: types
                                      .map(
                                        (type) => PgcIndexPage(indexType: type),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
            },
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    ),
  );

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: Style.cardSpace,
    crossAxisSpacing: Style.cardSpace,
    maxCrossAxisExtent: Grid.smallCardWidth * 0.6,
    childAspectRatio: 0.75,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(50),
  );

  Widget _buildRcmdBody(LoadingState<List<PgcIndexItem>?> loadingState) {
    return switch (loadingState) {
      Loading() => const SliverToBoxAdapter(),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  return PgcCardVPgcIndex(item: response[index]);
                },
                itemCount: response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _buildFollow(ThemeData theme) => SliverToBoxAdapter(
    child: Obx(
      () => controller.accountService.isLogin.value
          ? Column(
              children: [
                _buildFollowTitle(theme),
                SizedBox(
                  height:
                      Grid.smallCardWidth / 2 / 0.75 +
                      MediaQuery.textScalerOf(context).scale(50),
                  child: Obx(
                    () => _buildFollowBody(controller.followState.value),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    ),
  );

  Widget _buildFollowTitle(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Row(
      children: [
        Obx(
          () => Text(
            '最近${widget.tabType == HomeTabType.bangumi ? '追番' : '追剧'}${controller.followCount.value == -1 ? '' : ' ${controller.followCount.value}'}',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const Spacer(),
        TvFocusable(
          onTap: () => controller
            ..followPage = 1
            ..followEnd = false
            ..queryPgcFollow(),
          builder: (context, focused, hovered) => TvFocusHighlight(
            radius: 20,
            focused: focused,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.refresh,
                size: 20,
                color: focused ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ),
        Obx(
          () => controller.accountService.isLogin.value
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: moreTextButton(
                    text: '查看全部',
                    onTap: () => Get.toNamed(
                      '/fav',
                      arguments: widget.tabType == HomeTabType.bangumi
                          ? FavTabType.bangumi.index
                          : FavTabType.cinema.index,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: theme.colorScheme.secondary,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );

  Widget _buildFollowBody(LoadingState<List<FavPgcItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => m3eLoading,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? ListView.builder(
                controller: controller.followController,
                scrollDirection: Axis.horizontal,
                itemCount: response.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.queryPgcFollow(false);
                  }
                  return Container(
                    width: Grid.smallCardWidth / 2,
                    margin: EdgeInsets.only(
                      left: Style.safeSpace,
                      right: index == response.length - 1 ? Style.safeSpace : 0,
                    ),
                    child: PgcCardV(item: response[index]),
                  );
                },
              )
            : Center(
                child: Text(
                  '还没有${widget.tabType == HomeTabType.bangumi ? '追番' : '追剧'}',
                ),
              ),
      Error(:final errMsg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          errMsg ?? '',
          textAlign: TextAlign.center,
        ),
      ),
    };
  }
}
