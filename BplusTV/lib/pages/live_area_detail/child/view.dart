import 'package:bplus_tv/common/skeleton/video_card_v.dart';
import 'package:bplus_tv/common/sliver_single_child_delegate.dart';
import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/self_sized_horizontal_list.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/live/live_feed_index/card_data_list_item.dart';
import 'package:bplus_tv/pages/live/widgets/live_item_app.dart';
import 'package:bplus_tv/pages/live/widgets/live_tv_filter.dart';
import 'package:bplus_tv/pages/live/widgets/live_tv_grid.dart';
import 'package:bplus_tv/pages/live_area_detail/child/controller.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class LiveAreaChildPage extends StatefulWidget {
  const LiveAreaChildPage({
    super.key,
    required this.areaId,
    required this.parentAreaId,
    required this.showFirstFrame,
  });

  final dynamic areaId;
  final dynamic parentAreaId;
  final bool showFirstFrame;

  @override
  State<LiveAreaChildPage> createState() => _LiveAreaChildPageState();
}

class _LiveAreaChildPageState extends State<LiveAreaChildPage>
    with AutomaticKeepAliveClientMixin {
  late final LiveAreaChildController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      LiveAreaChildController(widget.areaId, widget.parentAreaId),
      tag: '${widget.areaId}${widget.parentAreaId}',
    );
  }

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
          SliverPadding(
            padding: EdgeInsets.only(
              left: Style.safeSpace,
              right: Style.safeSpace,
              top: Style.safeSpace,
              bottom: 24,
            ),
            sliver: Obx(
              () => _buildBody(theme, _controller.loadingState.value),
            ),
          ),
        ],
      ),
    );
  }

  LiveTvGridDelegate get gridDelegate => LiveTvGridDelegate(
    infoHeight: MediaQuery.textScalerOf(context).scale(96),
  );

  Widget _buildBody(
    ThemeData theme,
    LoadingState<List<CardLiveItem>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => SliverGrid(
        gridDelegate: gridDelegate,
        delegate: const SliverSingleChildDelegate(
          count: 10,
          child: VideoCardVSkeleton(),
        ),
      ),
      Success(:final response) => SliverMainAxisGroup(
        slivers: [
          if (_controller.newTags?.isNotEmpty == true)
            SliverToBoxAdapter(
              child: Obx(() {
                final tagIndex = _controller.tagIndex.value;
                return SelfSizedHorizontalList(
                  padding: const .only(bottom: 12),
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _controller.newTags![index];
                    final isCurr = index == tagIndex;
                    return LiveTvFilter(
                      label: item.name!,
                      selected: isCurr,
                      onTap: () =>
                          _controller.onSelectTag(index, item.sortType),
                    );
                  },
                  itemCount: _controller.newTags!.length,
                );
              }),
            ),
          response != null && response.isNotEmpty
              ? SliverGrid.builder(
                  gridDelegate: gridDelegate,
                  itemBuilder: (context, index) {
                    if (index == response.length - 1) {
                      _controller.onLoadMore();
                    }
                    return LiveCardVApp(
                      item: response[index],
                      showFirstFrame: widget.showFirstFrame,
                    );
                  },
                  itemCount: response.length,
                )
              : HttpError(onReload: _controller.onReload),
        ],
      ),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  @override
  bool get wantKeepAlive => true;
}
