import 'package:bplus_tv/common/widgets/appbar/appbar.dart';
import 'package:bplus_tv/common/widgets/flutter/pop_scope.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart';
import 'package:bplus_tv/common/widgets/keep_alive_wrapper.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart'
    show tabBarScrollPhysics;
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/history/list.dart';
import 'package:bplus_tv/pages/history/base_controller.dart';
import 'package:bplus_tv/pages/history/controller.dart';
import 'package:bplus_tv/pages/history/widgets/item.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/extension/scroll_controller_ext.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.type});

  final String? type;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  @override
  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 840,
    mainAxisExtent: 140,
    mainAxisSpacing: 10,
    crossAxisSpacing: 14,
  );

  late final HistoryController _historyController;

  @override
  void initState() {
    super.initState();
    _historyController = Get.put(
      HistoryController(widget.type),
      tag: widget.type ?? 'all',
    );
  }

  HistoryController currCtr([int? index]) {
    try {
      index ??= _historyController.tabController!.index;
      if (index != 0) {
        return Get.find<HistoryController>(
          tag: _historyController.tabs[index - 1].type,
        );
      }
    } catch (_) {}
    return _historyController;
  }

  @override
  void dispose() {
    Get.delete<HistoryBaseController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.viewPaddingOf(context);
    Widget child = refreshIndicator(
      onRefresh: _historyController.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _historyController.scrollController,
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
                  bottom: padding.bottom + 48,
                ),
                sliver: Obx(
                  () => _buildBody(_historyController.loadingState.value),
                ),
              );
            },
          ),
        ],
      ),
    );
    if (widget.type != null) {
      return child;
    }
    return Obx(
      () {
        final enableMultiSelect =
            _historyController.baseCtr.enableMultiSelect.value;
        return popScope(
          canPop: !enableMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (enableMultiSelect) {
              currCtr().handleSelect();
            }
          },
          child: SimpleScaffold(
            appBar: MultiSelectAppBarWidget(
              visible: enableMultiSelect,
              ctr: currCtr(),
              child: _buildAppBar,
            ),
            body: Padding(
              padding: .only(left: padding.left, right: padding.right),
              child: Obx(() {
                final tabs = _historyController.tabs;
                if (tabs.isEmpty) {
                  return child;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ?_buildPauseTip,
                    AnimatedBuilder(
                      animation: _historyController.tabController!,
                      builder: (context, _) => Row(
                        children: [
                          for (
                            int i = 0;
                            i < _historyController.tabs.length + 1;
                            i++
                          )
                            _buildHistoryTab(i, enableMultiSelect),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        physics: enableMultiSelect
                            ? const NeverScrollableScrollPhysics()
                            : tabBarScrollPhysics,
                        controller: _historyController.tabController,
                        horizontalDragGestureRecognizer:
                            CustomHorizontalDragGestureRecognizer.new,
                        children: [
                          KeepAliveWrapper(child: child),
                          ...tabs.map(
                            (item) => HistoryPage(type: item.type),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  AppBar get _buildAppBar => AppBar(
    title: const Text('观看记录'),
    actions: [
      IconButton(
        tooltip: '搜索',
        onPressed: () => Get.toNamed('/historySearch'),
        icon: const Icon(Icons.search_outlined),
      ),
      TvFocusable(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => tvDialogShell(
              title: '更多',
              content: const SizedBox.shrink(),
              actions: [
                TvDialogAction(
                  label: !_historyController.baseCtr.pauseStatus.value
                      ? '暂停观看记录'
                      : '恢复观看记录',
                  onTap: () {
                    Get.back();
                    _historyController.baseCtr.onPauseHistory(context);
                  },
                ),
                TvDialogAction(
                  label: '清空观看记录',
                  onTap: () {
                    Get.back();
                    _historyController.baseCtr.onClearHistory(
                      context,
                      () {
                        _historyController.loadingState.value = const Success(
                          null,
                        );
                        if (_historyController.tabController != null) {
                          for (final item in _historyController.tabs) {
                            try {
                              Get.find<HistoryController>(
                                tag: item.type,
                              ).loadingState.value = const Success(
                                null,
                              );
                            } catch (_) {}
                          }
                        }
                      },
                    );
                  },
                ),
                TvDialogAction(
                  label: '删除已看记录',
                  onTap: () {
                    Get.back();
                    currCtr().onDelViewedHistory();
                  },
                ),
              ],
            ),
          );
        },
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 16,
          borderWidth: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: focused
                  ? Theme.of(context).colorScheme.secondaryContainer
                        .withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: const Icon(Icons.more_vert),
          ),
        ),
      ),
      const SizedBox(width: 6),
    ],
  );

  Widget _buildBody(LoadingState<List<HistoryItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _historyController.onLoadMore();
                  }
                  final item = response[index];
                  return HistoryItem(
                    item: item,
                    ctr: _historyController,
                    onDelete: (kid, business) =>
                        _historyController.delHistory(item),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _historyController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _historyController.onReload,
      ),
    };
  }

  PreferredSizeWidget? get _buildPauseTip {
    if (_historyController.baseCtr.pauseStatus.value) {
      final theme = Theme.of(context).colorScheme;
      return PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          height: 48,
          color: theme.secondaryContainer.withValues(alpha: 0.8),
          padding: const EdgeInsets.only(left: 16, right: 6),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  strutStyle: const StrutStyle(height: 1, leading: 0),
                  style: TextStyle(
                    height: 1,
                    color: theme.onSecondaryContainer,
                  ),
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: theme.onSecondaryContainer,
                        ),
                      ),
                      const TextSpan(text: ' 历史记录功能已关闭'),
                    ],
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () =>
                    _historyController.baseCtr.onPauseHistory(context),
                child: Text('开启记录', style: TextStyle(color: theme.primary)),
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }

  Widget _buildHistoryTab(int index, bool enableMultiSelect) {
    final tabs = _historyController.tabs;
    final selected = _historyController.tabController!.index == index;
    return Expanded(
      child: TvFocusable(
        onTap: () {
          feedBack();
          final tabController = _historyController.tabController!;
          if (tabController.index == index && !tabController.indexIsChanging) {
            currCtr().scrollController.animToTop();
          } else {
            if (enableMultiSelect) {
              currCtr().handleSelect();
            }
            tabController.animateTo(index);
          }
        },
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 16,
          borderWidth: 2,
          // 无选中底：选中只用文字颜色/字重区分，焦点用光晕反馈
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              index == 0 ? '全部' : tabs[index - 1].name ?? '',
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.type != null;
}
