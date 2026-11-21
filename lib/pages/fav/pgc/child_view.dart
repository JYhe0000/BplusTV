import 'package:bplus_tv/common/skeleton/fav_pgc_item.dart';
import 'package:bplus_tv/common/sliver_single_child_delegate.dart';
import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/fav/fav_pgc/list.dart';
import 'package:bplus_tv/pages/fav/pgc/controller.dart';
import 'package:bplus_tv/pages/fav/pgc/pgc_layout.dart';
import 'package:bplus_tv/pages/fav/pgc/widget/item.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_option_picker.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class FavPgcChildPage extends StatefulWidget {
  const FavPgcChildPage({
    super.key,
    required this.type,
    required this.followStatus,
  });

  final int type;
  final int followStatus;

  @override
  State<FavPgcChildPage> createState() => _FavPgcChildPageState();
}

class _FavPgcChildPageState extends State<FavPgcChildPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  @override
  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 840,
    mainAxisExtent: 140,
    mainAxisSpacing: 10,
    crossAxisSpacing: 14,
  );

  late final FavPgcController _favPgcController;

  @override
  void initState() {
    super.initState();
    _favPgcController = Get.put(
      FavPgcController(widget.type, widget.followStatus),
      tag: '${widget.type}${widget.followStatus}',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    return PgcLayout(
      body: refreshIndicator(
        onRefresh: _favPgcController.onRefresh,
        child: CustomScrollView(
          controller: _favPgcController.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final horizontalInset =
                    ((constraints.crossAxisExtent - 1600) / 2)
                        .clamp(0.0, double.infinity)
                        .toDouble();
                return SliverPadding(
                  padding: EdgeInsets.only(
                    left: horizontalInset + 8,
                    right: horizontalInset + 8,
                    top: 8,
                    bottom: padding.bottom + 48,
                  ),
                  sliver: Obx(
                    () => _buildBody(_favPgcController.loadingState.value),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      toolbar: Obx(
        () => AnimatedSlide(
          offset: _favPgcController.enableMultiSelect.value
              ? const Offset(0, -1)
              : Offset.zero,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: .only(bottom: padding.bottom),
            decoration: BoxDecoration(
              color: theme.colorScheme.onInverseSurface,
              border: Border(
                top: BorderSide(
                  width: 0.5,
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                iconButton(
                  size: 48,
                  tooltip: '取消',
                  context: context,
                  icon: const Icon(Icons.clear),
                  onPressed: _favPgcController.onDisable,
                ),
                const SizedBox(width: 12),
                Obx(
                  () => Checkbox(
                    value: _favPgcController.allSelected.value,
                    onChanged: (value) {
                      _favPgcController.handleSelect(
                        checked: !_favPgcController.allSelected.value,
                        disableSelect: false,
                      );
                    },
                  ),
                ),
                TvFocusable(
                  onTap: () => _favPgcController.handleSelect(
                    checked: !_favPgcController.allSelected.value,
                    disableSelect: false,
                  ),
                  builder: (context, focused, hovered) => TvFocusHighlight(
                    focused: focused,
                    radius: 8,
                    borderWidth: 2,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      child: Text('全选', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ),
                const Spacer(),
                ...const [
                      (followStatus: 1, title: '想看'),
                      (followStatus: 2, title: '在看'),
                      (followStatus: 3, title: '看过'),
                    ]
                    .where(
                      (item) => item.followStatus != widget.followStatus,
                    )
                    .map(
                      (item) => Padding(
                        padding: EdgeInsets.only(
                          left: 8,
                        ),
                        child: TvFocusable(
                          onTap: () {
                            if (_favPgcController.checkedCount != 0) {
                              _favPgcController.onUpdateList(
                                item.followStatus,
                              );
                            }
                          },
                          builder: (context, focused, hovered) =>
                              TvFocusHighlight(
                                focused: focused,
                                radius: 8,
                                borderWidth: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    '标记为${item.title}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<FavPgcItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => SliverGrid(
        gridDelegate: gridDelegate,
        delegate: const SliverSingleChildDelegate(
          count: 10,
          child: FavPgcItemSkeleton(),
        ),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _favPgcController.onLoadMore();
                  }
                  final item = response[index];
                  return FavPgcItem(
                    item: item,
                    ctr: _favPgcController,
                    onSelect: () => _favPgcController.onSelect(item),
                    onUpdateStatus: () {
                      {
                        _showTvFollowDialog(context, index, item.seasonId);
                        return;
                      }
                    },
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _favPgcController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _favPgcController.onReload,
      ),
    };
  }

  Future<void> _showTvFollowDialog(
    BuildContext context,
    int index,
    dynamic seasonId,
  ) async {
    final type = widget.type == 0 ? '追番' : '追剧';
    final status = await showTvOptionPicker<int>(
      context: context,
      title: '标记为',
      current: widget.followStatus,
      options: [
        TvOption(
          value: 3,
          label: '看过',
          enabled: widget.followStatus != 3,
        ),
        TvOption(
          value: 2,
          label: '在看',
          enabled: widget.followStatus != 2,
        ),
        TvOption(
          value: 1,
          label: '想看',
          enabled: widget.followStatus != 1,
        ),
        TvOption(value: -1, label: '取消$type'),
      ],
    );
    if (status == null) return;
    if (status == -1) {
      _favPgcController.pgcDel(index, seasonId);
    } else {
      _favPgcController.onUpdate(index, status, seasonId);
    }
  }

  @override
  bool get wantKeepAlive => true;
}
