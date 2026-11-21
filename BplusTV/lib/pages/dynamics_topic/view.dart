import 'package:bplus_tv/common/assets.dart';
import 'package:bplus_tv/common/widgets/custom_icon.dart';
import 'package:bplus_tv/common/widgets/dynamic_sliver_app_bar/dynamic_sliver_app_bar.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/pair.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/selection_text.dart';
import 'package:bplus_tv/common/widgets/sliver/sliver_pinned_header.dart';
import 'package:bplus_tv/common/widgets/sliver/sliver_constrained_cross_axis.dart';
import 'package:bplus_tv/http/constants.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/image_type.dart';
import 'package:bplus_tv/models_new/dynamic/dyn_topic_feed/fold_card_item.dart';
import 'package:bplus_tv/models_new/dynamic/dyn_topic_feed/item.dart';
import 'package:bplus_tv/models_new/dynamic/dyn_topic_top/top_details.dart';
import 'package:bplus_tv/pages/common/fab_mixin.dart';
import 'package:bplus_tv/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:bplus_tv/pages/dynamics/dyn_layout.dart';
import 'package:bplus_tv/pages/dynamics_create/view.dart';
import 'package:bplus_tv/pages/dynamics_topic/controller.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/extension/num_ext.dart';
import 'package:bplus_tv/utils/extension/theme_ext.dart';
import 'package:bplus_tv/utils/global_data.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/share_utils.dart';
import 'package:bplus_tv/utils/theme_utils.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:bplus_tv/utils/waterfall.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waterfall_flow/waterfall_flow.dart'
    hide SliverWaterfallFlowDelegateWithMaxCrossAxisExtent;

class DynTopicPage extends StatefulWidget {
  const DynTopicPage({super.key});

  @override
  State<DynTopicPage> createState() => _DynTopicPageState();
}

class _DynTopicPageState extends State<DynTopicPage>
    with DynMixin, SingleTickerProviderStateMixin, BaseFabMixin, FabMixin {
  late EdgeInsets padding;
  late ColorScheme colorScheme;
  final DynTopicController _controller = Get.put(
    DynTopicController(),
    tag: Utils.generateRandomString(8),
  );

  @override
  Widget buildPage(Widget child) => GlobalData().dynamicsWaterfallFlow
      ? child
      : CenteredSliverConstrainedCrossAxis(
          maxExtent: DynLayout.maxReadingWidth,
          sliver: child,
        );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorScheme = ColorScheme.of(context);
    padding = MediaQuery.viewPaddingOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      body: refreshIndicator(
        onRefresh: _controller.onRefresh,
        child: fabAnimWrapper(
          child: CustomScrollView(
            controller: _controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              Obx(
                () => _buildAppBar(
                  colorScheme,
                  padding,
                  _controller.topState.value,
                ),
              ),
              Obx(() {
                final allSortBy = _controller.topicSortByConf.value?.allSortBy;
                if (allSortBy != null && allSortBy.isNotEmpty) {
                  return SliverPinnedHeader(
                    backgroundColor: colorScheme.surface,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 12 + padding.left,
                        top: 6,
                        bottom: 6,
                      ),
                      child: Builder(
                        builder: (context) {
                          return ToggleButtons(
                            fillColor: colorScheme.secondaryContainer,
                            selectedColor: colorScheme.onSecondaryContainer,
                            constraints: const BoxConstraints(
                              minWidth: 88,
                              minHeight: 48,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            borderRadius: const .all(.circular(25)),
                            onPressed: (index) {
                              _controller.onSort(allSortBy[index].sortBy!);
                              (context as Element).markNeedsBuild();
                            },
                            isSelected: allSortBy
                                .map((e) => e.sortBy == _controller.sortBy)
                                .toList(),
                            children: allSortBy.map((e) {
                              return Text(
                                e.sortName!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.35,
                                ),
                                strutStyle: const StrutStyle(
                                  height: 1,
                                  leading: 0,
                                  fontSize: 16,
                                ),
                                textScaler: TextScaler.noScaling,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter();
              }),
              SliverPadding(
                padding: EdgeInsets.only(
                  left: padding.left,
                  right: padding.right,
                  bottom: padding.bottom + 100,
                ),
                sliver: buildPage(
                  Obx(() => _buildBody(_controller.loadingState.value)),
                ),
              ),
            ],
          ),
        ),
      ),
      fab: SlideTransition(
        position: fabAnimation,
        child: Padding(
          padding: .only(
            right: kFloatingActionButtonMargin + padding.right,
            bottom: kFloatingActionButtonMargin + padding.bottom,
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              if (_controller.isLogin) {
                CreateDynPanel.onCreateDyn(
                  context,
                  topic: Pair(
                    first: int.parse(_controller.topicId),
                    second: _controller.topicName,
                  ),
                );
              } else {
                SmartDialog.showToast('账号未登录');
              }
            },
            icon: const Icon(CustomIcons.topic_tag, size: 20),
            label: const Text('参与话题'),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    ColorScheme colorScheme,
    EdgeInsets padding,
    LoadingState<TopDetails?> topState,
  ) {
    return switch (topState) {
      Loading() => const SliverAppBar(),
      Success(:final response) when response != null => DynamicSliverAppBar.medium(
        onPerformLayout: (value) => _controller.appbarOffset =
            value.height - kToolbarHeight - padding.top,
        title: IgnorePointer(
          child: Text(
            response.topicItem!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: ResizeImage(
                width: MediaQuery.widthOf(context).cacheSize(context),
                const AssetImage(Assets.topicHeader),
              ),
              filterQuality: FilterQuality.low,
              fit: BoxFit.cover,
            ),
          ),
          padding: EdgeInsets.only(
            top: padding.top,
            left: 12 + padding.left,
            right: 12 + padding.right,
          ),
          child: DynPageContent(
            maxWidth: DynLayout.maxReadingWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: kToolbarHeight,
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(left: 45, right: 78),
                  child: DynFocusAction(
                    onTap: () => Get.toNamed(
                      '/member?mid=${response.topicCreator!.uid}',
                    ),
                    child: Row(
                      spacing: 10,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NetworkImgLayer(
                          width: 36,
                          height: 36,
                          src: response.topicCreator!.face!,
                          type: ImageType.avatar,
                        ),
                        Flexible(
                          child: Text(
                            response.topicCreator!.name!,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ' 发起',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  response.topicItem!.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SelectionText(
                  response.topicItem!.description!,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${NumUtils.numFormat(response.topicItem!.view)}浏览 · ${NumUtils.numFormat(response.topicItem!.discuss)}讨论',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(72, 48),
                        side: BorderSide(
                          width: 1,
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        foregroundColor: _controller.isLike.value
                            ? null
                            : colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.standard,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _controller.onLike,
                      icon: _controller.isLike.value
                          ? const Icon(FontAwesomeIcons.solidThumbsUp, size: 18)
                          : const Icon(FontAwesomeIcons.thumbsUp, size: 18),
                      label: Text(
                        NumUtils.numFormat(response.topicItem!.like),
                        style: const TextStyle(fontSize: 16),
                        textScaler: TextScaler.noScaling,
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(72, 48),
                        side: BorderSide(
                          width: 1,
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        foregroundColor: _controller.isFav.value
                            ? null
                            : colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.standard,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _controller.onFav,
                      icon: _controller.isFav.value
                          ? const Icon(FontAwesomeIcons.solidStar, size: 18)
                          : const Icon(FontAwesomeIcons.star, size: 18),
                      label: Text(
                        NumUtils.numFormat(response.topicItem!.fav),
                        style: const TextStyle(fontSize: 16),
                        textScaler: TextScaler.noScaling,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ShareUtils.shareText(
              '${_controller.topicName} https://m.bilibili.com/topic-detail?topic_id=${_controller.topicId}',
            ),
            // https://www.bilibili.com/v/topic/detail?topic_id=${_controller.topicId}
            icon: const Icon(MdiIcons.share),
          ),
          TvFocusable(
            onTap: _showTvMoreMenu,
            builder: (context, focused, hovered) => TvFocusHighlight(
              focused: focused,
              radius: 16,
              borderWidth: 2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: focused
                      ? Theme.of(context).colorScheme.secondaryContainer
                            .withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: const Icon(Icons.more_vert),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      _ => SliverAppBar(
        pinned: true,
        title: Text(_controller.topicName),
      ),
    };
  }

  void _showTvMoreMenu() {
    showDialog(
      context: context,
      builder: (dialogContext) => tvDialogShell(
        title: '更多',
        minWidth: 420,
        content: const SizedBox.shrink(),
        actions: [
          TvDialogAction(
            label: '${_controller.isFav.value ? '取消' : ''}收藏',
            autofocus: true,
            onTap: () {
              Get.back();
              _controller.onFav();
            },
          ),
          TvDialogAction(
            label: '举报',
            onTap: () {
              Get.back();
              if (!_controller.isLogin) {
                SmartDialog.showToast('账号未登录');
                return;
              }
              PageUtils.inAppWebview(
                '${HttpString.baseUrl}/h5/topic-active/topic-report?topic_id=${_controller.topicId}&topic_name=${_controller.topicName}&${ThemeUtils.themeUrl(colorScheme.isDark)}',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<TopicCardItem>?> loadingState) {
    return switch (loadingState) {
      Loading() => dynSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? GlobalData().dynamicsWaterfallFlow
                  ? SliverLayoutBuilder(
                      builder: (context, constraints) => SliverWaterfallFlow(
                        gridDelegate:
                            SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  (constraints.crossAxisExtent / 560)
                                      .floor()
                                      .clamp(1, 3)
                                      .toInt(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => _itemBuilder(response, index),
                          childCount: response.length,
                        ),
                      ),
                    )
                  : SliverList.builder(
                      itemBuilder: (context, index) =>
                          _itemBuilder(response, index),
                      itemCount: response.length,
                    )
            : HttpError(onReload: _controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  Widget _itemBuilder(List<TopicCardItem> list, int index) {
    if (index == list.length - 1) {
      _controller.onLoadMore();
    }

    final item = list[index];

    if (item.dynamicCardItem case final dynamicCardItem?) {
      return DynamicPanel(item: dynamicCardItem);
    }

    if (item.foldCardItem case final foldCardItem?) {
      return _buildFoldItem(foldCardItem);
    }

    return Text(item.topicType ?? 'err');
  }

  Widget _buildFoldItem(FoldCardItem item) {
    return Padding(
      padding: const .only(top: 12),
      child: Material(
        color: colorScheme.outline.withValues(alpha: .05),
        child: InkWell(
          onTap: _controller.topicFold,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const .symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: .min,
              mainAxisAlignment: .center,
              children: [
                Flexible(
                  child: Text(
                    item.foldDesc!,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_right, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
