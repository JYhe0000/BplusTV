import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:bplus_tv/pages/live_search/child/view.dart';
import 'package:bplus_tv/pages/live_search/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_text_input.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class LiveSearchPage extends StatefulWidget {
  const LiveSearchPage({super.key});

  @override
  State<LiveSearchPage> createState() => _LiveSearchPageState();
}

class _LiveSearchPageState extends State<LiveSearchPage> {
  final _controller = Get.put(
    LiveSearchController(),
    tag: Utils.generateRandomString(8),
  );

  Future<void> _editQuery() async {
    final value = await showTvTextInput(
      context,
      title: '搜索房间、主播或房间号',
      initialValue: _controller.editingController.text,
    );
    if (!mounted || value == null) return;
    _controller.editingController.text = value.trim();
    if (value.trim().isEmpty) {
      _controller.hasData.value = false;
      return;
    }
    _controller.submit();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: '清空',
            onPressed: _controller.onClear,
            icon: const Icon(Icons.clear, size: 22),
          ),
          IconButton(
            tooltip: '搜索',
            onPressed: _controller.submit,
            icon: const Icon(Icons.search, size: 22),
          ),
          const SizedBox(width: 10),
        ],
        title: TvFocusable(
          autofocus: true,
          focusNode: _controller.focusNode,
          onTap: _editQuery,
          builder: (context, focused, hovered) => TvFocusHighlight(
            focused: focused,
            radius: 14,
            child: NetflixSegment(
              radius: 14,
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder(
                  valueListenable: _controller.editingController,
                  builder: (context, value, child) => Text(
                    value.text.isEmpty ? '搜索房间、主播或房间号' : value.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      color: value.text.isEmpty
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ViewSafeArea(
        child: Obx(() {
          if (!_controller.hasData.value) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.live_tv_rounded, size: 52),
                  SizedBox(height: 16),
                  Text('找到想看的直播', style: TextStyle(fontSize: 22)),
                  SizedBox(height: 8),
                  Text('按确认键输入关键词，也可直接输入房间号'),
                ],
              ),
            );
          }
          return Column(
            children: [
              TabBar(
                controller: _controller.tabController,
                labelStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 16),
                labelPadding: const EdgeInsets.symmetric(horizontal: 28),
                tabs: [
                  Obx(
                    () => Tab(
                      height: 52,
                      text:
                          '正在直播 ${_controller.counts[0] != -1 ? _controller.counts[0] : ''}',
                    ),
                  ),
                  Obx(
                    () => Tab(
                      height: 52,
                      text:
                          '主播 ${_controller.counts[1] != -1 ? _controller.counts[1] : ''}',
                    ),
                  ),
                ],
                onTap: (index) {
                  if (!_controller.tabController.indexIsChanging) {
                    if (index == 0) {
                      _controller.roomCtr.animateToTop();
                    } else {
                      _controller.userCtr.animateToTop();
                    }
                  }
                },
              ),
              Expanded(
                child: tabBarView(
                  controller: _controller.tabController,
                  children: [
                    LiveSearchChildPage(
                      controller: _controller.roomCtr,
                      searchType: .room,
                    ),
                    LiveSearchChildPage(
                      controller: _controller.userCtr,
                      searchType: .user,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
