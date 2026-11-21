import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/image_type.dart';
import 'package:bplus_tv/models_new/live/live_area_list/area_item.dart';
import 'package:bplus_tv/pages/live/widgets/live_tv_dialog.dart';
import 'package:bplus_tv/pages/live_area_detail/child/controller.dart';
import 'package:bplus_tv/pages/live_area_detail/child/view.dart';
import 'package:bplus_tv/pages/live_area_detail/controller.dart';
import 'package:bplus_tv/pages/live_search/view.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class LiveAreaDetailPage extends StatefulWidget {
  const LiveAreaDetailPage({
    super.key,
    required this.areaId,
    required this.parentAreaId,
    required this.parentName,
  });

  final dynamic areaId;
  final dynamic parentAreaId;
  final String parentName;

  @override
  State<LiveAreaDetailPage> createState() => _LiveAreaDetailPageState();
}

class _LiveAreaDetailPageState extends State<LiveAreaDetailPage> {
  late final LiveAreaDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      LiveAreaDetailController(widget.areaId?.toString(), widget.parentAreaId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SimpleScaffold(
      appBar: AppBar(
        title: Text(widget.parentName),
        actions: [
          IconButton(
            onPressed: () => Get.to(const LiveSearchPage()),
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(
        () => _buildBody(theme, 0, _controller.loadingState.value),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    double bottom,
    LoadingState<List<AreaItem>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: AnimatedBuilder(
                            animation: _controller.tabController!,
                            builder: (context, _) => ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: response.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) => _areaTab(
                                index,
                                response[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                      iconButton(
                        size: 48,
                        iconSize: 20,
                        tooltip:
                            '切换${_controller.showFirstFrame ? '封面' : '首帧'}',
                        icon: _controller.showFirstFrame
                            ? const Icon(MdiIcons.alphaFBox)
                            : const Icon(MdiIcons.image),
                        onPressed: () {
                          _controller.showFirstFrame =
                              !_controller.showFirstFrame;
                          setState(() {});
                        },
                      ),
                      iconButton(
                        size: 48,
                        iconSize: 20,
                        tooltip: '显示菜单',
                        icon: const Icon(Icons.menu),
                        onPressed: () =>
                            _showTags(context, theme, bottom, response),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: tabBarView(
                      controller: _controller.tabController,
                      children: response
                          .map(
                            (e) => LiveAreaChildPage(
                              areaId: e.id,
                              parentAreaId: e.parentId,
                              showFirstFrame: _controller.showFirstFrame,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              )
            : LiveAreaChildPage(
                areaId: widget.areaId,
                parentAreaId: widget.parentAreaId,
                showFirstFrame: _controller.showFirstFrame,
              ),
      Error() => LiveAreaChildPage(
        areaId: widget.areaId,
        parentAreaId: widget.parentAreaId,
        showFirstFrame: _controller.showFirstFrame,
      ),
    };
  }

  Widget _tagItem({
    required ThemeData theme,
    required AreaItem item,
    required VoidCallback onTap,
  }) {
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 14,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            NetworkImgLayer(
              width: 56,
              height: 56,
              src: item.pic,
              type: ImageType.emote,
            ),
            const SizedBox(height: 4),
            Text(
              item.name!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _areaTab(int index, AreaItem item) {
    final selected = _controller.tabController!.index == index;
    return SizedBox(
      width: 148,
      child: TvFocusable(
        onTap: () {
          if (_controller.tabController!.indexIsChanging) return;
          _controller.tabController!.animateTo(index);
          try {
            Get.find<LiveAreaChildController>(
              tag: '${item.id}${item.parentId}',
            ).animateToTop();
          } catch (_) {}
        },
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 16,
          borderWidth: 2,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              item.name ?? '',
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

  void _showTags(
    BuildContext context,
    ThemeData theme,
    double bottom,
    List<AreaItem> list,
  ) {
    showDialog(
      context: context,
      builder: (_) => LiveTvDialog(
        title: widget.parentName,
        maxWidth: 880,
        maxHeight: 560,
        content: GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 108,
          ),
          itemBuilder: (_, index) => _tagItem(
            theme: theme,
            item: list[index],
            onTap: () {
              Get.back();
              _controller.tabController?.index = index;
            },
          ),
        ),
      ),
    );
  }
}
