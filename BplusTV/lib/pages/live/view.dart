import 'package:bplus_tv/common/skeleton/video_card_v.dart';
import 'package:bplus_tv/common/sliver_single_child_delegate.dart';
import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/button/more_btn.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/pair.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/live/live_feed_index/card_data_list_item.dart';
import 'package:bplus_tv/models_new/live/live_feed_index/card_list.dart';
import 'package:bplus_tv/pages/live/controller.dart';
import 'package:bplus_tv/pages/live/widgets/live_item_app.dart';
import 'package:bplus_tv/pages/live/widgets/live_tv_filter.dart';
import 'package:bplus_tv/pages/live/widgets/live_tv_grid.dart';
import 'package:bplus_tv/pages/live_area/view.dart';
import 'package:bplus_tv/pages/live_follow/view.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/extension/theme_ext.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/theme_utils.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage>
    with AutomaticKeepAliveClientMixin {
  final LiveController controller = Get.put(LiveController());

  @override
  bool get wantKeepAlive => true;

  late TextScaler textScaler;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    textScaler = MediaQuery.textScalerOf(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);
    final homeTopInset = TvScrollInset.maybeOf(context);
    return Container(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(borderRadius: Style.mdRadius),
      child: refreshIndicator(
        onRefresh: controller.onRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                top: homeTopInset ?? 66,
                bottom: 100,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  Obx(() => _buildTop(theme, controller.topState.value)),
                  Obx(() => _buildBody(theme, controller.loadingState.value)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTop(ThemeData theme, Pair<LiveCardList?, LiveCardList?> data) {
    return SliverMainAxisGroup(
      slivers: [
        if (data.first != null) ..._buildFollowList(theme, data.first!),
        if (data.second?.cardData?.areaEntranceV3?.list case final list?)
          if (list.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const .only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: Obx(() {
                          final areaIndex = controller.areaIndex.value;
                          return ListView.separated(
                            scrollDirection: .horizontal,
                            padding: const .only(right: 8),
                            physics: const AlwaysScrollableScrollPhysics(),
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final isFirst = index == 0;
                              late final item = list[index - 1];
                              final isCurr = index == areaIndex;
                              return LiveTvFilter(
                                label: isFirst ? '推荐' : item.title!,
                                selected: isCurr,
                                onTap: () => controller.onSelectArea(
                                  index,
                                  isFirst ? null : item,
                                ),
                              );
                            },
                            itemCount: list.length + 1,
                          );
                        }),
                      ),
                    ),
                    iconButton(
                      size: 48,
                      iconSize: 18,
                      context: context,
                      tooltip: '切换${controller.showFirstFrame ? '封面' : '首帧'}',
                      icon: controller.showFirstFrame
                          ? const Icon(MdiIcons.alphaFBox)
                          : const Icon(MdiIcons.image),
                      onPressed: () {
                        controller.showFirstFrame = !controller.showFirstFrame;
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    iconButton(
                      size: 48,
                      iconSize: 16,
                      context: context,
                      tooltip: '游戏赛事',
                      icon: const Icon(Icons.gamepad),
                      onPressed: () => Get.toNamed(
                        '/webview',
                        parameters: {
                          'uaType': 'mob',
                          'url':
                              'https://www.bilibili.com/h5/match/data/home?navhide=1&${ThemeUtils.themeUrl(theme.isDark)}',
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    iconButton(
                      size: 48,
                      iconSize: 16,
                      context: context,
                      tooltip: '全部标签',
                      icon: const Icon(Icons.widgets),
                      onPressed: () => Get.to(const LiveAreaPage()),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  LiveTvGridDelegate get gridDelegate => LiveTvGridDelegate(
    infoHeight: textScaler.scale(96),
  );

  Widget _buildBody(ThemeData theme, LoadingState<List?> loadingState) {
    return switch (loadingState) {
      Loading() => SliverGrid(
        gridDelegate: gridDelegate,
        delegate: const SliverSingleChildDelegate(
          child: VideoCardVSkeleton(),
          count: 10,
        ),
      ),
      Success(:final response) => SliverMainAxisGroup(
        slivers: [
          if (controller.newTags case final newTags?)
            if (newTags.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: Obx(() {
                    final tagIndex = controller.tagIndex.value;
                    return ListView.separated(
                      scrollDirection: .horizontal,
                      padding: const .only(bottom: 8),
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = newTags[index];
                        final isCurr = index == tagIndex;
                        return LiveTvFilter(
                          label: item.name!,
                          selected: isCurr,
                          onTap: () =>
                              controller.onSelectTag(index, item.sortType),
                        );
                      },
                      itemCount: newTags.length,
                    );
                  }),
                ),
              ),
          response != null && response.isNotEmpty
              ? SliverGrid.builder(
                  gridDelegate: gridDelegate,
                  itemBuilder: (context, index) {
                    if (index == response.length - 1) {
                      controller.onLoadMore();
                    }
                    final item = response[index];
                    if (item is LiveCardList) {
                      final smallCard = item.cardData?.smallCardV1;
                      if (smallCard == null) {
                        return const SizedBox.shrink();
                      }
                      return LiveCardVApp(
                        item: smallCard,
                        showFirstFrame: controller.showFirstFrame,
                      );
                    }
                    return LiveCardVApp(
                      item: item,
                      showFirstFrame: controller.showFirstFrame,
                    );
                  },
                  itemCount: response.length,
                )
              : HttpError(onReload: controller.onReload),
        ],
      ),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  List<Widget> _buildFollowList(ThemeData theme, LiveCardList item) {
    final totalCount = item.cardData?.myIdolV1?.extraInfo?.totalCount ?? 0;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const .only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  overflow: TextOverflow.ellipsis,
                  TextSpan(
                    children: [
                      const TextSpan(text: '我的关注  '),
                      TextSpan(
                        text: totalCount.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: '人正在直播',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              moreTextButton(
                onTap: () => Get.to(const LiveFollowPage()),
                color: theme.colorScheme.outline,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      if (item.cardData?.myIdolV1?.list case final list?)
        if (list.isNotEmpty) _buildFollowBody(theme, list, totalCount),
    ];
  }

  Widget _buildFollowBody(
    ThemeData theme,
    List<CardLiveItem> followList,
    int totalCount,
  ) {
    final listLength = followList.length;
    return SliverToBoxAdapter(
      child: SizedBox(
        // 3+4+45+6+10+12*textScaler
        height: 68.0 + textScaler.scale(12),
        child: CustomScrollView(
          scrollDirection: Axis.horizontal,
          controller: controller.followController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFixedExtentList.builder(
              itemExtent: 70,
              itemCount: totalCount > listLength ? listLength + 1 : listLength,
              itemBuilder: (context, index) {
                if (index == listLength) {
                  return Align(
                    alignment: const Alignment(0, -0.3),
                    child: TvFocusable(
                      onTap: () => Get.to(const LiveFollowPage()),
                      builder: (context, focused, hovered) => TvFocusHighlight(
                        radius: 20,
                        focused: focused,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: .circle,
                            color: theme.colorScheme.onInverseSurface,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_right,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                final item = followList[index];
                return Padding(
                  padding: const .only(right: 5),
                  child: SizedBox(
                    width: 65,
                    child: TvFocusable(
                      onTap: () => PageUtils.toLiveRoom(item.roomid),
                      onLongPress: () {
                        Feedback.forLongPress(context);
                        Get.toNamed('/member?mid=${item.uid}');
                      },
                      builder: (context, focused, hovered) => TvFocusHighlight(
                        radius: 12,
                        focused: focused,
                        child: Column(
                          mainAxisSize: .min,
                          children: [
                            Container(
                              padding: const .all(2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 1.5,
                                  color: theme.colorScheme.primary,
                                  strokeAlign: BorderSide.strokeAlignInside,
                                ),
                                shape: .circle,
                              ),
                              child: NetworkImgLayer(
                                type: .avatar,
                                width: 45,
                                height: 45,
                                src: item.face,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.uname!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
