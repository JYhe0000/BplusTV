import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/fav/fav_folder/list.dart';
import 'package:bplus_tv/pages/fav/video/controller.dart';
import 'package:bplus_tv/pages/fav/video/widgets/item.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class FavVideoPage extends StatefulWidget {
  const FavVideoPage({super.key});

  @override
  State<FavVideoPage> createState() => _FavVideoPageState();
}

class _FavVideoPageState extends State<FavVideoPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  @override
  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 840,
    mainAxisExtent: 140,
    mainAxisSpacing: 10,
    crossAxisSpacing: 14,
  );

  final FavController _favController = Get.find<FavController>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      onRefresh: _favController.onRefresh,
      child: CustomScrollView(
        controller: _favController.scrollController,
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
                  bottom: 48 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                sliver: Obx(
                  () => _buildBody(_favController.loadingState.value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<FavFolderInfo>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (BuildContext context, int index) {
                  if (index == response.length - 1) {
                    _favController.onLoadMore();
                  }
                  final item = response[index];
                  String heroTag = 'fav-${item.fid}';
                  return FavVideoItem(
                    heroTag: heroTag,
                    item: item,
                    onTap: () async {
                      final res = await Get.toNamed(
                        '/favDetail',
                        arguments: item,
                        parameters: {
                          'heroTag': heroTag,
                          'mediaId': item.id.toString(),
                        },
                      );
                      if (res == true) {
                        final list =
                            _favController.loadingState.value.dataOrNull;
                        if (list != null && index < list.length) {
                          list.removeAt(index);
                          _favController.loadingState.refresh();
                        }
                      }
                    },
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _favController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _favController.onReload,
      ),
    };
  }
}
