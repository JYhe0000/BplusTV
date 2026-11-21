import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart'
    show m3eLoading;
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/fav/fav_topic/topic_item.dart';
import 'package:bplus_tv/pages/fav/topic/controller.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/grid.dart';

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class FavTopicPage extends StatefulWidget {
  const FavTopicPage({super.key});

  @override
  State<FavTopicPage> createState() => _FavTopicPageState();
}

class _FavTopicPageState extends State<FavTopicPage>
    with AutomaticKeepAliveClientMixin {
  final FavTopicController _controller = Get.put(FavTopicController());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);
    return refreshIndicator(
      onRefresh: _controller.onRefresh,
      child: CustomScrollView(
        controller: _controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final inset =
                  ((constraints.crossAxisExtent - 1600) / 2)
                      .clamp(0.0, double.infinity)
                      .toDouble() +
                  Style.safeSpace;
              return SliverPadding(
                padding: EdgeInsets.only(
                  left: inset,
                  right: inset,
                  top: 8,
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 48,
                ),
                sliver: Obx(
                  () => _buildBody(theme, _controller.loadingState.value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    mainAxisSpacing: 10,
    crossAxisSpacing: 14,
    maxCrossAxisExtent: 420,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(48),
  );

  Widget _buildBody(
    ThemeData theme,
    LoadingState<List<FavTopicItem>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => const SliverToBoxAdapter(
        child: SizedBox(
          height: 125,
          child: m3eLoading,
        ),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _controller.onLoadMore();
                  }
                  final item = response[index];

                  void onTap() => Get.toNamed(
                    '/dynTopic',
                    parameters: {
                      'id': item.id!.toString(),
                      'name': item.name!,
                    },
                  );
                  void onLongPress() {
                    showTvConfirm(
                      context: context,
                      title: '取消收藏',
                      message: '确定取消收藏？',
                      confirmLabel: '取消收藏',
                      destructive: true,
                    ).then((ok) {
                      if (ok == true) _controller.onRemove(index, item.id!);
                    });
                  }

                  final label = Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    child: Text(
                      '# ${item.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );

                  return TvFocusable(
                    onTap: onTap,
                    onLongPress: onLongPress,
                    builder: (context, focused, hovered) => TvFocusHighlight(
                      focused: focused,
                      radius: 8,
                      child: Material(
                        color: theme.colorScheme.onInverseSurface,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        child: label,
                      ),
                    ),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }
}
