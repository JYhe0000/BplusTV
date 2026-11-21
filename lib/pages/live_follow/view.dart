import 'package:bplus_tv/common/skeleton/video_card_v.dart';
import 'package:bplus_tv/common/sliver_single_child_delegate.dart';
import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/live/live_follow/item.dart';
import 'package:bplus_tv/pages/live_follow/controller.dart';
import 'package:bplus_tv/pages/live_follow/widgets/live_item_follow.dart';
import 'package:bplus_tv/pages/live/widgets/live_tv_grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class LiveFollowPage extends StatefulWidget {
  const LiveFollowPage({super.key});

  @override
  State<LiveFollowPage> createState() => _LiveFollowPageState();
}

class _LiveFollowPageState extends State<LiveFollowPage> {
  final _controller = Get.put(LiveFollowController());

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(
        title: Obx(
          () {
            final count = _controller.count.value;
            return Text(count != null ? '$count人正在直播' : '关注直播');
          },
        ),
      ),
      body: refreshIndicator(
        onRefresh: _controller.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(
                left: Style.safeSpace,
                right: Style.safeSpace,
                top: 12,
                bottom: 24,
              ),
              sliver: Obx(() => _buildBody(_controller.loadingState.value)),
            ),
          ],
        ),
      ),
    );
  }

  LiveTvGridDelegate get gridDelegate => LiveTvGridDelegate(
    infoHeight: MediaQuery.textScalerOf(context).scale(96),
  );

  Widget _buildBody(LoadingState<List<LiveFollowItem>?> loadingState) {
    return switch (loadingState) {
      Loading() => SliverGrid(
        gridDelegate: gridDelegate,
        delegate: const SliverSingleChildDelegate(
          count: 10,
          child: VideoCardVSkeleton(),
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
                  return LiveCardVFollow(
                    liveItem: response[index],
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
