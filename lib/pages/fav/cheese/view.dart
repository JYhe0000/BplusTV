import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/space/space_cheese/item.dart';
import 'package:bplus_tv/pages/fav/cheese/controller.dart';
import 'package:bplus_tv/pages/member_cheese/widgets/item.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class FavCheesePage extends StatefulWidget {
  const FavCheesePage({super.key});

  @override
  State<FavCheesePage> createState() => _FavCheesePageState();
}

class _FavCheesePageState extends State<FavCheesePage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  @override
  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 840,
    mainAxisExtent: 140,
    mainAxisSpacing: 10,
    crossAxisSpacing: 14,
  );

  final FavCheeseController _controller = Get.put(FavCheeseController());

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
              final horizontalInset = ((constraints.crossAxisExtent - 1600) / 2)
                  .clamp(0.0, double.infinity)
                  .toDouble();
              return SliverPadding(
                padding: EdgeInsets.only(
                  left: horizontalInset + 8,
                  right: horizontalInset + 8,
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

  void _confirmRemove(BuildContext context, int index, int seasonId) {
    {
      showTvConfirm(
        context: context,
        title: '取消收藏',
        message: '确定取消收藏该课堂？',
        confirmLabel: '取消收藏',
        destructive: true,
      ).then((ok) {
        if (ok == true) _controller.onRemove(index, seasonId);
      });
      return;
    }
  }

  Widget _buildBody(
    ThemeData theme,
    LoadingState<List<SpaceCheeseItem>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _controller.onLoadMore();
                  }
                  final item = response[index];
                  return MemberCheeseItem(
                    item: item,
                    onRemove: () =>
                        _confirmRemove(context, index, item.seasonId!),
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
