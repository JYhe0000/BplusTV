import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/fav_type.dart';
import 'package:bplus_tv/pages/fav/article/controller.dart';
import 'package:bplus_tv/pages/fav/cheese/controller.dart';
import 'package:bplus_tv/pages/fav/topic/controller.dart';
import 'package:bplus_tv/pages/fav/video/controller.dart';
import 'package:bplus_tv/pages/fav_folder_sort/view.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:bplus_tv/utils/extension/scroll_controller_ext.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavPage extends StatefulWidget {
  const FavPage({super.key});

  @override
  State<FavPage> createState() => _FavPageState();
}

class _FavPageState extends State<FavPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FavController _favController = Get.put(FavController());
  late final RxBool _showVideoFavMenu;

  void listener() {
    _showVideoFavMenu.value = _tabController.index == 0;
  }

  @override
  void initState() {
    super.initState();
    int initialIndex = Get.arguments is int ? Get.arguments as int : 0;
    _showVideoFavMenu = (initialIndex == 0).obs;
    _tabController = TabController(
      length: FavTabType.values.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(listener);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(listener)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = SimpleScaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        actions: [
          Obx(
            () => _showVideoFavMenu.value
                ? IconButton(
                    onPressed: () => Get.toNamed('/createFav')?.then(
                      (data) {
                        if (data != null) {
                          final list =
                              _favController.loadingState.value.dataOrNull;
                          if (list != null && list.isNotEmpty) {
                            list.insert(1, data);
                            _favController.loadingState.refresh();
                          } else {
                            _favController.loadingState.value = Success([data]);
                          }
                        }
                      },
                    ),
                    icon: const Icon(Icons.add),
                    tooltip: '新建收藏夹',
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => _showVideoFavMenu.value
                ? IconButton(
                    onPressed: () {
                      if (_favController.loadingState.value.isSuccess) {
                        if (!_favController.isEnd) {
                          SmartDialog.showToast('加载全部收藏夹再排序');
                          return;
                        }
                        Get.to(
                          FavFolderSortPage(favController: _favController),
                        );
                      }
                    },
                    icon: const Icon(Icons.sort),
                    tooltip: '收藏夹排序',
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => _showVideoFavMenu.value
                ? IconButton(
                    onPressed: () {
                      if (_favController.loadingState.value case Success(
                        :final response,
                      )) {
                        if (response?.isNotEmpty != true) {
                          SmartDialog.showToast('收藏夹为空');
                          return;
                        }
                        try {
                          final item = response!.first;
                          Get.toNamed(
                            '/favSearch',
                            arguments: {
                              'type': 1,
                              'mediaId': item.id,
                              'title': item.title,
                              'count': item.mediaCount,
                              'isOwner': true,
                            },
                          );
                        } catch (_) {}
                      }
                    },
                    icon: const Icon(Icons.search_outlined),
                    tooltip: '搜索',
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ViewSafeArea(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final tabs = Row(
                  children: [
                    for (final tab in FavTabType.values) _buildTab(tab),
                  ],
                );
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: netflixSurface(radius: 18, child: tabs),
                );
              },
            ),
            Expanded(
              child: tabBarView(
                controller: _tabController,
                children: FavTabType.values.map((item) => item.page).toList(),
              ),
            ),
          ],
        ),
      ),
    );
    return TvPageFocus(child: page);
  }

  Widget _buildTab(FavTabType tab) {
    final selected = _tabController.index == FavTabType.values.indexOf(tab);
    return Expanded(
      child: TvFocusable(
        onTap: () {
          feedBack();
          if (!_tabController.indexIsChanging) {
            _tabController.animateTo(
              FavTabType.values.indexOf(tab),
            );
            switch (tab) {
              case FavTabType.video:
                _favController.scrollController.animToTop();
              case FavTabType.article:
                if (Get.isRegistered<FavArticleController>()) {
                  Get.find<FavArticleController>().scrollController.animToTop();
                }
              case FavTabType.topic:
                if (Get.isRegistered<FavTopicController>()) {
                  Get.find<FavTopicController>().scrollController.animToTop();
                }
              case FavTabType.cheese:
                if (Get.isRegistered<FavCheeseController>()) {
                  Get.find<FavCheeseController>().scrollController.animToTop();
                }
              default:
            }
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
              tab.title,
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
}
