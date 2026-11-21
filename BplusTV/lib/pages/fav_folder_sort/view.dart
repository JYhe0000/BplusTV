import 'package:bplus_tv/common/widgets/reorder_mixin.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/http/fav.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/fav/fav_folder/list.dart';
import 'package:bplus_tv/pages/fav/video/controller.dart';
import 'package:bplus_tv/pages/fav/video/widgets/item.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavFolderSortPage extends StatefulWidget {
  const FavFolderSortPage({super.key, required this.favController});

  final FavController favController;

  @override
  State<FavFolderSortPage> createState() => _FavFolderSortPageState();
}

class _FavFolderSortPageState extends State<FavFolderSortPage>
    with ReorderMixin {
  FavController get _favController => widget.favController;

  late List<FavFolderInfo> sortList = List<FavFolderInfo>.from(
    _favController.loadingState.value.data ?? const [],
  );
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final page = SimpleScaffold(
      appBar: AppBar(
        title: const Text('收藏夹排序'),
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
            onPressed: () async {
              final res = await FavHttp.sortFavFolder(
                sort: sortList.map((item) => item.id).join(','),
              );
              if (res.isSuccess) {
                SmartDialog.showToast('排序完成');
                _favController.loadingState.value = Success(sortList);
                if (mounted) {
                  Get.back();
                }
              } else {
                res.toast();
              }
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
    if (oldIndex == 0 || newIndex == 0) {
      SmartDialog.showToast('默认收藏夹不支持排序');
      return;
    }

    sortList.insert(newIndex, sortList.removeAt(oldIndex));

    setState(() {});
  }

  void _moveSelected(int delta) {
    if (sortList.isEmpty) return;
    final target = _selectedIndex + delta;
    if (target < 0 || target >= sortList.length) return;
    if (_selectedIndex == 0 || target == 0) {
      SmartDialog.showToast('默认收藏夹不支持排序');
      return;
    }
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
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemCount: sortList.length,
        itemBuilder: (context, index) {
          final item = sortList[index];
          final key = item.id.toString();
          final selected = index == _selectedIndex;
          Widget card = SizedBox(
            height: 110,
            child: FavVideoItem(
              heroTag: key,
              item: item,
              enableTvFocus: false,
            ),
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
              onLongPress: index == 0
                  ? () => SmartDialog.showToast('默认收藏夹不支持排序')
                  : null,
              builder: (context, focused, hovered) => TvFocusHighlight(
                focused: focused,
                radius: 12,
                child: card,
              ),
            ),
          );
        },
      );
    }
  }
}
