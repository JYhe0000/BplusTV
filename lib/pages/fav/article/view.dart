import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/fav/fav_article/item.dart';
import 'package:bplus_tv/pages/fav/article/controller.dart';
import 'package:bplus_tv/pages/fav/article/widget/item.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class FavArticlePage extends StatefulWidget {
  const FavArticlePage({super.key});

  @override
  State<FavArticlePage> createState() => _FavArticlePageState();
}

class _FavArticlePageState extends State<FavArticlePage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  @override
  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 840,
    mainAxisExtent: 140,
    mainAxisSpacing: 10,
    crossAxisSpacing: 14,
  );

  final FavArticleController _favArticleController = Get.put(
    FavArticleController(),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      onRefresh: _favArticleController.onRefresh,
      child: CustomScrollView(
        controller: _favArticleController.scrollController,
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
                  () => _buildBody(_favArticleController.loadingState.value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index, String opusId) {
    {
      showTvConfirm(
        context: context,
        title: '取消收藏',
        message: '确定取消收藏？',
        confirmLabel: '取消收藏',
        destructive: true,
      ).then((ok) {
        if (ok == true) _favArticleController.onRemove(index, opusId);
      });
      return;
    }
  }

  Widget _buildBody(LoadingState<List<FavArticleItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _favArticleController.onLoadMore();
                  }
                  final item = response[index];
                  return FavArticleItem(
                    item: item,
                    onDelete: () =>
                        _confirmDelete(context, index, item.opusId!),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _favArticleController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _favArticleController.onReload,
      ),
    };
  }
}
