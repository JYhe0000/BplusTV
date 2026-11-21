import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models_new/fav/fav_folder/list.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/bili_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavFolderItem extends StatelessWidget {
  const FavFolderItem({
    super.key,
    required this.item,
    required this.onPop,
    required this.heroTag,
  });

  final FavFolderInfo item;
  final VoidCallback onPop;
  final String heroTag;

  void _open() {
    Get.toNamed(
      '/favDetail',
      arguments: item,
      parameters: {
        'mediaId': item.id.toString(),
        'heroTag': heroTag,
      },
    )?.whenComplete(onPop);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 216,
      child: TvFocusable(
        onTap: _open,
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 12,
          child: GestureDetector(
            onTap: _open,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.onInverseSurface.withValues(
                          alpha: 0.4,
                        ),
                        offset: const Offset(6, -8),
                        blurRadius: 0.0,
                        spreadRadius: 0.0,
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: heroTag,
                    child: NetworkImgLayer(
                      src: item.cover,
                      width: 216,
                      height: 122,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ' ${item.title}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  ' 共${item.mediaCount}条视频 · ${BiliUtils.isPublicFavText(item.attr)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
