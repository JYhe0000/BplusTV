import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/fav/fav_note/list.dart';
import 'package:bplus_tv/pages/fav/note/controller.dart';
import 'package:bplus_tv/pages/fav/note/widget/item.dart';
import 'package:bplus_tv/pages/fav/pgc/pgc_layout.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class FavNoteChildPage extends StatefulWidget {
  const FavNoteChildPage({super.key, required this.isPublish});

  final bool isPublish;

  @override
  State<FavNoteChildPage> createState() => _FavNoteChildPageState();
}

class _FavNoteChildPageState extends State<FavNoteChildPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  @override
  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 840,
    mainAxisExtent: 140,
    mainAxisSpacing: 10,
    crossAxisSpacing: 14,
  );

  late final FavNoteController _favNoteController;

  @override
  void initState() {
    super.initState();
    _favNoteController = Get.put(
      FavNoteController(widget.isPublish),
      tag: widget.isPublish.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    return PgcLayout(
      body: refreshIndicator(
        onRefresh: _favNoteController.onRefresh,
        child: CustomScrollView(
          controller: _favNoteController.scrollController,
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
                    () => _buildBody(_favNoteController.loadingState.value),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      toolbar: Obx(
        () => AnimatedSlide(
          offset: _favNoteController.enableMultiSelect.value
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
                  onPressed: _favNoteController.onDisable,
                ),
                const SizedBox(width: 12),
                Obx(
                  () => Checkbox(
                    value: _favNoteController.allSelected.value,
                    onChanged: (value) {
                      _favNoteController.handleSelect(
                        checked: !_favNoteController.allSelected.value,
                        disableSelect: false,
                      );
                    },
                  ),
                ),
                TvFocusable(
                  onTap: () => _favNoteController.handleSelect(
                    checked: !_favNoteController.allSelected.value,
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
                FilledButton.tonal(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 48),
                    visualDensity: VisualDensity.standard,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    if (_favNoteController.checkedCount != 0) {
                      {
                        showTvConfirm(
                          context: context,
                          title: '删除笔记',
                          message: '确定删除已选中的笔记吗？',
                          confirmLabel: '删除',
                          destructive: true,
                        ).then((ok) {
                          if (ok == true) _favNoteController.onRemove();
                        });
                      }
                    }
                  },
                  child: const Text('删除'),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<FavNoteItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _favNoteController.onLoadMore();
                  }
                  final item = response[index];
                  return FavNoteItem(
                    item: item,
                    ctr: _favNoteController,
                    onSelect: () => _favNoteController.onSelect(item),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _favNoteController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _favNoteController.onReload,
      ),
    };
  }

  @override
  bool get wantKeepAlive => true;
}
