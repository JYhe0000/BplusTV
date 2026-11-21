import 'package:bplus_tv/common/skeleton/video_card_v.dart';
import 'package:bplus_tv/common/sliver_single_child_delegate.dart';
import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/video_card/video_card_v.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/pages/rcmd/controller.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_focus_viewport.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class RcmdPage extends StatefulWidget {
  const RcmdPage({super.key});

  @override
  State<RcmdPage> createState() => _RcmdPageState();
}

class _RcmdPageState extends State<RcmdPage>
    with AutomaticKeepAliveClientMixin {
  final controller = Get.put(RcmdController());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = ColorScheme.of(context);
    final homeTopInset = TvScrollInset.maybeOf(context);
    return LayoutBuilder(
      builder: (context, pageConstraints) {
        final pageWidth = pageConstraints.maxWidth
            .clamp(0.0, 1760.0)
            .toDouble();
        return Center(
          child: SizedBox(
            width: pageWidth,
            height: pageConstraints.maxHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalInset = (constraints.maxWidth * 0.018)
                    .clamp(14.0, 30.0)
                    .toDouble();
                final availableWidth =
                    (constraints.maxWidth - horizontalInset * 2)
                        .clamp(1.0, double.infinity)
                        .toDouble();
                final delegate = _gridDelegate(
                  availableWidth: availableWidth,
                  availableHeight: constraints.maxHeight,
                );
                // 与 TvFocusViewport 的内边距一致，卡片直接复用网格尺寸。
                final maxCardWidth =
                    delegate.maxCrossAxisExtent + 2 * delegate.crossAxisSpacing;
                final gridWidth =
                    (availableWidth -
                            2 * TvConstants.focusPaintOutset(maxCardWidth))
                        .clamp(0.0, double.infinity)
                        .toDouble();
                final coverWidth = delegate.tileWidthFor(gridWidth);
                Widget scrollView = CustomScrollView(
                  controller: controller.scrollController,
                  clipBehavior: Clip.none,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.only(
                        top: homeTopInset ?? 0,
                        bottom: (constraints.maxHeight * 0.08)
                            .clamp(64.0, 100.0)
                            .toDouble(),
                      ),
                      sliver: Obx(
                        () => _buildBody(
                          colorScheme,
                          controller.loadingState.value,
                          delegate,
                          coverWidth,
                        ),
                      ),
                    ),
                  ],
                );
                scrollView = TvFocusViewport(
                  maxCardSize: Size(
                    maxCardWidth,
                    maxCardWidth / delegate.childAspectRatio +
                        delegate.mainAxisExtent,
                  ),
                  child: scrollView,
                );

                return Container(
                  clipBehavior: .hardEdge,
                  margin: EdgeInsets.symmetric(horizontal: horizontalInset),
                  decoration: const BoxDecoration(borderRadius: Style.mdRadius),
                  child: refreshIndicator(
                    onRefresh: controller.onRefresh,
                    child: scrollView,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  SliverGridDelegateWithExtentAndRatio _gridDelegate({
    required double availableWidth,
    required double availableHeight,
  }) {
    final preferredWidth = (Pref.recommendCardWidth * 0.75)
        .clamp(160.0, 240.0)
        .toDouble();
    final spacing = (availableWidth * 0.008).clamp(10.0, 14.0).toDouble();
    final targetColumns =
        ((availableWidth + spacing) / (preferredWidth + spacing))
            .round()
            .clamp(1, 9)
            .toInt();
    // 匹配自定义委托的向上取整公式，避免卡片被拉成少数大列。
    final cardWidth =
        ((availableWidth - spacing) / targetColumns - spacing + 0.01)
            .clamp(1.0, double.infinity)
            .toDouble();
    final informationHeight = availableHeight < 680 ? 86.0 : 102.0;
    return SliverGridDelegateWithExtentAndRatio(
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      maxCrossAxisExtent: cardWidth,
      childAspectRatio: Style.aspectRatio,
      mainAxisExtent: informationHeight,
    );
  }

  Widget _buildBody(
    ColorScheme colorScheme,
    LoadingState<List<dynamic>?> loadingState,
    SliverGridDelegateWithExtentAndRatio delegate,
    double coverWidth,
  ) {
    return switch (loadingState) {
      Loading() => _buildSkeleton(delegate),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: delegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  if (controller.lastRefreshAt != null) {
                    if (controller.lastRefreshAt == index) {
                      return TvFocusable(
                        onTap: () => controller
                          ..animateToTop()
                          ..onRefresh(),
                        builder: (context, focused, hovered) =>
                            TvFocusHighlight(
                              radius: 12,
                              focused: focused,
                              child: Card(
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const .symmetric(horizontal: 10),
                                  child: Text(
                                    '上次看到这里\n点击刷新',
                                    textAlign: .center,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      );
                    }
                    final actualIndex = index > controller.lastRefreshAt!
                        ? index - 1
                        : index;
                    return VideoCardV(
                      videoItem: response[actualIndex],
                      gridCoverWidth: coverWidth,
                      autofocus: actualIndex == 0,
                      onRemove: () {
                        if (controller.lastRefreshAt != null &&
                            actualIndex < controller.lastRefreshAt!) {
                          controller.lastRefreshAt =
                              controller.lastRefreshAt! - 1;
                        }
                        controller.loadingState
                          ..value.data!.removeAt(actualIndex)
                          ..refresh();
                      },
                    );
                  } else {
                    return VideoCardV(
                      videoItem: response[index],
                      gridCoverWidth: coverWidth,
                      autofocus: index == 0,
                      onRemove: () => controller.loadingState
                        ..value.data!.removeAt(index)
                        ..refresh(),
                    );
                  }
                },
                itemCount: controller.lastRefreshAt != null
                    ? response.length + 1
                    : response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _buildSkeleton(SliverGridDelegateWithExtentAndRatio delegate) =>
      SliverGrid(
        gridDelegate: delegate,
        delegate: const SliverSingleChildDelegate(
          count: 10,
          child: VideoCardVSkeleton(),
        ),
      );
}
