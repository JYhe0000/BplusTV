import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/search/search_type.dart';
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/pages/search_panel/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

abstract class CommonSearchPanel extends StatefulWidget {
  const CommonSearchPanel({
    super.key,
    required this.keyword,
    required this.searchType,
    required this.tag,
  });

  final String keyword;
  final SearchType searchType;
  final String tag;
}

abstract class CommonSearchPanelState<
  S extends CommonSearchPanel,
  R extends SearchNumData<T>,
  T
>
    extends State<S>
    with AutomaticKeepAliveClientMixin {
  SearchPanelController<R, T> get controller;

  late ColorScheme colorScheme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorScheme = ColorScheme.of(context);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    controller.cancelListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 900 ? 12.0 : 16.0;
        // 从视口宽度计算网格尺寸，滚动时无需重建网格委托。
        final contentWidth = (constraints.maxWidth - 2 * horizontalPadding)
            .clamp(0.0, double.infinity);
        return ClipRect(
          child: refreshIndicator(
            onRefresh: controller.onRefresh,
            child: CustomScrollView(
              controller: controller.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                ?buildHeader(),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: 10,
                    bottom: 16,
                  ),
                  sliver: Obx(
                    () =>
                        _buildBody(controller.loadingState.value, contentWidth),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 按实际内容宽度决定列数，避免侧栏出现后继续套用整屏列宽。
  Widget buildResultGrid({
    required double contentWidth,
    required int itemCount,
    required Widget Function(BuildContext context, int index, double tileWidth)
    itemBuilder,
    double minItemWidth = 360,
    double itemHeight = 132,
  }) {
    const gap = 12.0;
    final columns = ((contentWidth + gap) / (minItemWidth + gap)).floor().clamp(
      1,
      4,
    );
    final tileWidth = (contentWidth - gap * (columns - 1)) / columns;
    final extraTextHeight =
        (MediaQuery.textScalerOf(context).scale(17) - 17).clamp(
          0.0,
          double.infinity,
        ) *
        4;
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        mainAxisExtent: itemHeight + extraTextHeight,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => itemBuilder(context, index, tileWidth),
    );
  }

  Widget buildLoading(double contentWidth);

  Widget _buildBody(LoadingState<List<T>?> loadingState, double contentWidth) {
    return switch (loadingState) {
      Loading() => buildLoading(contentWidth),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? buildList(response, contentWidth)
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget? buildHeader() => null;

  Widget buildList(List<T> list, double contentWidth);
}

/// 筛选状态沿横向轨道排列，入口保留 48dp 焦点区域。
class TvSearchFilterBar extends StatelessWidget {
  const TvSearchFilterBar({
    super.key,
    required this.children,
    required this.onFilter,
  });

  final List<Widget> children;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: NetflixSurface(
            radius: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(spacing: 12, children: children),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: VerticalDivider(
                      width: 1,
                      indent: 12,
                      endIndent: 12,
                      color: colorScheme.outline.withValues(alpha: 0.24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: '筛选',
                    child: TvFocusable(
                      onTap: onFilter,
                      builder: (context, focused, hovered) => TvFocusHighlight(
                        focused: focused,
                        radius: 12,
                        child: SizedBox.square(
                          dimension: 48,
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
