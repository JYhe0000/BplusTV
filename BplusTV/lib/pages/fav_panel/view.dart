import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/fav/fav_folder/list.dart';
import 'package:bplus_tv/pages/common/common_intro_controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/bili_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavPanel extends StatefulWidget {
  const FavPanel({
    super.key,
    required this.ctr,
    this.scrollController,
  });

  final FavMixin ctr;
  final ScrollController? scrollController;

  @override
  State<FavPanel> createState() => _FavPanelState();
}

class _FavPanelState extends State<FavPanel> {
  LoadingState loadingState = LoadingState.loading();

  @override
  void initState() {
    super.initState();
    _queryVideoInFolder();
  }

  Future<void> _queryVideoInFolder() async {
    final res = await widget.ctr.queryVideoInFolder();
    if (mounted) {
      loadingState = res;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    {
      return _buildTvList();
    }
  }

  Widget _buildTvList() {
    switch (loadingState) {
      case Loading():
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: m3eLoading),
        );
      case Error(:final errMsg):
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(errMsg ?? '加载失败'),
        );
      case Success():
        final list = widget.ctr.favFolderData.value.list ?? const [];
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _tvRow(
              title: '新建收藏夹',
              icon: Icons.add,
              onTap: () => Get.toNamed('/createFav')?.then((data) {
                if (data is FavFolderInfo && mounted) {
                  widget.ctr.favFolderData.value.list?.insert(
                    1,
                    data
                      ..favState = 1
                      ..mediaCount = 1,
                  );
                  setState(() {});
                }
              }),
            ),
            for (final item in list)
              _tvRow(
                title: item.title,
                subtitle:
                    '${item.mediaCount}个内容 . ${BiliUtils.isPublicFavText(item.attr)}',
                icon: BiliUtils.isPublicFav(item.attr)
                    ? Icons.folder_outlined
                    : Icons.lock_outline,
                checked: item.favState == 1,
                onTap: () {
                  final isChecked = item.favState == 1;
                  setState(() {
                    item
                      ..favState = isChecked ? 0 : 1
                      ..mediaCount += isChecked ? -1 : 1;
                  });
                },
              ),
          ],
        );
    }
  }

  Widget _tvRow({
    required String title,
    required VoidCallback onTap,
    required IconData icon,
    String? subtitle,
    bool? checked,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: focused
                ? colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              if (checked != null) ...[
                const SizedBox(width: 12),
                Icon(
                  checked ? Icons.check_circle : Icons.circle_outlined,
                  size: 24,
                  color: checked ? colorScheme.primary : colorScheme.outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
