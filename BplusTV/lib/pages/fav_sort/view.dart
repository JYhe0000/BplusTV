import 'package:bplus_tv/common/widgets/reorder_mixin.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/http/fav.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/fav/fav_detail/media.dart';
import 'package:bplus_tv/pages/fav_detail/controller.dart';
import 'package:bplus_tv/pages/fav_detail/widget/fav_video_card.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/extension/iterable_ext.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavSortPage extends StatefulWidget {
  const FavSortPage({super.key, required this.favDetailController});

  final FavDetailController favDetailController;

  @override
  State<FavSortPage> createState() => _FavSortPageState();
}

class _FavSortPageState extends State<FavSortPage> with ReorderMixin {
  FavDetailController get _favDetailController => widget.favDetailController;

  late List<FavDetailItemModel> sortList = List<FavDetailItemModel>.from(
    _favDetailController.loadingState.value.data ?? const [],
  );
  List<String> sort = <String>[];
  int _selectedIndex = 0;

  void onLoadMore() {
    if (_favDetailController.isEnd) {
      return;
    }
    _favDetailController.onLoadMore().whenComplete(() {
      try {
        if (_favDetailController.loadingState.value case Success(
          :final response,
        )) {
          sortList.addAll(response!.skip(sortList.length));
          if (mounted) {
            setState(() {});
          }
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = SimpleScaffold(
      appBar: AppBar(
        title: Text('排序: ${_favDetailController.folderInfo.value.title}'),
        actions: [
          ...[
            _tvMoveButton(
              icon: Icons.keyboard_arrow_up,
              tooltip: '上移',
              onTap: () => _moveSelected(-1),
            ),
            _tvMoveButton(
              icon: Icons.keyboard_arrow_down,
              tooltip: '下移',
              onTap: () => _moveSelected(1),
            ),
          ],
          TextButton(
            onPressed: () {
              if (sort.isEmpty) {
                Get.back();
                return;
              }
              FavHttp.sortFav(
                mediaId: _favDetailController.mediaId,
                sort: sort.join(','),
              ).then((res) {
                if (res.isSuccess) {
                  SmartDialog.showToast('排序完成');
                  _favDetailController.loadingState.value = Success(sortList);
                  if (mounted) {
                    Get.back();
                  }
                } else {
                  res.toast();
                }
              });
            },
            child: const Text('完成'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody,
    );
    return TvPageFocus(child: page);
  }

  void onReorderItem(int oldIndex, int newIndex) {
    final oldItem = sortList[oldIndex];
    final newItem = sortList.getOrNull(
      oldIndex > newIndex ? newIndex - 1 : newIndex, // might be Negative
    );
    sort.add(
      '${newItem == null ? '0:0' : '${newItem.id}:${newItem.type}'}:${oldItem.id}:${oldItem.type}',
    );

    sortList.insert(newIndex, sortList.removeAt(oldIndex));

    setState(() {});
  }

  void _moveSelected(int delta) {
    if (sortList.isEmpty) return;
    final target = _selectedIndex + delta;
    if (target < 0 || target >= sortList.length) return;
    onReorderItem(_selectedIndex, target);
    setState(() => _selectedIndex = target);
  }

  Widget _tvMoveButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 16,
        borderWidth: 2,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(icon, size: 26),
          ),
        ),
      ),
    );
  }

  Widget get _buildBody {
    {
      final list = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemCount: sortList.length,
        itemBuilder: (context, index) {
          final item = sortList[index];
          final selected = index == _selectedIndex;
          Widget card = SizedBox(
            height: 110,
            child: FavVideoCardH(item: item, enableTvFocus: false),
          );
          if (selected) {
            card = DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: card,
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: TvFocusable(
              onTap: () => setState(() => _selectedIndex = index),
              builder: (context, focused, hovered) => TvFocusHighlight(
                focused: focused,
                radius: 12,
                child: card,
              ),
            ),
          );
        },
      );
      if (!_favDetailController.isEnd) {
        return NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent - 300) {
              onLoadMore();
            }
            return false;
          },
          child: list,
        );
      }
      return list;
    }
  }
}
