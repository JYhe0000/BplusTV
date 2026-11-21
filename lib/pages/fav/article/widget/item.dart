import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/stat/stat.dart';
import 'package:bplus_tv/models/common/stat_type.dart';
import 'package:bplus_tv/models_new/fav/fav_article/item.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavArticleItem extends StatelessWidget {
  const FavArticleItem({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final FavArticleItemModel item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void onTap() => Get.toNamed(
      '/articlePage',
      parameters: {
        'id': item.opusId!.toString(),
        'type': 'opus',
      },
    );
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Style.safeSpace,
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.cover != null) ...[
            AspectRatio(
              aspectRatio: Style.aspectRatio,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  return NetworkImgLayer(
                    src: item.cover!.url,
                    width: boxConstraints.maxWidth,
                    height: boxConstraints.maxHeight,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.content!,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  item.author!.name!,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    StatWidget(
                      type: StatType.like,
                      value: item.stat!.like,
                      color: theme.colorScheme.outline,
                    ),
                    Text(
                      '  ·  ${item.pubTime}',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TvFocusable(
            onTap: onTap,
            builder: (context, focused, hovered) => TvFocusHighlight(
              focused: focused,
              radius: 12,
              child: body,
            ),
          ),
          Positioned(
            right: 12,
            bottom: -6,
            child: iconButton(
              size: 48,
              iconSize: 18,
              onPressed: onDelete,
              icon: const Icon(Icons.clear),
              iconColor: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
