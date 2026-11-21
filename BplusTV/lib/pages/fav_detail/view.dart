import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/flutter/pop_scope.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/http/fav.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/fav_order_type.dart';
import 'package:bplus_tv/models_new/fav/fav_detail/media.dart';
import 'package:bplus_tv/models_new/fav/fav_folder/list.dart';
import 'package:bplus_tv/pages/dynamics_repost/view.dart';
import 'package:bplus_tv/pages/fav_detail/controller.dart';
import 'package:bplus_tv/pages/fav_detail/widget/fav_video_card.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_option_picker.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/bili_utils.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:bplus_tv/utils/request_utils.dart';
import 'package:bplus_tv/utils/share_utils.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class FavDetailPage extends StatefulWidget {
  const FavDetailPage({super.key});

  @override
  State<FavDetailPage> createState() => _FavDetailPageState();
}

class _FavDetailPageState extends State<FavDetailPage> with GridMixin {
  @override
  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 840,
    mainAxisExtent: 140,
    mainAxisSpacing: 10,
    crossAxisSpacing: 14,
  );

  late final FavDetailController _favDetailController;
  late String mediaId;

  @override
  void initState() {
    super.initState();
    mediaId = Get.parameters['mediaId']!;
    _favDetailController = Get.put(
      FavDetailController(),
      tag: Utils.makeHeroTag(mediaId),
    );
  }

  late EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    padding = MediaQuery.viewPaddingOf(context);
    return Obx(
      () {
        final enableMultiSelect = _favDetailController.enableMultiSelect.value;
        final page = popScope(
          canPop: !enableMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (enableMultiSelect) {
              _favDetailController.handleSelect();
            }
          },
          child: SimpleScaffold(
            body: refreshIndicator(
              onRefresh: _favDetailController.onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _favDetailController.scrollController,
                slivers: [
                  _buildHeader(enableMultiSelect, theme),
                  SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalInset =
                          ((constraints.crossAxisExtent -
                                      padding.horizontal -
                                      1600) /
                                  2)
                              .clamp(0.0, double.infinity)
                              .toDouble();
                      return SliverPadding(
                        padding: EdgeInsets.only(
                          left: padding.left + horizontalInset + 8,
                          right: padding.right + horizontalInset + 8,
                          top: 8,
                          bottom: padding.bottom + 48,
                        ),
                        sliver: Obx(
                          () => _buildBody(
                            enableMultiSelect,
                            theme,
                            _favDetailController.loadingState.value,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        return TvPageFocus(child: page);
      },
    );
  }

  Widget _buildHeader(bool enableMultiSelect, ThemeData theme) {
    return SliverAppBar.medium(
      leadingWidth: enableMultiSelect ? 125 : null,
      leading: enableMultiSelect
          ? Row(
              mainAxisSize: .min,
              children: [
                IconButton(
                  tooltip: '取消',
                  onPressed: _favDetailController.handleSelect,
                  icon: const Icon(Icons.close_outlined),
                ),
                Obx(
                  () {
                    return Text(
                      '已选: ${_favDetailController.checkedCount}',
                      style: const TextStyle(fontSize: 15),
                    );
                  },
                ),
              ],
            )
          : null,
      expandedHeight: kToolbarHeight + 127,
      pinned: true,
      title: enableMultiSelect
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _favDetailController.folderInfo.value.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '共${_favDetailController.folderInfo.value.mediaCount}条视频',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
      actions: enableMultiSelect ? _selectActions(theme) : _actions(theme),
      flexibleSpace: _flexibleSpace(theme),
    );
  }

  List<Widget> _actions(ThemeData theme) {
    return [
      TextButton.icon(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: _favDetailController.folderInfo.value.mediaCount > 0
            ? _favDetailController.toViewPlayAll
            : null,
        icon: const Icon(Icons.playlist_play),
        label: const Text('播放全部'),
      ),
      IconButton(
        tooltip: '搜索',
        onPressed: () {
          final folderInfo = _favDetailController.folderInfo.value;
          Get.toNamed(
            '/favSearch',
            arguments: {
              'type': 0,
              'mediaId': int.parse(mediaId),
              'title': folderInfo.title,
              'count': folderInfo.mediaCount,
              'isOwner': _favDetailController.isOwner,
            },
          );
        },
        icon: const Icon(Icons.search_outlined),
      ),
      Obx(() {
        final attr = _favDetailController.folderInfo.value.attr;
        return attr == -1 || !BiliUtils.isPublicFav(attr)
            ? const SizedBox.shrink()
            : IconButton(
                iconSize: 22,
                tooltip: '分享',
                onPressed: () => ShareUtils.shareText(
                  'https://www.bilibili.com/medialist/detail/ml${_favDetailController.mediaId}',
                ),
                icon: const Icon(Icons.share),
              );
      }),
      Builder(
        builder: (context) {
          final orderIcon = _favDetailController.pageDesc
              ? const Icon(MdiIcons.sortNumericDescending)
              : const Icon(MdiIcons.sortNumericAscending);
          {
            return TvFocusable(
              onTap: () => _showTvPageOrder(context),
              builder: (context, focused, hovered) => TvFocusHighlight(
                focused: focused,
                radius: 16,
                borderWidth: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: focused
                        ? Theme.of(context).colorScheme.secondaryContainer
                              .withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: orderIcon,
                ),
              ),
            );
          }
        },
      ),
      TvFocusable(
        onTap: _showTvSortMenu,
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 16,
          borderWidth: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: focused
                  ? Theme.of(context).colorScheme.secondaryContainer
                        .withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: const Icon(Icons.sort),
          ),
        ),
      ),
      if (_favDetailController.account.isLogin)
        TvFocusable(
          onTap: _showTvMoreMenu,
          builder: (context, focused, hovered) => TvFocusHighlight(
            focused: focused,
            radius: 16,
            borderWidth: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
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
      const SizedBox(width: 10),
    ];
  }

  void _showTvPageOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => tvDialogShell(
        title: '页码顺序',
        content: const SizedBox.shrink(),
        actions: [
          TvDialogAction(
            label: '正序',
            autofocus: true,
            onTap: () {
              Get.back();
              _favDetailController.updatePageOrder(false);
              if (context.mounted) {
                (context as Element).markNeedsBuild();
              }
            },
          ),
          TvDialogAction(
            label: '倒序',
            onTap: () {
              Get.back();
              _favDetailController.updatePageOrder(true);
              if (context.mounted) {
                (context as Element).markNeedsBuild();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showTvSortMenu() async {
    final order = await showTvOptionPicker<FavOrderType>(
      context: context,
      title: '排序方式',
      current: _favDetailController.order.value,
      options: FavOrderType.values
          .map((e) => TvOption(value: e, label: e.label))
          .toList(),
    );
    if (order == null || order == _favDetailController.order.value) return;
    _favDetailController
      ..order.value = order
      ..onReload();
  }

  void _showTvMoreMenu() {
    final isOwner = _favDetailController.isOwner;
    final folderInfo = _favDetailController.folderInfo.value;
    showDialog(
      context: context,
      builder: (dialogContext) => tvDialogShell(
        title: '更多',
        minWidth: 420,
        content: const SizedBox.shrink(),
        actions: [
          if (isOwner) ...[
            TvDialogAction(
              label: '排序',
              onTap: () {
                Get.back();
                _favDetailController.onSort();
              },
            ),
            TvDialogAction(
              label: '编辑信息',
              onTap: () {
                Get.back();
                Get.toNamed(
                  '/createFav',
                  parameters: {'mediaId': mediaId},
                )?.then((res) {
                  if (res is FavFolderInfo) {
                    _favDetailController.folderInfo.value = res;
                  }
                });
              },
            ),
          ] else
            TvDialogAction(
              label: '${folderInfo.favState == 1 ? '取消' : ''}收藏',
              onTap: () {
                Get.back();
                _favDetailController.onFav(folderInfo.favState == 1);
              },
            ),
          if (BiliUtils.isPublicFav(folderInfo.attr))
            TvDialogAction(
              label: '分享至动态',
              onTap: () {
                Get.back();
                _onShareToDyn();
              },
            ),
          if (isOwner) ...[
            TvDialogAction(
              label: '清除失效内容',
              onTap: () {
                Get.back();
                _favDetailController.cleanFav();
              },
            ),
            if (!BiliUtils.isDefaultFav(folderInfo.attr))
              TvDialogAction(
                label: '删除',
                onTap: () {
                  Get.back();
                  showTvConfirm(
                    context: context,
                    title: '删除收藏夹',
                    message: '确定删除该收藏夹?',
                    confirmLabel: '删除',
                    destructive: true,
                  ).then((ok) {
                    if (ok == true) {
                      FavHttp.deleteFolder(mediaIds: mediaId).then((res) {
                        if (res.isSuccess) {
                          SmartDialog.showToast('删除成功');
                          Get.back(result: true);
                        } else {
                          res.toast();
                        }
                      });
                    }
                  });
                },
              ),
          ],
        ],
      ),
    );
  }

  void _onShareToDyn() {
    final folderInfo = _favDetailController.folderInfo.value;
    {
      showDialog(
        context: context,
        builder: (context) => tvDialogShell(
          title: '分享至动态',
          minWidth: 480,
          content: RepostPanel(
            rid: _favDetailController.mediaId,
            dynType: 4300,
            pic: folderInfo.cover,
            title: folderInfo.title,
            uname: folderInfo.upper?.name,
          ),
          actions: [
            TvDialogAction(
              label: '关闭',
              onTap: Get.back,
            ),
          ],
        ),
      );
      return;
    }
  }

  List<Widget> _selectActions(ThemeData theme) {
    final btnStyle = TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      visualDensity: VisualDensity.standard,
    );
    final textStyle = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    return [
      TextButton(
        style: btnStyle,
        onPressed: () => _favDetailController.handleSelect(checked: true),
        child: const Text('全选'),
      ),
      TextButton(
        style: btnStyle,
        onPressed: () => RequestUtils.onCopyOrMove<FavDetailItemModel>(
          context: context,
          isCopy: true,
          ctr: _favDetailController,
          mediaId: _favDetailController.mediaId,
          mid: _favDetailController.account.mid,
        ),
        child: Text('复制', style: textStyle),
      ),
      TextButton(
        style: btnStyle,
        onPressed: () => RequestUtils.onCopyOrMove<FavDetailItemModel>(
          context: context,
          isCopy: false,
          ctr: _favDetailController,
          mediaId: _favDetailController.mediaId,
          mid: _favDetailController.account.mid,
        ),
        child: Text('移动', style: textStyle),
      ),
      TextButton(
        style: btnStyle,
        onPressed: _favDetailController.onRemove,
        child: Text(
          '删除',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
      const SizedBox(width: 10),
    ];
  }

  Widget _flexibleSpace(ThemeData theme) {
    final style = TextStyle(
      height: 1,
      fontSize: 12.5,
      color: theme.colorScheme.outline,
    );
    return FlexibleSpaceBar(
      background: Padding(
        padding: EdgeInsets.only(
          top: kToolbarHeight + padding.top + 10,
          left: 12 + padding.left,
          right: 12 + padding.right,
          bottom: 7,
        ),
        child: SizedBox(
          height: 110,
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1576),
              child: Obx(
                () {
                  final folderInfo = _favDetailController.folderInfo.value;
                  final row = Row(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Hero(
                            tag: _favDetailController.heroTag,
                            child: NetworkImgLayer(
                              width: 176,
                              height: 110,
                              src: folderInfo.cover,
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Obx(() {
                              if (_favDetailController.isOwner ||
                                  _favDetailController.loadingState.value
                                      is! Success) {
                                return const SizedBox.shrink();
                              }
                              bool isFav = folderInfo.favState == 1;
                              return iconButton(
                                size: 48,
                                iconSize: 18,
                                tooltip: '${isFav ? '取消' : ''}收藏',
                                onPressed: () =>
                                    _favDetailController.onFav(isFav),
                                icon: isFav
                                    ? const Icon(Icons.favorite)
                                    : const Icon(Icons.favorite_border),
                                bgColor: isFav
                                    ? theme.colorScheme.secondaryContainer
                                    : theme.colorScheme.onInverseSurface,
                                iconColor: isFav
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              );
                            }),
                          ),
                        ],
                      ),
                      if (folderInfo.title.isNotEmpty)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (folderInfo.upper != null &&
                                  folderInfo.upper!.name != null)
                                TvFocusable(
                                  onTap: () => Get.toNamed(
                                    '/member?mid=${folderInfo.upper!.mid}',
                                  ),
                                  builder: (context, focused, hovered) =>
                                      TvFocusHighlight(
                                        focused: focused,
                                        radius: 8,
                                        borderWidth: 2,
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minHeight: 48,
                                            minWidth: 48,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            folderInfo.upper!.name!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                ),
                              const SizedBox(height: 4),
                              if (folderInfo.intro?.isNotEmpty == true) ...[
                                Flexible(
                                  child: Text(
                                    folderInfo.intro!,
                                    style: style,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                '共${folderInfo.mediaCount}条视频 · '
                                '${BiliUtils.isPublicFavText(folderInfo.attr)}',
                                style: style,
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                  return netflixSurface(radius: 18, child: row);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    bool enableMultiSelect,
    ThemeData theme,
    LoadingState<List<FavDetailItemModel>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length) {
                    _favDetailController.onLoadMore();
                    return Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Text(
                        _favDetailController.isEnd ? '没有更多了' : '加载中...',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  FavDetailItemModel item = response[index];
                  return FavVideoCardH(
                    item: item,
                    index: index,
                    ctr: _favDetailController,
                  );
                },
                itemCount: response.length + 1,
              )
            : HttpError(onReload: _favDetailController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _favDetailController.onReload,
      ),
    };
  }
}
