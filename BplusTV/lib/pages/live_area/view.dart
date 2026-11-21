import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/keep_alive_wrapper.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/image_type.dart';
import 'package:bplus_tv/models_new/live/live_area_list/area_item.dart';
import 'package:bplus_tv/models_new/live/live_area_list/area_list.dart';
import 'package:bplus_tv/pages/live_area/controller.dart';
import 'package:bplus_tv/pages/live_area_detail/view.dart';
import 'package:bplus_tv/pages/search/widgets/search_text.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:bplus_tv/utils/extension/iterable_ext.dart';
import 'package:flutter_sortable_wrap/sortable_wrap.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class LiveAreaPage extends StatefulWidget {
  const LiveAreaPage({super.key});

  @override
  State<LiveAreaPage> createState() => _LiveAreaPageState();
}

class _LiveAreaPageState extends State<LiveAreaPage> {
  final _controller = Get.put(LiveAreaController());

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SimpleScaffold(
      appBar: AppBar(
        title: const Text('全部标签'),
        actions: _controller.isLogin
            ? [
                TextButton(
                  onPressed: _controller.onEdit,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  child: Obx(
                    () => Text(_controller.isEditing.value ? '完成' : '编辑'),
                  ),
                ),
                const SizedBox(width: 16),
              ]
            : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_controller.isLogin)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.32,
                ),
                child: SingleChildScrollView(
                  child: Obx(
                    () => _buildFavWidget(theme, _controller.favState.value),
                  ),
                ),
              ),
            Expanded(
              child: Obx(
                () => _buildBody(
                  theme,
                  0,
                  _controller.loadingState.value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    double bottom,
    LoadingState<List<AreaList>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 52,
                    child: AnimatedBuilder(
                      animation: _controller.tabController!,
                      builder: (context, _) => ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: response.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) =>
                            _buildAreaTab(index, response[index]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: tabBarView(
                      controller: _controller.tabController,
                      children: response
                          .map(
                            (e) => KeepAliveWrapper(
                              child: e.areaList.isNullOrEmpty
                                  ? const SizedBox.shrink()
                                  : GridView.builder(
                                      padding: EdgeInsets.only(
                                        top: 12,
                                        bottom: bottom + 24,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 152,
                                            mainAxisSpacing: 14,
                                            crossAxisSpacing: 14,
                                            mainAxisExtent: 112,
                                          ),
                                      itemCount: e.areaList!.length,
                                      itemBuilder: (context, index) {
                                        final item = e.areaList![index];
                                        return _tagItem(
                                          theme: theme,
                                          item: item,
                                          onPressed: () {
                                            // success
                                            bool? isFav =
                                                _controller.favInfo[item.id];
                                            if (isFav == true) {
                                              _controller.favInfo[item.id] =
                                                  false;
                                              _controller.favState
                                                ..value.data.remove(item)
                                                ..refresh();
                                              (context as Element)
                                                  .markNeedsBuild();
                                            } else {
                                              // check
                                              if (_controller
                                                  .favState
                                                  .value
                                                  .isSuccess) {
                                                _controller.favInfo[item.id] =
                                                    true;
                                                _controller.favState
                                                  ..value.data.add(item)
                                                  ..refresh();
                                                (context as Element)
                                                    .markNeedsBuild();
                                              }
                                            }
                                          },
                                        );
                                      },
                                    ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              )
            : scrollErrorWidget(onReload: _controller.onReload),
      Error(:final errMsg) => scrollErrorWidget(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  Widget _buildFavWidget(
    ThemeData theme,
    LoadingState<List<AreaItem>?> loadingState,
  ) {
    if (loadingState case Success(:final response)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '我的常用标签  '),
                  TextSpan(
                    text: '点击进入标签',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (response != null && response.isNotEmpty) ...[
              SortableWrap(
                onSortStart: (index) => _controller.isEditing.value = true,
                onSorted: (int oldIndex, int newIndex) {
                  response.insert(newIndex, response.removeAt(oldIndex));
                },
                spacing: 12,
                runSpacing: 8,
                children: response
                    .map(
                      (item) => _favTagItem(
                        theme: theme,
                        item: item,
                        onPressed: () {
                          response.remove(item);
                          _controller
                            ..favInfo[item.id] = false
                            ..favState.refresh();
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _tagItem({
    required ThemeData theme,
    required AreaItem item,
    required VoidCallback onPressed,
  }) {
    return TvFocusable(
      onTap: () {
        if (_controller.isEditing.value) {
          if (item.id != 0) {
            onPressed();
          }
          return;
        }

        Get.to(
          LiveAreaDetailPage(
            areaId: item.id,
            parentAreaId: item.parentId,
            parentName: item.parentName ?? '',
          ),
        );
      },
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 14,
        borderWidth: 2,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NetworkImgLayer(
                  width: 62,
                  height: 62,
                  src: item.pic,
                  type: ImageType.emote,
                ),
                const SizedBox(height: 6),
                Text(
                  item.name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (item.id != 0)
              Positioned(
                top: 0,
                right: 0,
                child: Obx(() {
                  if (_controller.isEditing.value) {
                    if (_controller.favState.value case Success(
                      :final response,
                    )) {
                      bool? isFav = _controller.favInfo[item.id];
                      if (isFav == null) {
                        isFav = response.contains(item);
                        _controller.favInfo[item.id] = isFav;
                      }
                      return Icon(
                        isFav ? MdiIcons.check : MdiIcons.plus,
                        size: 24,
                        color: isFav
                            ? theme.colorScheme.outline
                            : theme.colorScheme.onSecondaryContainer,
                      );
                    }
                  }
                  return const SizedBox.shrink();
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _favTagItem({
    required ThemeData theme,
    required AreaItem item,
    required VoidCallback onPressed,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline,
            ),
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: SearchText(
            text: item.name!,
            fontSize: 14,
            bgColor: Colors.transparent,
            padding: const .symmetric(horizontal: 18, vertical: 16),
            onTap: (value) {
              if (_controller.isEditing.value) {
                onPressed();
                return;
              }

              Get.to(
                LiveAreaDetailPage(
                  areaId: item.id,
                  parentAreaId: item.parentId,
                  parentName: item.parentName ?? '',
                ),
              );
            },
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: Obx(() {
            if (_controller.isEditing.value) {
              final isDark = theme.brightness == Brightness.dark;
              return IgnorePointer(
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: isDark
                      ? theme.colorScheme.error
                      : theme.colorScheme.errorContainer,
                  child: Icon(
                    Icons.horizontal_rule,
                    size: 14,
                    color: isDark
                        ? theme.colorScheme.onError
                        : theme.colorScheme.onErrorContainer,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ),
      ],
    );
  }

  Widget _buildAreaTab(int index, AreaList area) {
    final selected = _controller.tabController!.index == index;
    return SizedBox(
      width: 148,
      child: TvFocusable(
        onTap: () {
          feedBack();
          if (!_controller.tabController!.indexIsChanging) {
            _controller.tabController!.animateTo(index);
          }
        },
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 16,
          borderWidth: 2,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              area.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
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
}
