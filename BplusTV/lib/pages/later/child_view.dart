import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/later_view_type.dart';
import 'package:bplus_tv/models/common/video/source_type.dart';
import 'package:bplus_tv/models_new/later/list.dart';
import 'package:bplus_tv/pages/later/base_controller.dart';
import 'package:bplus_tv/pages/later/controller.dart';
import 'package:bplus_tv/pages/later/widgets/video_card_h_later.dart';
import 'package:bplus_tv/utils/extension/get_ext.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class LaterViewChildPage extends StatefulWidget {
  const LaterViewChildPage({
    super.key,
    required this.laterViewType,
  });

  final LaterViewType laterViewType;

  @override
  State<LaterViewChildPage> createState() => _LaterViewChildPageState();
}

class _LaterViewChildPageState extends State<LaterViewChildPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  @override
  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 840,
    mainAxisExtent: 140,
    mainAxisSpacing: 10,
    crossAxisSpacing: 14,
  );

  late final LaterController _laterController;
  late final _baseCtr = Get.putOrFind(
    LaterBaseController.new,
    tag: 'laterBase',
  );

  @override
  void initState() {
    super.initState();
    _laterController = Get.put(
      LaterController(widget.laterViewType),
      tag: widget.laterViewType.type.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      onRefresh: _laterController.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _laterController.scrollController,
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
                  () => _buildBody(_laterController.loadingState.value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<LaterItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _laterController.onLoadMore();
                  }
                  final videoItem = response[index];
                  return VideoCardHLater(
                    index: index,
                    videoItem: videoItem,
                    ctr: _laterController,
                    onViewLater: (cid) {
                      PageUtils.toVideoPage(
                        bvid: videoItem.bvid,
                        cid: cid,
                        cover: videoItem.pic,
                        title: videoItem.title,
                        dimension: videoItem.dimension,
                        extraArguments: _baseCtr.isPlayAll.value
                            ? {
                                'oid': videoItem.aid,
                                'sourceType': SourceType.watchLater,
                                'count': _laterController
                                    .baseCtr
                                    .counts[LaterViewType.all.index],
                                'favTitle': '稍后再看',
                                'mediaId': _laterController.mid,
                                'desc': _laterController.asc.value,
                                'isContinuePlaying': index != 0,
                              }
                            : const {'viewLater': true},
                      );
                    },
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _laterController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _laterController.onReload,
      ),
    };
  }

  @override
  bool get wantKeepAlive => true;
}
