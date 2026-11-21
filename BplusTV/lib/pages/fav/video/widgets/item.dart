import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models_new/fav/fav_folder/list.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/bili_utils.dart';
import 'package:material_ui/material_ui.dart';

class FavVideoItem extends StatelessWidget {
  final String heroTag;
  final FavFolderInfo item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableTvFocus;

  const FavVideoItem({
    super.key,
    this.onTap,
    this.onLongPress,
    required this.heroTag,
    required this.item,
    this.enableTvFocus = true,
  });

  @override
  Widget build(BuildContext context) {
    final onLongPress =
        this.onLongPress ??
        (onTap == null
            ? null
            : () => imageSaveDialog(title: item.title, cover: item.cover));
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: Style.aspectRatio,
            child: LayoutBuilder(
              builder: (context, boxConstraints) {
                return Hero(
                  tag: heroTag,
                  child: NetworkImgLayer(
                    src: item.cover,
                    width: boxConstraints.maxWidth,
                    height: boxConstraints.maxHeight,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          content(context),
        ],
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: (enableTvFocus
          ? TvFocusable(
              onTap: onTap,
              onLongPress: onLongPress,
              builder: (context, focused, hovered) => TvFocusHighlight(
                focused: focused,
                radius: 12,
                child: body,
              ),
            )
          : body),
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.labelMedium!.fontSize;
    final color = theme.colorScheme.outline;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            textAlign: TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
              letterSpacing: 0.3,
            ),
          ),
          if (item.intro?.isNotEmpty == true)
            Text(
              item.intro!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          Text(
            '${item.mediaCount}个内容',
            style: TextStyle(
              fontSize: fontSize,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            BiliUtils.isPublicFavText(item.attr),
            style: TextStyle(
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
